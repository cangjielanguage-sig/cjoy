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
import cjoy.utils.{parseKVAttr, TypeNodeInfo}

public class BindFieldInfo {
    let filedName: String
    let typeNode: TypeNodeInfo
    var bindName: String = ""
    var timeformat: String = ""
    var defValue: ?String = ""

    init(vd: VarDecl) {
        let supportTypes = "String, PrimitiveType, Opition<String>, ArrayList<String>, Array<Strng>"
        this.typeNode = TypeNodeInfo(supportTypes)
        this.typeNode.parse(vd.toTokens(), vd.declType)

        let varId: String = vd.identifier.value
        this.filedName = varId
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
        let varDecl: Decl = parseDecl(input)
        if (!(varDecl is VarDecl)) {
            diagReport(DiagReportLevel.ERROR, input, "BindField macro only using for the var field of struct or class",
                "")
            throw Exception("BindField macro only using for the var field of struct or class")
        }

        let vd = (varDecl as VarDecl).getOrThrow()
        let info = BindFieldInfo(vd)
        info.parseAttr(attr)
        BindInfoCache.addCache(info.filedName, info)
    }
}

class BindFieldGenerator {
    BindFieldGenerator(let varId: Token, let info: BindFieldInfo) {
    }

    public func genBindTokens(): Tokens {
        if (info.typeNode.isOptionStringType()) {
            return optStringTokens()
        }
        if (info.typeNode.isStringType()) {
            return stringTokens()
        }
        if (info.typeNode.isPrimitive) {
            return primitiveTokens()
        }
        if (info.typeNode.isOptionPrimitiveType()) {
            return optPrimitiveTokens()
        }
        if (info.typeNode.isArrayStringType()) {
            return arrayStringTokens()
        }
        if (info.typeNode.isArrayListStringType()) {
            return arrayListStringTokens()
        }
        if (info.typeNode.isDateTimeType() || info.typeNode.isOptionDateTimeType()) {
            return datetimeTokens()
        }
        Tokens()
    }

    public func optStringTokens(): Tokens {
        quote(obj.$(varId) = source.getOne($(info.keyName()))
        )
    }

    public func stringTokens(): Tokens {
        if (let Some(dv) <- info.defValue) {
            quote(obj.$(varId) = source.getOne($(info.keyName())).getOrDefault({=>$((dv))})
            )
        } else {
            quote(
                if (let Some(v) <- source.getOne($(info.keyName()))) {
                    obj.$(varId) = v
                }
            )
        }
    }

    public func primitiveTokens(): Tokens {
        if (let Some(dv) <- info.defValue) {
            quote(
                obj.$(varId) = $(info.typeNode.vtype).parse(source.getOne($(info.keyName())).getOrDefault({=>$(dv)}))
            )
        } else {
            quote(
                if (let Some(v) <- source.getOne($(info.keyName()))) {
                    obj.$(varId) = $(info.typeNode.vtype).parse(v)
                }
            )
        }
    }

    public func optPrimitiveTokens(): Tokens {
        if (let Some(dv) <- info.defValue) {
            quote(
                obj.$(varId) = $(info.typeNode.genericType).parse(source.getOne($(info.keyName())).getOrDefault({=>$((dv))}))
            )
        } else {
            quote(
                if (let Some(v) <- source.getOne($(info.keyName()))) {
                    obj.$(varId) = $(info.typeNode.genericType).parse(v)
                }
            )
        }
    }

    public func arrayStringTokens(): Tokens {
        quote(obj.$(varId) = source.getAll($(info.keyName())).toArray()
        )
    }

    public func arrayListStringTokens(): Tokens {
        quote(obj.$(varId) = ArrayList(source.getAll($(info.keyName())))
        )
    }

    public func datetimeTokens(): Tokens {
        if (info.timeformat != "") {
            if (let Some(dv) <- info.defValue) {
                quote(
                    obj.$(varId) = DateTime.parse(source.getOne($(info.keyName())).getOrDefault({=>$(dv)}), $(info.timeformat))
                )
            } else {
                quote(
                    if (let Some(v) <- source.getOne($(info.keyName()))) {
                        obj.$(varId) = DateTime.parse(v, $(info.timeformat))
                    }
                )
            }
        } else {
            if (let Some(dv) <- info.defValue) {
                quote(
                    obj.$(varId) = DateTime.parse(source.getOne($(info.keyName())).getOrDefault({=>$(dv)}))
                )
            } else {
                quote(
                    if (let Some(v) <- source.getOne($(info.keyName()))) {
                        obj.$(varId) = DateTime.parse(v)
                    }
                )
            }
        }
    }
}