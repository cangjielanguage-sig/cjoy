/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.json.generate

import std.ast.*
import std.collection.ArrayList
import cjoy.utils.{ClassGenentor, parserAttrs, MapToString, MapListGetFunc}

public class JsonClassInfo {
    let classId: Token
    let fields: ArrayList<JsonFieldGenerator>
    let description: String
    let superClass: String
    let isClass: Bool

    init(attr: ?Tokens, classId: Token, vars: ArrayList<VarDecl>, isClass: Bool) {
        this.classId = classId
        this.fields = ArrayList<JsonFieldGenerator>()
        for (vd in vars) {
            this.fields.add(JsonInfoCache.create(vd))
        }
        this.isClass = isClass

        if (attr.isSome()) {
            let map: MapToString = parserAttrs(attr.getOrThrow(), validKeys: ["description", "superClass"],
                macroName: "Json")
            this.description = map.getString("description") ?? ""
            this.superClass = map.getString("superClass") ?? ""
        } else {
            this.description = ""
            this.superClass = ""
        }
    }

    func genSerializeFunc(): Tokens {
        var serTokens = Tokens()
        for (f in this.fields) {
            if (f.info.jsonKeyName() == "") {
                continue
            }
            serTokens += f.genSerializeTokens()
        }
        var callSuperTokens = Tokens()
        if (superClass != "") {
            callSuperTokens = quote(super.write(writer))
        }
        var openToken = if (isClass) {
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

    func genDeserializeFunc(): Tokens {
        var deserTokens = Tokens()
        for (f in this.fields) {
            if (f.info.jsonKeyName() == "") {
                continue
            }
            deserTokens += f.genDeserializeTokens()
        }
        if (isClass) {
            var callSuperTokens = Tokens()
            if (superClass != "") {
                let superId = Token(TokenKind.IDENTIFIER, superClass)
                callSuperTokens = quote(&& $(superId).read(obj, name, reader))
            }
            quote(
                protected static func read(obj: $(classId), name: String, reader: JsonReader): Bool {
                    match (name) {
                        $(deserTokens)
                        case _ => return true
                    }
                    return false
                }

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
        } else {
            // struct is inmutable
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
        let classInfo = JsonClassInfo(attr, ident, classGen.variables, classGen.isClass)
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
