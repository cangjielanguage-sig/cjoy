/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.generate

import std.ast.*
import std.collection.*
import cjoy.utils.{parserAttrs, MapToString, MapListGetFunc, TypeNodeInfo}

open class ParamInfo {
    let marcroName: String

    var name: String = ""
    var description: String = ""

    var pid: Token = Token()
    var paramType: ?TypeNode = None
    var typeNode: TypeNodeInfo = TypeNodeInfo("")

    init(marcroName: String) {
        this.marcroName = marcroName
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "description"], macroName: "ToolParam")
        this.name = map.getString("name") ?? ""
        this.description = map.getString("description") ?? ""
    }

    func parse(input: Tokens): Unit {
        let funcParam = FuncParam(input)
        parseFuncParam(funcParam)
    }

    func parseFuncParam(funcParam: FuncParam): Unit {
        this.pid = funcParam.identifier
        this.paramType = funcParam.paramType
        this.typeNode.parse(funcParam.toTokens(), funcParam.paramType)
    }

    private func getName(): String {
        if (name != "") {
            return name
        }
        return pid.value
    }

    private func getType(): Tokens {
        match (paramType.getOrThrow()) {
            case x: PrefixType => quote(Option<$(x.baseType)>)
            case _ => paramType.getOrThrow().toTokens()
        }
    }

    func isJoyContext(): Bool {
        typeNode.vtype.value == "JoyContext"
    }

    func isOption(): Bool {
        typeNode.vtype.value == "Option"
    }

    func isComplexType(): Bool {
        if (typeNode.isPrimitive) {
            return false
        }
        if (typeNode.genericIsPrimitive) {
            return false
        }
        let builtTypes = ["String"]
        for (bt in builtTypes) {
            if (typeNode.vtype.value == bt || typeNode.genericType.value == bt) {
                return false
            }
        }
        return true
    }

    // for tool
    public func genVarTokens(): Tokens {
        if (isJoyContext()) {
            if (pid.value == "ctx") {
                Tokens()
            } else {
                quote(let $(pid) = ctx
                )
            }
        } else {
            if (isOption()) {
                quote(var $(pid): $(getType()) = None
                )
            } else {
                quote(var $(pid): Option<$(getType())> = None
                )
            }
        }
    }

    // for tool
    public func genVarComplexTypeTokens(): Tokens {
        if (isJoyContext()) {
            if (pid.value == "ctx") {
                Tokens()
            } else {
                quote(let $(pid) = ctx
                )
            }
        } else {
            quote(let $(pid): $(getType()) = JsonTool.fromJson(arguments_)
            )
        }
    }
    // for tool
    public func genSchemTokens(): Tokens {
        if (isJoyContext()) {
            Tokens()
        } else {
            match (paramType.getOrThrow()) {
                case x: PrefixType => quote(properties.add($(getName()), $(getType()).toJsonSchema($description))
                    )
                case _ => quote(properties.add($(getName()), $(getType()).toJsonSchema($description))
                    required.add($(getName()))
                    )
            }
        }
    }

    public func genSchemComplexTypeTokens(): Tokens {
        if (isJoyContext()) {
            Tokens()
        } else {
            quote(let inputSchema = $(getType()).toJsonSchema($description))
        }
    }

    public func genReadJsonTokens(): Tokens {
        if (typeNode.vtype.value == "JoyContext") {
            Tokens()
        } else {
            quote(case $(getName()) => $(pid) = reader_.readValue<$(getType())>()
            )
        }
    }

    // for resource
    public func genResoureVarTokens(): Tokens {
        if (isJoyContext()) {
            if (pid.value == "ctx") {
                Tokens()
            } else {
                quote(let $(pid) = ctx
                )
            }
        } else {
            quote(let $(pid) = $(getType()).bind(ctx.params, $(getName()), None, None).getOrThrow()
            )
        }
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
        PARAMS |> filter {it: ParamInfo => it.pid.value == name} |> first
    }
}

public func parseParam(marcroName: String, input: Tokens): Unit {
    parseParam(marcroName, None, input)
}

public func parseParam(marcroName: String, attr: ?Tokens, input: Tokens): Unit {
    match (marcroName) {
        case "ToolParam" => assertParentContext("Tool")
        case _ => ()
    }
    let paramInfo: ParamInfo = ParamInfo(marcroName)
    paramInfo.parse(input)
    if (let Some(a) <- attr) {
        paramInfo.parseAttr(a)
    }
    ParamInfoCache.addCache(paramInfo)
}
