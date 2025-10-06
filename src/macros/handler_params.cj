/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.macros

import std.ast.*
import std.collection.*
import cjoy.utils.{parserAttrs, MapToString, MapListGetFunc, TypeNodeInfo}

open class ParamInfo {
    let marcroName: String

    // the name of param in content
    var name: String = ""

    // the name of decl param
    var pname: Token = Token()

    // the type info of param
    var typeNode: TypeNodeInfo

    // the defalt value for query, postform, header
    var defValue: String = ""

    var paramType: ?TypeNode = None

    // the timeformat of datatime
    var timeformat: String = ""

    init(marcroName: String) {
        this.marcroName = marcroName
        let supportTypes = "String, PrimitiveType, T <: JsonDeserializable, Opition<T <: JsonDeserializable>, Opition<String>, ArrayList<String>, Array<Strng>"
        this.typeNode = TypeNodeInfo(supportTypes)
    }

    func parse(input: Tokens): Unit {
        let funcParam = FuncParam(input)
        parseFuncParam(funcParam)
    }

    func getName(): String {
        if (name != "") {
            return name
        }
        return pname.value
    }

    /**
     * @throws Exception if no macro in param
     */
    public open func genTokens(): Tokens {
        if (typeNode.vtype.value == "JoyContext") {
            if (pname.value == "ctx") {
                Tokens()
            } else {
                quote(let $(pname) = ctx
                )
            }
        } else {
            throw Exception(
                "must using macro for param `${getName()}: ${typeNode.vtype.value}` like @PathParam, @QueryParam")
        }
    }

    func getDefValue(): Tokens {
        if (defValue != "") {
            return quote($(defValue))
        }
        return quote(Option<String>.None)
    }

    func getTimeformat(): Tokens {
        if (timeformat != "") {
            return quote($(timeformat))
        }
        return quote(Option<String>.None)
    }

    func getType(): Tokens {
        match (paramType.getOrThrow()) {
            case x: PrefixType => quote(Option<$(x.baseType)>)
            case _ => paramType.getOrThrow().toTokens()
        }
    }

    func parseFuncParam(funcParam: FuncParam): Unit {
        pname = funcParam.identifier
        this.paramType = funcParam.paramType
        typeNode.parse(funcParam.toTokens(), this.paramType.getOrThrow())
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "timeformat", "default"], macroName: marcroName)
        this.name = map.getString("name") ?? ""
        this.timeformat = map.getString("timeformat") ?? ""
        this.defValue = map.getString("default") ?? ""
    }
}

class PathParamVarGenerator <: ParamInfo {
    init() {
        super("PathParam")
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.params, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow() 
        )
    }
}

class QueryParamVarGenerator <: ParamInfo {
    init() {
        super("QueryParam")
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.httpContext.request.url.queryForm, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow()
        )
    }
}

class PostFormParamVarGenerator <: ParamInfo {
    init() {
        super("PostFormParam")
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.httpContext.request.form, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow() 
        )
    }
}

class HeaderParamVarGenerator <: ParamInfo {
    init() {
        super("HeaderParam")
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.httpContext.request.headers, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow()
        )
    }
}

class CookieParamVarGenerator <: ParamInfo {
    init() {
        super("CookieParam")
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.cookies, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow() 
        )
    }
}

class ContextParamVarGenerator <: ParamInfo {
    init() {
        super("ContextParam")
    }

    public override func genTokens(): Tokens {
        if (typeNode.vtype.value == "Option") {
            return quote(
                let $(pname): ?$(typeNode.genericType)= ctx.getCtxParam<$(typeNode.genericType)>($(this.getName()))
            )
        } else {
            return quote(
                let $(pname): $(typeNode.vtype)= ctx.getCtxParam<$(typeNode.vtype)>($(this.getName())).getOrThrow()
            )
        }
    }
}

class BodyParamVarGenerator <: ParamInfo {
    init() {
        super("BodyParam")
    }

    public override func genTokens(): Tokens {
        // body param
        if (typeNode.isStringType() || typeNode.isOptionStringType()) {
            return quote(let $(pname) = ctx.readString()
            )
        }
        if (typeNode.vtype.value == "Option") {
            return quote(let $(pname): ?$(typeNode.genericType) = ctx.readJson<$(typeNode.genericType)>()
            )
        } else {
            return quote(let $(pname): $(typeNode.vtype) = ctx.readJson<$(typeNode.vtype)>().getOrThrow()
            )
        }
    }
}

class QueryBindParamVarGenerator <: ParamInfo {
    init() {
        super("QueryBindParam")
    }

    public override func genTokens(): Tokens {
        if (typeNode.vtype.value == "Option") {
            return quote(let $(pname): ?$(typeNode.genericType) = ctx.bindQuery<$(typeNode.genericType)>()
            )
        } else {
            return quote(let $(pname): $(typeNode.vtype) = ctx.bindQuery<$(typeNode.vtype)>().getOrThrow()
            )
        }
    }
}

class PostFormBindParamVarGenerator <: ParamInfo {
    init() {
        super("PostFormBindParam")
    }

    public override func genTokens(): Tokens {
        if (typeNode.vtype.value == "Option") {
            return quote(
                let $(pname): ?$(typeNode.genericType) = ctx.bindPostForm<$(typeNode.genericType)>()
            )
        } else {
            return quote(
                let $(pname): $(typeNode.vtype) = ctx.bindPostForm<$(typeNode.vtype)>().getOrThrow()
            )
        }
    }
}

class HeaderBindParamVarGenerator <: ParamInfo {
    init() {
        super("HeaderBindParam")
    }

    public override func genTokens(): Tokens {
        if (typeNode.vtype.value == "Option") {
            return quote(let $(pname): ?$(typeNode.genericType) = ctx.bindHeader<$(typeNode.genericType)>()
            )
        } else {
            return quote(let $(pname): $(typeNode.vtype) = ctx.bindHeader<$(typeNode.vtype)>().getOrThrow()
            )
        }
    }
}

func createParamVarGenerator(name: String): ParamInfo {
    match (name) {
        case "PathParam" => PathParamVarGenerator()
        case "QueryParam" => QueryParamVarGenerator()
        case "PostFormParam" => PostFormParamVarGenerator()
        case "ContextParam" => ContextParamVarGenerator()
        case "HeaderParam" => HeaderParamVarGenerator()
        case "CookieParam" => CookieParamVarGenerator()
        case "BodyParam" => BodyParamVarGenerator()
        case "QueryBindParam" => QueryBindParamVarGenerator()
        case "PostFormBindParam" => PostFormBindParamVarGenerator()
        case "HeaderBindParam" => HeaderBindParamVarGenerator()
        case _ => ParamInfo("")
    }
}

class ParamInfoCache {
    static let PARAMS: ArrayList<ParamInfo> = ArrayList()

    static func clear(): Unit {
        PARAMS.clear()
    }

    static func addCache(info: ParamInfo): Unit {
        PARAMS.add(info)
    }

    static func findByParamName(name: String): ?ParamInfo {
        PARAMS |> filter {it: ParamInfo => it.pname.value == name} |> first
    }
}

func parseParam(name: String, input: Tokens): Unit {
    parseParam(name, None, input)
}

func parseParam(name: String, attr: ?Tokens, input: Tokens): Unit {
    let paramInfo: ParamInfo = createParamVarGenerator(name)
    paramInfo.parse(input)
    if (let Some(a) <- attr) {
        paramInfo.parseAttr(a)
    }
    ParamInfoCache.addCache(paramInfo)
}
