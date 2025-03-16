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

public class BindFieldInfo {
    let filedName: String
    let typeNode: TypeNodeInfo
    let declType: TypeNode
    let varDecl: VarDecl
    var bindName: String = ""
    var timeformat: String = ""
    var defValue: ?String = None

    init(vd: VarDecl) {
        let supportTypes = "String, Opition<String>, PrimitiveType, ArrayList<String>, Array<Strng>, DateTime"
        this.varDecl = vd
        this.typeNode = TypeNodeInfo(supportTypes)
        this.typeNode.parse(vd.toTokens(), vd.declType)
        this.declType = vd.declType

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
}

class BindFieldGenerator {
    BindFieldGenerator(let varId: Token, let info: BindFieldInfo) {
    }

    public func genBindTokens(): Tokens {
        if (info.typeNode.isOptionStringType()) {
            return optStringTokens()
        } else if (info.typeNode.isStringType()) {
            return stringTokens()
        } else if (info.typeNode.isPrimitive) {
            return primitiveTokens()
        } else if (info.typeNode.isOptionPrimitiveType()) {
            return optPrimitiveTokens()
        } else if (info.typeNode.isArrayStringType()) {
            return arrayStringTokens()
        } else if (info.typeNode.isArrayListStringType()) {
            return arrayListStringTokens()
        } else if (info.typeNode.isDateTimeType()) {
            return datetimeTokens()
        } else if (info.typeNode.isOptionDateTimeType()) {
            return optDatetimeTokens()
        }
        Tokens()
    }

    public func optStringTokens(): Tokens {
         if (let Some(dv) <- info.defValue) {
            quote($(varId): source.getOne($(info.keyName())).getOrDefault({=>$dv})
            )
        } else {
            if (let Some(dv) <- getDefValueOfType(info.varDecl)) {
                quote($(varId): {=>
                        let r: ?String = if (let Some(v)<-source.getOne($(info.keyName()))) {
                            Some(v)
                        } else {
                            $dv
                        }
                        r
                    }()
                )
            } else {
                quote($(varId): {=>
                        let r: ?String = if (let Some(v)<-source.getOne($(info.keyName()))) {
                            Some(v)
                        } else {
                            None
                        }
                        r
                    }()
                )
            }
        }
    }

    public func stringTokens(): Tokens {
        if (let Some(dv) <- info.defValue) {
            quote($(varId): source.getOne($(info.keyName())).getOrDefault({=>$dv})
            )
        } else {
            if (let Some(dv) <- getDefValueOfType(info.varDecl)) {
                quote($(varId): source.getOne($(info.keyName())).getOrDefault({=>$dv})
                )
            } else {
                quote($(varId): source.getOne($(info.keyName())).getOrThrow()
                )
            }
        }
    }

    public func primitiveTokens(): Tokens {
        if (let Some(dv) <- info.defValue) {
            quote(
                $(varId): $(info.typeNode.vtype).parse(source.getOne($(info.keyName())).getOrDefault({=>$dv}))
            )
        } else {
            if (let Some(dv) <- getDefValueOfType(info.varDecl)) {
                quote($(varId): {=>
                        let r: $(info.typeNode.vtype) = if (let Some(v)<-source.getOne($(info.keyName()))) {
                            $(info.typeNode.vtype).parse(v)
                        } else {
                            $dv
                        }
                        r
                    }() 
                )
            } else {
                quote(
                    $(varId): $(info.typeNode.vtype).parse(source.getOne($(info.keyName())).getOrThrow())
                )
            }
        }
    }

    public func optPrimitiveTokens(): Tokens {
        if (let Some(dv) <- info.defValue) {
            quote(
                $(varId): $(info.typeNode.genericType).parse(source.getOne($(info.keyName())).getOrDefault({=>$((dv))}))
            )
        } else {
            if (let Some(dv) <- getDefValueOfType(info.varDecl)) {
                quote($(varId): {=>
                        let r: ?$(info.typeNode.genericType) = if (let Some(v)<-source.getOne($(info.keyName()))) {
                            Some($(info.typeNode.genericType).parse(v))
                        } else {
                            $dv
                        }
                        r
                    }() 
                )
            } else {
                quote($(varId): {=>
                        let r: ?$(info.typeNode.genericType) = if (let Some(v)<-source.getOne($(info.keyName()))) {
                            Some($(info.typeNode.genericType).parse(v))
                        } else {
                            None
                        }
                        r
                    }()
                )
            }
        }
    }

    public func arrayStringTokens(): Tokens {
        quote($(varId): source.getAll($(info.keyName())).toArray()
        )
    }

    public func arrayListStringTokens(): Tokens {
        quote($(varId): ArrayList(source.getAll($(info.keyName())))
        )
    }

    public func datetimeTokens(): Tokens {
        if (info.timeformat != "") {
            if (let Some(dv) <- info.defValue) {
                quote(
                    $(varId): DateTime.parse(source.getOne($(info.keyName())).getOrDefault({=>$(dv)}), $(info.timeformat))
                )
            } else {
                if (let Some(dv) <- getDefValueOfType(info.varDecl)) {
                    quote($(varId): {=>
                            let r: DateTime = if (let Some(v)<-source.getOne($(info.keyName()))) {
                                DateTime.parse(v, $(info.timeformat))
                            } else {
                                $dv
                            }
                            r
                        }() 
                    )
                } else {
                    quote(
                        $(varId): DateTime.parse(source.getOne($(info.keyName())).getOrThrow(), $(info.timeformat))
                    )
                }
            }
        } else {
            if (let Some(dv) <- info.defValue) {
                quote(
                    $(varId): DateTime.parse(source.getOne($(info.keyName())).getOrDefault({=>$(dv)}))
                )
            } else {
                if (let Some(dv) <- getDefValueOfType(info.varDecl)) {
                    quote($(varId): {=>
                            let r: DateTime = if (let Some(v)<-source.getOne($(info.keyName()))) {
                                DateTime.parse(v)
                            } else {
                                $dv
                            }
                            r
                        }() 
                    )
                } else {
                    quote(
                        $(varId): DateTime.parse(source.getOne($(info.keyName())).getOrThrow())
                    )
                }
            }
        }
    }

    public func optDatetimeTokens(): Tokens {
        if (info.timeformat != "") {
            if (let Some(dv) <- info.defValue) {
                quote(
                    $(varId): DateTime.parse(source.getOne($(info.keyName())).getOrDefault({=>$(dv)}), $(info.timeformat))
                )
            } else {
                if (let Some(dv) <- getDefValueOfType(info.varDecl)) {
                    quote($(varId): {=>
                            let r: ?DateTime = if (let Some(v)<-source.getOne($(info.keyName()))) {
                                Some(DateTime.parse(v, $(info.timeformat)))
                            } else {
                                $dv
                            }
                            r
                        }() 
                    )
                } else {
                    quote($(varId): {=>
                            let r: ?DateTime = if (let Some(v)<-source.getOne($(info.keyName()))) {
                                Some(DateTime.parse(v, $(info.timeformat)))
                            } else {
                                None
                            }
                            r
                        }()
                    )
                }
            }
        } else {
            if (let Some(dv) <- info.defValue) {
                quote(
                    $(varId): DateTime.parse(source.getOne($(info.keyName())).getOrDefault({=>$(dv)}))
                )
            } else {
                if (let Some(dv) <- getDefValueOfType(info.varDecl)) {
                    quote($(varId): {=>
                            let r: ?DateTime = if (let Some(v)<-source.getOne($(info.keyName()))) {
                                Some(DateTime.parse(v))
                            } else {
                                $dv
                            }
                            r
                        }() 
                    )
                } else {
                    quote($(varId): {=>
                            let r: ?DateTime = if (let Some(v)<-source.getOne($(info.keyName()))) {
                                Some(DateTime.parse(v))
                            } else {
                                None
                            }
                            r
                        }() 
                    )
                }
            }
        }
    }
}
