/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package cjoy.macros.generate

import std.ast.*
import std.collection.*

public enum ParamCatgory {
    PC_PATH | PC_QUERY | PC_POSTFORM | PC_HEADER | PC_CONTEXT | PC_BODY | PC_COOKIE | PC_NONE
}

class ParamInfo {
    let marcroName: String
    let catgory: ParamCatgory

    // the name of param in content
    var name: String = ""

    // the name of decl param
    var pname: Token = Token()

    // the type of decl param
    var ptype: Token = Token()

    // the type of Array<T>
    var pGenericType: Token = Token()

    // the defalt value for query, postform, header
    var defValue: String = ""

    var isPrimitive: Bool = false

    init(marcroName: String, catgory: ParamCatgory) {
        this.marcroName = marcroName
        this.catgory = catgory
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

    func getDeclVarTokens(): Tokens {
        match (catgory) {
            case PC_PATH => getXCateVarTokens("getParam", array: false)
            case PC_QUERY => getXCateVarTokens("getQuery", array: true)
            case PC_POSTFORM => getXCateVarTokens("getPostForm", array: true)
            case PC_CONTEXT => getCtxCateVarTokens()
            case PC_HEADER => getHeaderCateVarTokens()
            case PC_COOKIE => getCookieCateVarTokens()
            case PC_BODY => getBodyCateVarTokens()
            case PC_NONE => getOtherVarTokens()
        }
    }

    private func getOtherVarTokens(): Tokens {
        if (ptype.value == "JoyContext") {
            if (pname.value == "ctx") {
                Tokens()
            } else {
                quote(
                    let $(pname) = ctx
                )
            }
        } else {
            throw Exception("not support param type ${ptype.value} for no macro")
        }
    }

    private func getCtxCateVarTokens(): Tokens {
        // context param
        if (ptype.value == "Option") {
            return quote(
                let $(pname): ?$(pGenericType)= ctx.getCtxParm($(this.getName()))
            )
        } else {
            return quote(
                let $(pname): $(ptype)= ctx.getCtxParm<$(ptype)>($(this.getName())).getOrThrow()
            )
        }
    }

    private func getBodyCateVarTokens(): Tokens {
        // body param
        if (isOptionStringType()) {
            return quote(
                let $(pname) = Some(ctx.readString())
            )
        }
        if (isStringType()) {
            return quote(
                let $(pname) = ctx.readString()
            )
        }
        if (ptype.value == "Option") {
            return quote(
                let $(pname): ?$(pGenericType) = ctx.readJson<$(pGenericType)>()
            )
        } else {
            return quote(
                let $(pname): $(ptype) = ctx.readJson<$(ptype)>().getOrThrow()
            )
        }
    }

    private func getXCateVarTokens(fname: String, array!: Bool = false): Tokens {
        // query, param, postform
        let fn = Token(TokenKind.IDENTIFIER, fname)
        if (isOptionStringType()) {
            return quote(
                let $(pname) = ctx.$(fn)($(this.getName()))
            )
        }

        if (isStringType()) {
            if (defValue != "") {
                return quote(
                    let $(pname) = ctx.$(fn)($(this.getName())).getOrDefault({=>$(defValue)})
                )
            } else {
                return quote(
                    let $(pname) = ctx.$(fn)($(this.getName())).getOrThrow()
                )
            }
        }

        if (isArrayStringType() && array) {
            let fnl = Token(TokenKind.IDENTIFIER, fname + "List")
            return quote(
                let $(pname) = ctx.$(fnl)($(this.getName())).toArray()
            )
        }

        if (isArrayListStringType() && array) {
            let fnl = Token(TokenKind.IDENTIFIER, fname + "List")
            return quote(
                let $(pname) = ctx.$(fnl)($(this.getName()))
            )
        }

        if (isPrimitive) {
            if (defValue != "") {
                return quote(
                    let $(pname) = $(ptype).parse(ctx.$(fn)($(this.getName())).getOrDefault({=>$(defValue)}))
                )
            } else {
                return quote(
                    let $(pname) = $(ptype).parse(ctx.$(fn)($(this.getName())).getOrThrow())
                )
            }
        }
        Tokens()
    }

    private func getHeaderCateVarTokens(): Tokens {
        // header param
        if (isOptionStringType()) {
            return quote(
                let $(pname) = ctx.readHeader($(this.getName()))
            )
        }

        if (isStringType()) {
            if (defValue != "") {
                return quote(
                    let $(pname) = ctx.readHeader($(this.getName())).getOrDefault({=>$(defValue)})
                )
            } else {
                return quote(
                    let $(pname) = ctx.readHeader($(this.getName())).getOrThrow()
                )
            }
        }

        if (isArrayStringType()) {
            return quote(
                let $(pname) = ctx.readHeaders($(this.getName())).toArray()
            )
        }

        if (isArrayListStringType()) {
            return quote(
                let $(pname) = ArrayList(ctx.readHeaders($(this.getName())))
            )
        }

        if (isPrimitive) {
            if (defValue != "") {
                return quote(
                    let $(pname) = $(ptype).parse(ctx.readHeader($(this.getName())).getOrDefault({=>$(defValue)}))
                )
            } else {
                return quote(
                    let $(pname) = $(ptype).parse(ctx.readHeader($(this.getName())).getOrThrow())
                )
            }
        }
        Tokens()
    }

    private func getCookieCateVarTokens(): Tokens {
        // cookie param
        if (isOptionStringType()) {
            return quote(
                let $(pname) = ctx.readCookie($(this.getName()))
            )
        }

        if (isStringType()) {
            if (defValue != "") {
                return quote(
                    let $(pname) = ctx.readCookie($(this.getName())).getOrDefault({=>$(defValue)})
                )
            } else {
                return quote(
                    let $(pname) = ctx.readCookie($(this.getName())).getOrThrow()
                )
            }
        }

        if (isPrimitive) {
            if (defValue != "") {
                return quote(
                    let $(pname) = $(ptype).parse(ctx.readCookie($(this.getName())).getOrDefault({=>$(defValue)}))
                )
            } else {
                return quote(
                    let $(pname) = $(ptype).parse(ctx.readCookie($(this.getName())).getOrThrow())
                )
            }
        }
        Tokens()
    }

    private func isOptionStringType(): Bool {
        ptype.value == "Option" && pGenericType.value == "String"
    }

    private func isStringType(): Bool {
        ptype.value == "String" && pGenericType.value == ""
    }

    private func isArrayStringType(): Bool {
        ptype.value == "Array" && pGenericType.value == "String"
    }

    private func isArrayListStringType(): Bool {
        ptype.value == "ArrayList" && pGenericType.value == "String"
    }

    func parseFuncParam(input: Tokens): Unit {
        let supportTypes = "String, PrimitiveType, T <: JsonDeserializable, Opition<T <: JsonDeserializable>, Opition<String>, ArrayList<String>, Array<Strng>"
        let funcParam = FuncParam(input)
        pname = funcParam.identifier
        let paramType = funcParam.paramType
        match (paramType) {
            case x: PrimitiveType =>
                ptype = x.keyword
                isPrimitive = true
            case x: PrefixType =>
                ptype = Token(TokenKind.IDENTIFIER, "Option")
                let gType = x.baseType
                if (gType is RefType) {
                    pGenericType = (gType as RefType).getOrThrow().identifier
                } else {
                    diagReport(DiagReportLevel.ERROR, input, "unsuported type", "param ref type must be ${supportTypes}"
                    )
                    throw Exception("unsuported type")
                }
            case x: RefType =>
                ptype = x.identifier
                if (ptype.value == "Int" || ptype.value == "UInt") {
                    isPrimitive = true
                }

                if (x.typeArguments.size != 1 && x.typeArguments.size != 0) {
                    diagReport(DiagReportLevel.ERROR, input, "unsuported type", "param ref type must be ${supportTypes}"
                    )
                    throw Exception("unsuported type")
                }

                if (x.typeArguments.size == 1) {
                    let gType = x.typeArguments[0]
                    if (gType is RefType) {
                        pGenericType = (gType as RefType).getOrThrow().identifier
                    } else {
                        diagReport(DiagReportLevel.ERROR, input, "unsuported type",
                            "param ref type must be ${supportTypes}")
                        throw Exception("unsuported type")
                    }
                }
            case _ =>
                diagReport(DiagReportLevel.ERROR, input, "unsuported type", "param ref type must be ${supportTypes}")
                throw Exception("unsuported type")
        }
    }

    func parseAttr(attr: Tokens): Unit {
        parseKVAttr(attr, marcroName,
            {
                ident: Token, value: Token => match (ident.value) {
                    case "name" => this.name = value.value
                    case "default" => this.defValue = value.value
                    case _ => throw Exception("${marcroName} attriable should be name, defalut")
                }
            })
    }
}

func parseKVAttr(attr: Tokens, marcroName: String, cb: (ident: Token, value: Token) -> Unit): Unit {
    if ((attr.size + 1) % 4 != 0) {
        diagReport(DiagReportLevel.ERROR, attr, "${marcroName} attriable should link 'attrname= value'", "")
        throw Exception("${marcroName} attriable should link 'attrname= value'")
    }

    for (idx in 0..attr.size : 4) {
        let ident = attr.get(idx)
        if (ident.kind != TokenKind.IDENTIFIER) {
            diagReport(DiagReportLevel.ERROR, attr,
                "${marcroName} attriable name should be a identitier, but is ${ident.kind}", "")
            throw Exception("${marcroName} attriable name should be a identitier")
        }
        let assign = attr.get(idx + 1)
        if (assign.kind != TokenKind.ASSIGN) {
            diagReport(DiagReportLevel.ERROR, attr, "${marcroName} attriable name should be =, but is ${ident.kind}", ""
            )
            throw Exception("${marcroName} attriable name should be =")
        }

        let value = attr.get(idx + 2)
        cb(ident, value)
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

public func parseParam(marcroName: String, catgory: ParamCatgory, input: Tokens): Unit {
    parseParam(marcroName, catgory, None, input)
}

public func parseParam(marcroName: String, catgory: ParamCatgory, attr: ?Tokens, input: Tokens): Unit {
    let paramInfo: ParamInfo = ParamInfo(marcroName, catgory)
    paramInfo.parse(input)
    if (let Some(a) <- attr) {
        paramInfo.parseAttr(a)
    }
    ParamInfoCache.addCache(paramInfo)
}
