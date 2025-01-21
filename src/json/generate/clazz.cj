/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy.json.generate

import std.ast.*
import std.collection.ArrayList

class ClassVarDeclVisitor <: Visitor {
    private let varDecls: ArrayList<VarDecl> = ArrayList<VarDecl>()

    public func allVarDecls(): Array<VarDecl> {
        return varDecls.toArray()
    }

    public override func visit(varDecl: VarDecl) {
        varDecls.add(varDecl)
    }

    public override func visit(_: FuncDecl) {
        breakTraverse()
    }
}

public class JsonClassInfo {
    let classId: Token
    let fields: ArrayList<JsonFieldGenerator>

    init(classId: Token, vars: Array<VarDecl>) {
        this.classId = classId
        this.fields = ArrayList<JsonFieldGenerator>()
        for (vd in vars) {
            this.fields.add(JsonInfoCache.create(vd))
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
        quote(
            public func toJson(writer: JsonWriter): Unit {
                writer.startObject()
                $(serTokens)
                writer.endObject()
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

        var addonFuncTokens = Tokens()
        for (f in this.fields) {
            if (f.info.jsonKeyName() == "") {
                continue
            }
            addonFuncTokens += f.genAddonFuncTokens()
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
                                match (name) {
                                    $(deserTokens)
                                    case _ => ()
                                }
                            }
                            reader.endObject()
                            break
                        case _ => throw Exception("the token is not start object")
                    }
                }
                obj
            }
            $(addonFuncTokens)
        )
    }

    public static func parse(input: Tokens): Tokens {
        let decl: Decl = parseDecl(input)
        if (!(decl is StructDecl) && !(decl is ClassDecl)) {
            throw Exception("Json macro only using for struct or class")
        }

        let ident = decl.identifier
        let visitor = ClassVarDeclVisitor()
        decl.traverse(visitor)
        let vars = visitor.allVarDecls()
        let classInfo = JsonClassInfo(ident, vars)

        let serTokens = classInfo.genSerializeFunc()
        let deserTokens = classInfo.genDeserializeFunc()
        JsonInfoCache.clear()

        input + quote(
            extend $(classInfo.classId) <: JsonSerializable & JsonDeserializable<$(classInfo.classId)> {
                $(serTokens)
                $(deserTokens)
            }
        )
    }
}
