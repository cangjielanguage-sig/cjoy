/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.macros.generate

import std.ast.*
import std.collection.*
import cjoy.utils.{parserAttrs, MapToString, MapListGetFunc, TypeNodeInfo}

public enum ParamCatgory {
    PC_PATH
    | PC_QUERY
    | PC_QUERY_BIND
    | PC_POSTFORM
    | PC_POSTFORM_BIND
    | PC_HEADER
    | PC_HEADER_BIND
    | PC_CONTEXT
    | PC_BODY
    | PC_COOKIE
    | PC_NONE
}

open class ParamInfo {
    let marcroName: String
    let catgory: ParamCatgory

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

    init(marcroName: String, catgory: ParamCatgory) {
        this.marcroName = marcroName
        this.catgory = catgory
        let supportTypes = "String, PrimitiveType, T <: JsonDeserializable, Opition<T <: JsonDeserializable>, Opition<String>, ArrayList<String>, Array<Strng>"
        this.typeNode = TypeNodeInfo(supportTypes)
    }

    func parse(input: Tokens): Unit {
        parseFuncParam(input)
    }

    func getName(): String {
        if (name != "") {
            return name
        }
        return pname.value
    }

    public open func genTokens(): Tokens {
        if (typeNode.vtype.value == "JoyContext") {
            if (pname.value == "ctx") {
                Tokens()
            } else {
                quote(let $(pname) = ctx
                )
            }
        } else {
            throw Exception("not support param type ${typeNode.vtype.value} for no macro")
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

    private func parseFuncParam(input: Tokens): Unit {
        let funcParam = FuncParam(input)
        pname = funcParam.identifier
        this.paramType = funcParam.paramType
        typeNode.parse(input, this.paramType.getOrThrow())
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
        super("PathParam", ParamCatgory.PC_PATH)
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.params, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow() )
    }
}

class QueryParamVarGenerator <: ParamInfo {
    init() {
        super("QueryParam", ParamCatgory.PC_QUERY)
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.httpContext.request.url.queryForm, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow() )
    }
}

class PostFormParamVarGenerator <: ParamInfo {
    init() {
        super("PostFormParam", ParamCatgory.PC_POSTFORM)
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.httpContext.request.form, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow() )
    }
}

class HeaderParamVarGenerator <: ParamInfo {
    init() {
        super("PostFormParam", ParamCatgory.PC_POSTFORM)
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.httpContext.request.headers, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow() )
    }
}

class CookieParamVarGenerator <: ParamInfo {
    init() {
        super("CookieParam", ParamCatgory.PC_COOKIE)
    }

    public override func genTokens(): Tokens {
        return quote(
            let $(pname) = $(getType()).bind(ctx.cookies, $(getName()), $(getDefValue()), $(getTimeformat())).getOrThrow() )
    }
}

class ContextParamVarGenerator <: ParamInfo {
    init() {
        super("ContextParam", ParamCatgory.PC_CONTEXT)
    }

    public override func genTokens(): Tokens {
        if (typeNode.vtype.value == "Option") {
            return quote(let $(pname): ?$(typeNode.genericType)= ctx.getCtxParm<$(typeNode.genericType)>($(this.getName()))
            )
        } else {
            return quote(
                let $(pname): $(typeNode.vtype)= ctx.getCtxParm<$(typeNode.vtype)>($(this.getName())).getOrThrow()
            )
        }
    }
}

class BodyParamVarGenerator <: ParamInfo {
    init() {
        super("BodyParam", ParamCatgory.PC_BODY)
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
        super("QueryBindParam", ParamCatgory.PC_QUERY_BIND)
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
        super("PostFormBindParam", ParamCatgory.PC_POSTFORM_BIND)
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
        super("HeaderBindParam", ParamCatgory.PC_HEADER_BIND)
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

func createParamVarGenerator(catgory: ParamCatgory): ParamInfo {
    match (catgory) {
        case PC_PATH => PathParamVarGenerator()
        case PC_QUERY => QueryParamVarGenerator()
        case PC_POSTFORM => PostFormParamVarGenerator()
        case PC_CONTEXT => ContextParamVarGenerator()
        case PC_HEADER => HeaderParamVarGenerator()
        case PC_COOKIE => CookieParamVarGenerator()
        case PC_BODY => BodyParamVarGenerator()
        case PC_QUERY_BIND => QueryBindParamVarGenerator()
        case PC_POSTFORM_BIND => PostFormBindParamVarGenerator()
        case PC_HEADER_BIND => HeaderBindParamVarGenerator()
        case PC_NONE => ParamInfo("", ParamCatgory.PC_NONE)
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

public func parseParam(catgory: ParamCatgory, input: Tokens): Unit {
    parseParam(catgory, None, input)
}

public func parseParam(catgory: ParamCatgory, attr: ?Tokens, input: Tokens): Unit {
    let paramInfo: ParamInfo = createParamVarGenerator(catgory)
    paramInfo.parse(input)
    if (let Some(a) <- attr) {
        paramInfo.parseAttr(a)
    }
    ParamInfoCache.addCache(paramInfo)
}
