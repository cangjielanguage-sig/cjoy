/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.bind.generate

import std.ast.*
import std.collection.Map
import net.http.HttpRequest
import cjoy.utils.{parseKVAttr, TypeNodeInfo, getDefValueOfType}
import cjoy.JoyBindMeta

public class BindFieldInfo {
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
        parseKVAttr(attr, "BindField",
            {
                ident: Token, value: Token => match (ident.value) {
                    case "name" => this.bindName = value.value
                    case "timeformat" => this.timeformat = value.value
                    case "default" => this.defValue = value.value
                    case _ => throw Exception("BindField attriable should be name, from, timeformat")
                }
            })
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
                    "BindField macro only using for the var field of struct or class", "")
                throw Exception("BindField macro only using for the var field of struct or class")
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

class BindFieldGenerator {
    BindFieldGenerator(let varId: Token, let info: BindFieldInfo) {
    }

    public func genBindTokens(): Tokens {
        let vType = match (info.declType) {
            case x: PrefixType => quote(Option<$(x.baseType)>)
            case _ => info.declType.toTokens()
        }
        if (let Some(dv) <- getDefValueOfType(info.declType)) {
            return quote(
                $(varId): $(vType).bind(source, $(info.keyName()), $(info.getDefValue()), $(info.getTimeformat())).getOrDefault({=>$dv}))
        } else {
            return quote(
                $(varId): $(vType).bind(source, $(info.keyName()), $(info.getDefValue()), $(info.getTimeformat())).getOrThrow())
        }
        
    }
}
