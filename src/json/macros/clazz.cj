/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.json.macros

import std.ast.*
import std.collection.ArrayList
import cjoy.utils.ast.{ClassGenentor, parserAttrs}
import cjoy.utils.{MapToString, MapListGetFunc}

class JsonClassInfo {
    let classId: Token
    let fields: ArrayList<JsonFieldGenerator>
    let description: String
    let superClass: String
    let subTypeField: String
    let subTypeAs: ?Bool
    let subTypes: ?MapToString

    let isClass: Bool
    let isOpen: Bool

    /**
     * @throws Exception
     */
    init(attr: ?Tokens, classId: Token, vars: ArrayList<VarDecl>, isClass: Bool, isOpen: Bool) {
        this.classId = classId
        this.fields = ArrayList<JsonFieldGenerator>()
        for (vd in vars) {
            this.fields.add(JsonInfoCache.create(vd))
        }
        this.isClass = isClass
        this.isOpen = isOpen

        if (attr.isSome()) {
            let map: MapToString = parserAttrs(attr.getOrThrow(),
                validKeys: ["description", "superClass", "subTypeField", "subTypeAs", "subTypes"], macroName: "Json")
            this.description = map.getString("description") ?? ""
            this.superClass = map.getString("superClass") ?? ""
            this.subTypeField = map.getString("subTypeField") ?? ""
            this.subTypes = map.getMap("subTypes")
            this.subTypeAs = map.getBool("subTypeAs")
            checkAttrs(attr.getOrThrow())
        } else {
            this.description = ""
            this.superClass = ""
            this.subTypeField = ""
            this.subTypes = None
            this.subTypeAs = None
        }
    }

    private func checkAttrs(attr: Tokens): Unit {
        if (this.subTypeField != "") {
            if (this.subTypes.isNone()) {
                diagReport(DiagReportLevel.ERROR, attr, "miss subTypes attribute",
                    "attribute subTypes and subTypeField must exist simultaneously")
            }
        }
        if (this.subTypes.isSome()) {
            if (this.subTypeField == "" && this.subTypeAs.isNone()) {
                diagReport(DiagReportLevel.ERROR, attr, "miss subTypeField attribute",
                    "attribute subTypes and subTypeField/subTypeAs must exist simultaneously")
            }
        }
    }

    private func getAllSerializeTokens(): Tokens {
        var tokens = Tokens()
        for (f in this.fields) {
            if (f.info.jsonKeyName() == "") {
                continue
            }
            tokens += f.genSerializeTokens()
        }
        tokens
    }

    private func getAllDeserializeTokens(): Tokens {
        var tokens = Tokens()
        for (f in this.fields) {
            if (f.info.jsonKeyName() == "") {
                continue
            }
            tokens += f.genDeserializeTokens()
        }
        tokens
    }

    func genSerializeFunc(): Tokens {
        let serTokens = getAllSerializeTokens()
        var callSuperTokens = Tokens()
        if (superClass != "") {
            callSuperTokens = quote(super.write(writer))
        }
        let openToken = if (isOpen) {
            quote(open)
        } else {
            Tokens()
        }
        quote(
            public $(openToken) func toJson(writer: JsonWriter): Unit {
                writer.startObject()
                $(callSuperTokens)
                write(writer)
                writer.endObject()
            }

            protected $(openToken) func write(writer: JsonWriter): Unit {
                 $(serTokens)
            }
        )
    }

    private func genDeserializeForSubTypeField(): Tokens {
        var subTypeTokens = Tokens()
        for ((k, v) in subTypes.getOrThrow()) {
            let x = Token(TokenKind.IDENTIFIER, v.toString())
            subTypeTokens += quote(case $k => $x.fromJson(nr)
            )
        }
        quote(
            public static func fromJson(reader: JsonReader): $(classId) {
                var buffer = ByteBuffer()
                buffer.writeByte(b'{')
                var subType = ""
                var num = 0
                while (let Some(v) <- reader.peek()) {
                    match (v) {
                        case BeginObject =>
                            reader.startObject()
                            while (reader.peek() != EndObject) {
                                let name = reader.readName()
                                num++
                                if (num > 1) {
                                    buffer.writeByte(b',')
                                }
                                buffer.writeByte(b'"')
                                buffer.write(name.toArray())
                                buffer.writeByte(b'"')
                                buffer.writeByte(b':')
                                match (name) {
                                    case $subTypeField => 
                                        subType = reader.readValue<String>()
                                        buffer.writeByte(b'"')
                                        buffer.write(subType.toArray())
                                        buffer.writeByte(b'"')
                                    case _ => 
                                        buffer.write(reader.readValueBytes())
                                }
                            }
                            reader.endObject()
                            break
                        case _ => throw Exception("the token is not start object")
                    }
                }
                buffer.writeByte(b'}')
                let nr = JsonReader(buffer)
                match (subType) {
                    $subTypeTokens
                    case _ => throw Exception("unknown field value $subTypeField:${subType}")
                }
            }
        )
    }

    private func genDeserializeForSubTypeAs(): Tokens {
        var subTypeTokens = Tokens()
        var subTypeMatchTokens = Tokens()
        for ((k, v) in subTypes.getOrThrow()) {
            let x = Token(TokenKind.IDENTIFIER, v.toString())
            subTypeTokens += quote(if (exists.get($k).isSome()) {return $x.fromJson(nr)}
            )
            subTypeMatchTokens += quote(case $k => 
                exists.add($k, true)
                buffer.write(reader.readValueBytes())
            )
        }
        quote(
            public static func fromJson(reader: JsonReader): $(classId) {
                var buffer = ByteBuffer()
                buffer.writeByte(b'{')
                var exists: HashMap<String, Bool> = HashMap()
                var num = 0
                while (let Some(v) <- reader.peek()) {
                    match (v) {
                        case BeginObject =>
                            reader.startObject()
                            while (reader.peek() != EndObject) {
                                let name = reader.readName()
                                num++
                                if (num > 1) {
                                    buffer.writeByte(b',')
                                }
                                buffer.writeByte(b'"')
                                buffer.write(name.toArray())
                                buffer.writeByte(b'"')
                                buffer.writeByte(b':')
                                match (name) {
                                    $subTypeMatchTokens
                                    case _ => 
                                        buffer.write(reader.readValueBytes())
                                }
                            }
                            reader.endObject()
                            break
                        case _ => throw Exception("the token is not start object")
                    }
                }
                buffer.writeByte(b'}')
                let nr = JsonReader(buffer)
                $subTypeTokens
                throw Exception("unknown subtype")
            }
        )
    }

    private func genDeserializeForClass(): Tokens {
        var callSuperTokens = Tokens()
        if (superClass != "") {
            let superId = Token(TokenKind.IDENTIFIER, superClass)
            callSuperTokens = quote(&& $(superId).read(obj, name, reader))
        }
        quote(
            public static func fromJson(reader: JsonReader): $(classId) {
                var obj = $(classId)()
                while (let Some(v) <- reader.peek()) {
                    match (v) {
                        case BeginObject =>
                            reader.startObject()
                            while (reader.peek() != EndObject) {
                                let name = reader.readName()
                                let skip = read(obj, name, reader)$(callSuperTokens)
                                if (skip) { reader.skip() }
                            }
                            reader.endObject()
                            break
                        case _ => throw Exception("the token is not start object")
                    }
                }
                obj
            }
        )
    }

    private func genDeserializeForStruct(deserTokens: Tokens): Tokens {
        quote(
            public static func fromJson(reader: JsonReader): $(classId) {
                var obj = $(classId)()
                while (let Some(v) <- reader.peek()) {
                    match (v) {
                        case BeginObject =>
                            reader.startObject()
                            while (reader.peek() != EndObject) {
                                let name = reader.readName()
                                match (name) {
                                    $(deserTokens)
                                    case _ => reader.skip()
                                }
                            }
                            reader.endObject()
                            break
                        case _ => throw Exception("the token is not start object")
                    }
                }
                obj
            }
        )
    }

    func genDeserializeFunc(): Tokens {
        let deserTokens = getAllDeserializeTokens()
        if (isClass) {
            var res = quote(
                protected static func read(obj: $(classId), name: String, reader: JsonReader): Bool {
                    match (name) {
                        $(deserTokens)
                        case _ => return true
                    }
                    return false
                }
            )
            if (subTypeField != "") {
                res += genDeserializeForSubTypeField()
            } else if (subTypeAs.isSome()) {
                res += genDeserializeForSubTypeAs()
            } else {
                res += genDeserializeForClass()
            }
            res
        } else {
            // struct is inmutable
            genDeserializeForStruct(deserTokens)
        }
    }

    func genToSchemaFunc(): Tokens {
        var tokens = Tokens()
        for (f in this.fields) {
            if (f.info.jsonKeyName() == "") {
                continue
            }
            let ts = f.genSchemaTokens()
            if (ts.size == 0) {
                continue
            }
            if (tokens.size > 0) {
                tokens += Token(TokenKind.COMMA)
                tokens += Token(TokenKind.NL)
            }
            tokens += ts
        }
        var arrTokens = Tokens()
        if (tokens.size != 0) {
            arrTokens = quote([$tokens])
        }
        var callSuperTokens = Tokens()
        if (superClass != "") {
            let superId = Token(TokenKind.IDENTIFIER, superClass)
            callSuperTokens = quote(arr.add(all:$(superId).schemaInfos()))
        }
        quote(
            protected static func schemaInfos(): Array<JsonSchemaInfo> {
                let arr = ArrayList<JsonSchemaInfo>($arrTokens)
                $callSuperTokens
                arr.toArray()
            }

            public static func toSchema(): JsonSchemaType {
                JsonSchemaType.Obj($(classId).schemaInfos())
            }

            public static func toJsonSchema(): JsonSerializable {
                toSchema().toJson(description: $description)
            }
        )
    }

    public static func parse(attr: ?Tokens, input: Tokens): Tokens {
        let (decl, pos) = parseDeclFragment(input)
        let classGen = ClassGenentor("Json", decl)

        let ident = decl.identifier
        let classInfo = JsonClassInfo(attr, ident, classGen.variables, classGen.isClass, classGen.isOpen)
        let supperTokens = quote(JsonSerializable & JsonDeserializable<$(classInfo.classId)> & Jsonable)

        let serTokens = classInfo.genSerializeFunc()
        let deserTokens = classInfo.genDeserializeFunc()
        let schemaTokens = classInfo.genToSchemaFunc()
        let bindTokens = quote(
            $(serTokens)
            $(deserTokens)
            $(schemaTokens)
        )
        let tokens = classGen.genTokens(supperTokens, bindTokens)
        JsonInfoCache.clear()

        tokens + Token(TokenKind.NL) + input[pos..]
    }
}
