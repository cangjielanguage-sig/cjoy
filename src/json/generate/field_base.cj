/*
* Copyright (c) lanlingx 2024-2024. All rights resvered.
*/

package cjoy.json.generate

import std.ast.*
import std.collection.Map

public class JsonFieldInfo {
    let originName: String
    var newName: String = ""
    var ignore: Bool = false
    var omitempty: Bool = false
    var timeformat: String = ""

    init (name: String) {
        this.originName = name; 
    }

    func jsonKeyName(): String {
        if (ignore) {
            return ""
        }
        if (newName != "") {
            return newName
        }
        return originName
    }

    func parseAttr(attr: Tokens): Unit {
        if ((attr.size +1) % 4 !=0) {
            diagReport(DiagReportLevel.ERROR , attr , "JsonField attriable should link 'attrname= value'", "")
            throw Exception("JsonField attriable should link 'attrname= value'")
        }

        for (idx in 0..attr.size : 4) {
            let ident = attr.get(idx)
            if (ident.kind != TokenKind.IDENTIFIER) {
                diagReport(DiagReportLevel.ERROR , attr , "JsonField attriable name should be a identitier, but is ${ident.kind}", "")
                throw Exception("JsonField attriable name should be a identitier")
            }
            let assign = attr.get(idx+1)
             if (assign.kind != TokenKind.ASSIGN) {
                diagReport(DiagReportLevel.ERROR , attr , "JsonField attriable name should be =, but is ${ident.kind}", "")
                throw Exception("JsonField attriable name should be =")
            }
            
            let value = attr.get(idx+2)
            match (ident.value) {
                case "name" => this.newName = value.value
                case "ignore" => this.ignore = "true" == value.value
                case "omitempty" => this.omitempty = "true" == value.value
                case "timeformat" => this.timeformat = value.value
                case _ => throw Exception("JsonField attriable should be name, ignore, omitempty, timeformat")
            }
        }
    }

    public static func parse(attr: Tokens, input: Tokens): Tokens {
        let varDecl: Decl = parseDecl(input)
        if (!(varDecl is VarDecl)) {
            diagReport(DiagReportLevel.ERROR , input , "JsonField macro only using for the var field of struct or class", "")
            throw Exception("JsonField macro only using for the var field of struct or class")
        }
        let varId: String = varDecl.identifier.value

        let info = JsonFieldInfo(varId)
        info.parseAttr(attr)
        JsonInfoCache.addCache(varId, info)
        
        input
    }
}

open class JsonFieldGenerator {
    protected let varId: Token
    protected let varType: TypeNode
    protected let info: JsonFieldInfo

    init(vd: VarDecl, info: JsonFieldInfo){
        this.varId = vd.identifier
        this.varType = vd.declType
        this.info = info
    }
    
    public open func genSerializeTokens(): Tokens {
        quote(writer.writeName($(info.jsonKeyName())).writeValue($(varId))
        )
    }

    public open func genDeserializeTokens(): Tokens {
        quote(case $(info.jsonKeyName()) => obj.$(varId) = reader.readValue<$(varType)>()
        )
    }
}