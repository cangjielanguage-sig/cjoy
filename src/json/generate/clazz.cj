package cjoy.json.generate

import std.ast.*
import std.collection.ArrayList

class ClassVarDeclVisitor <: Visitor {
    private let varDecls: ArrayList<VarDecl> = ArrayList<VarDecl>()

    public func allVarDecls(): Array<VarDecl> {
        return varDecls.toArray()
    }

    override public func visit(varDecl: VarDecl) {
        varDecls.append(varDecl)
    }
}

public class JsonClassInfo {
    let classId: Token
    let fields: ArrayList<JsonFieldGenerator>

    init (classId: Token, vars: Array<VarDecl>) {
        this.classId = classId
        this.fields = ArrayList<JsonFieldGenerator>()
        for (vd in vars) {
            this.fields.append(JsonInfoCache.create(vd))
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
        )
    }

    public static func parse(input: Tokens): Tokens {
        let decl: Decl  = parseDecl(input)
        if (!(decl is StructDecl) && !(decl is ClassDecl)) {
            throw Exception("Json march only using for struct or class")
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
            extend $(classInfo.classId) <: JsonAdapter<$(classInfo.classId)> & JsonSerializable & JsonDeserializable<$(classInfo.classId)> {
                $(serTokens)
                $(deserTokens)
                public func toJson(): String {
                    let buffer = ByteBuffer()
                    let writer = JsonWriter(buffer)
                    writer.writeValue(this)
                    writer.flush()
                    String.fromUtf8(buffer.bytes())
                }
                public static func fromJson(jsonStr: String): $(classInfo.classId) {
                    let buffer = ByteBuffer()
                    unsafe { buffer.write(jsonStr.rawData()) }
                    var reader = JsonReader(buffer)
                    $(classInfo.classId).fromJson(reader)
                }
            }
        )
    }
}