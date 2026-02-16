/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.bind.macros

import std.ast.*
import std.collection.{HashMap}
import cjoy.utils.ast.{parserAttrs, getDefValueOfType}
import cjoy.utils.{MapToString, MapListGetFunc}

class BindFieldInfo {
    let filedName: String
    let declType: TypeNode
    var bindName: String = ""
    var timeformat: String = ""
    var defValue: ?String = None

    init(vd: VarDecl) {
        this.declType = vd.declType
        this.filedName = vd.identifier.value
    }

    func keyName(): String {
        if (bindName != "") {
            return bindName
        }
        return filedName
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "timeformat", "default"], macroName: "BindField")
        this.bindName = map.getString("name") ?? ""
        this.timeformat = map.getString("timeformat") ?? ""
        this.defValue = map.getString("default")
    }

    public static func parse(attr: Tokens, input: Tokens): Unit {
        assertParentContext("Bind")
        let varDecl: Decl = parseDecl(input)
        match (varDecl) {
            case vd: VarDecl =>
                let info = BindFieldInfo(vd)
                info.parseAttr(attr)
                BindInfoCache.addCache(info.filedName, info)
            case _ =>
                diagReport(DiagReportLevel.ERROR, input,
                    "@BindField macro only using for the var field of struct or class", "")
                return
        }
    }

    func getDefValue(): Tokens {
        if (let Some(v) <- defValue) {
            return quote($(v))
        }
        return quote(None)
    }

    func getTimeformat(): Tokens {
        if (timeformat != "") {
            return quote($(timeformat))
        }
        return quote(None)
    }
}

class BindInfoCache {
    static let FIELD_INFOS: HashMap<String, BindFieldInfo> = HashMap()

    public static func clear(): Unit {
        FIELD_INFOS.clear()
    }

    public static func addCache(vid: String, info: BindFieldInfo): Unit {
        FIELD_INFOS.add(vid, info)
    }

    public static func create(vd: VarDecl): BindFieldGenerator {
        let fieldInfo = FIELD_INFOS.get(vd.identifier.value) ?? BindFieldInfo(vd)
        BindFieldGenerator(vd.identifier, fieldInfo, vd)
    }
}

class BindFieldGenerator {
    BindFieldGenerator(let varId: Token, let info: BindFieldInfo, let varDecl: VarDecl) {
    }

    public func genBindTokens(): Tokens {
        let vType = match (info.declType) {
            case x: PrefixType => quote(Option<$(x.baseType)>)
            case _ => info.declType.toTokens()
        }

        // 尝试获取字段声明中设置的默认值，而不是只依赖类型默认值
        if (let Some(dv) <- getVarDeclDefValue()) {
            return quote(
                $(varId): $(vType).bind(source, $(info.keyName()), $(info.getDefValue()), $(info.getTimeformat())).getOrDefault({=>$dv}))
        } else if (let Some(dv) <- getDefValueOfType(info.declType)) {
            return quote(
                $(varId): $(vType).bind(source, $(info.keyName()), $(info.getDefValue()), $(info.getTimeformat())).getOrDefault({=>$dv}))
        } else {
            let msg = "not found bind ${varId.value} valude"
            return quote(
                $(varId): $(vType).bind(source, $(info.keyName()), $(info.getDefValue()), $(info.getTimeformat())).getOrThrow({=>throw Exception($msg)}))
        }
    }

    public func getVarDeclDefValue(): Option<Tokens> {
        try {
            let expr = varDecl.expr
            return expr.toTokens()
        } catch (_: ASTException) {
            return None
        }
    }
}
