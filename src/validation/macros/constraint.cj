/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.validation.macros

import std.convert.Parsable
import std.collection.{ArrayList, filter, first, map, collectArrayList}
import cjoy.utils.{MapToString, MapListGetFunc, converterList}
import cjoy.utils.ast.{parserAttrs, joinTokens}
import std.ast.*

enum ConstraintCatgory {
    | CCSize
    | CCLength
    | CCNotEmpty
    | CCNotBlank
    | CCNumberRange
    | CCPattern
    | CCDatetimeRange
    | CCChMobilePhone
    | CCEmail
    | CCIPV4
    | CCEnumStr
    | CCEnumInt
}

open class FieldInfo {
    let constraints: ArrayList<Tokens> = ArrayList()
    var nestedValid: Bool = false
    FieldInfo(let identifier: Token, let inFunc: Bool) {}

    func name(): String {
        identifier.value
    }

    func id(): Token {
        identifier
    }

    private func validateInFunc(constraints: Tokens): Tokens {
        if (constraints.size == 0) {
            quote($(id()).validate("", $nestedValid) )
        } else {
            quote($(id()).validate("", $nestedValid, $constraints))
        }
    }

    private func validateInClass(constraints: Tokens): Tokens {
        let fieldName = Token(TokenKind.IDENTIFIER, "\"\${field}." + name() + "\"")
        if (constraints.size == 0) {
            // 如果字段类型为Any，需要判断是JoyValidatable类型才做检查
            if (name() == "Any") {
                quote(match($(id())) {
                    case x: JoyValidatable => x.validate({=> if(field.isEmpty()) {$(name())} else { $fieldName } }(), $nestedValid) 
                    case _ => ()
                })
            } else {
                quote($(id()).validate({=> if(field.isEmpty()) {$(name())} else { $fieldName } }(), $nestedValid) )
            }
        } else {
            if (name() == "Any") {
                quote(match($(id())) {
                    case x: JoyValidatable => x.$(id()).validate({=> if(field.isEmpty()) {$(name())} else { $fieldName } }(), $nestedValid, $constraints) 
                    case _ => ()
                })
            } else {
                quote($(id()).validate({=> if(field.isEmpty()) {$(name())} else { $fieldName } }(), $nestedValid, $constraints) )
            }
        }
    }

    func genValidateTokens(): Tokens {
        if (constraints.isEmpty() && !nestedValid) {
            return Tokens()
        }

        var tokens = Tokens()
        if (!constraints.isEmpty()) {
            tokens += joinTokens(constraints, Token(TokenKind.COMMA))
        }
        if (inFunc) {
            validateInFunc(tokens)
        } else {
            validateInClass(tokens)
        }
    }
}

class FieldInfoCache {
    static let PARAMS: ArrayList<FieldInfo> = ArrayList()

    static func clear(): Unit {
        PARAMS.clear()
    }

    static func addCache(info: FieldInfo): Unit {
        PARAMS.add(info)
    }

    static func addCache(identifier: Token, inFunc: Bool, constraint: Tokens): Unit {
        for (fd in PARAMS) {
            if (fd.name() == identifier.value) {
                fd.constraints.add(constraint)
                return
            }
        }

        let info: FieldInfo = FieldInfo(identifier, inFunc)
        info.constraints.add(constraint)
        addCache(info)
    }

    static func setNestedValid(identifier: Token, inFunc: Bool): Unit {
        for (fd in PARAMS) {
            if (fd.name() == identifier.value) {
                fd.nestedValid = true
                return
            }
        }

        let info: FieldInfo = FieldInfo(identifier, inFunc)
        info.nestedValid = true
        addCache(info)
    }

    static func findByName(name: String): ?FieldInfo {
        PARAMS |> filter {it: FieldInfo => it.name() == name} |> first
    }
}

abstract class ConstraintGenerator {
    ConstraintGenerator(let marcroName: String) {}

    protected func toConstraint(): Tokens

    protected func parseAttr(attr: Tokens): Unit
}

abstract class MinMaxBaseConstraintGenerator <: ConstraintGenerator {
    var min: String = "0"
    var max: String = "100"
    var msg: String = ""

    init(marcroName: String) {
        super(marcroName)
    }

    protected func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["min", "max", "msg"], macroName: marcroName)
        this.min = map.getString("min") ?? "0"
        this.max = map.getString("max") ?? "100"
        this.msg = map.getString("msg") ?? ""
    }
}

abstract class MsgBaseConstraintGenerator <: ConstraintGenerator {
    var msg: String = ""

    init(marcroName: String) {
        super(marcroName)
    }

    protected func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["msg"], macroName: marcroName)
        this.msg = map.getString("msg") ?? ""
    }
}

class SizeConstraintGenerator <: MinMaxBaseConstraintGenerator {
    init() {
        super("Size")
    }

    protected func toConstraint(): Tokens {
        let min_ = Int.tryParse(min).getOrDefault({=> 0})
        let max_ = Int.tryParse(max).getOrDefault({=> 100})
        quote(SizeConstraint($min_, $max_, $msg))
    }
}

class LengthConstraintGenerator <: MinMaxBaseConstraintGenerator {
    init() {
        super("Length")
    }

    protected func toConstraint(): Tokens {
        let min_ = Int.tryParse(min).getOrDefault({=> 0})
        let max_ = Int.tryParse(max).getOrDefault({=> 100})
        quote(LengthConstraint($min_, $max_, $msg))
    }
}

class RangeConstraintGenerator <: MinMaxBaseConstraintGenerator {
    init() {
        super("Range")
    }

    protected func toConstraint(): Tokens {
        quote(RangeConstraint($(min), $(max), $(msg)))
    }
}

class NotEmptyConstraintGenerator <: MsgBaseConstraintGenerator {
    init() {
        super("NotEmpty")
    }
    protected func toConstraint(): Tokens {
        quote(NotEmptyConstraint($msg))
    }
}

class NotBlankConstraintGenerator <: MsgBaseConstraintGenerator {
    init() {
        super("NotBlank")
    }
    protected func toConstraint(): Tokens {
        quote(NotBlankConstraint($msg))
    }
}

class PatternConstraintGenerator <: ConstraintGenerator {
    var msg: String = ""
    var regex: String = ""

    init() {
        super("Pattern")
    }

    protected func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["regex", "msg"], macroName: marcroName)
        this.regex = map.getString("regex") ?? ""
        this.msg = map.getString("msg") ?? ""
    }

    protected func toConstraint(): Tokens {
        quote(PatternConstraint($regex, $msg))
    }
}

class DateTimeRangeConstraintGenerator <: ConstraintGenerator {
    var msg: String = ""
    var before: String = "DateTime.now().addYears(1)"
    var after: String = "DateTime.now()"

    init() {
        super("DateTimeRange")
    }

    protected func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["before", "after", "msg"], macroName: marcroName)
        this.before = map.getString("before") ?? "DateTime.now().addYears(1)"
        this.after = map.getString("after") ?? "DateTime.now()"
        this.msg = map.getString("msg") ?? ""
    }

    protected func toConstraint(): Tokens {
        let beforeToken = try {
            Token(TokenKind.IDENTIFIER, this.before)
        } catch (ex: Exception) {
            Token(TokenKind.EXP, this.before)
        }
        let afterToken = try {
            Token(TokenKind.IDENTIFIER, this.after)
        } catch (ex: Exception) {
            Token(TokenKind.EXP, this.after)
        }
        quote(DateTimeRangeConstraint({=>$beforeToken}(), {=>$afterToken}(), $msg))
    }
}

class ChMobilePhoneConstraintGenerator <: MsgBaseConstraintGenerator {
    init() {
        super("ChMobilePhone")
    }
    protected func toConstraint(): Tokens {
        quote(ChMobilePhoneConstraint($msg))
    }
}

class EmailConstraintGenerator <: MsgBaseConstraintGenerator {
    init() {
        super("Email")
    }
    protected func toConstraint(): Tokens {
        quote(EmailConstraint($msg))
    }
}

class IPV4ConstraintGenerator <: MsgBaseConstraintGenerator {
    init() {
        super("IPV4")
    }
    protected func toConstraint(): Tokens {
        quote(IPV4Constraint($msg))
    }
}

class EnumStrConstraintGenerator <: ConstraintGenerator {
    var msg: String = ""
    var values: ArrayList<ToString> = ArrayList()

    init() {
        super("EnumStr")
    }

    protected func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["values", "msg"], macroName: marcroName)
        this.values = map.getList("values") ?? ArrayList<ToString>()
        this.msg = map.getString("msg") ?? ""
    }

    protected func toConstraint(): Tokens {
        let v = converterList<ToString, String>(values)
        let tokens = v |> map {it => quote($it)} |> collectArrayList
        let vs = Token(TokenKind.LSQUARE) + joinTokens(tokens, Token(TokenKind.COMMA)) + Token(TokenKind.RSQUARE)
        quote(EnumStrConstraint($vs, $msg))
    }
}

class EnumIntConstraintGenerator <: ConstraintGenerator {
    var msg: String = ""
    var values: ArrayList<ToString> = ArrayList()

    init() {
        super("EnumInt")
    }

    protected func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["values", "msg"], macroName: marcroName)
        this.values = map.getList("values") ?? ArrayList<ToString>()
        this.msg = map.getString("msg") ?? ""
    }

    protected func toConstraint(): Tokens {
        let v = converterList<ToString, Int>(values)
        let tokens = v |> map {it => quote($it)} |> collectArrayList
        let vs = Token(TokenKind.LSQUARE) + joinTokens(tokens, Token(TokenKind.COMMA)) + Token(TokenKind.RSQUARE)
        quote(EnumIntConstraint($vs, $msg))
    }
}

func createConstraintGenerator(catgory: ConstraintCatgory): ConstraintGenerator {
    match (catgory) {
        case CCSize => SizeConstraintGenerator()
        case CCLength => LengthConstraintGenerator()
        case CCNotEmpty => NotEmptyConstraintGenerator()
        case CCNotBlank => NotBlankConstraintGenerator()
        case CCNumberRange => RangeConstraintGenerator()
        case CCPattern => PatternConstraintGenerator()
        case CCDatetimeRange => DateTimeRangeConstraintGenerator()
        case CCChMobilePhone => ChMobilePhoneConstraintGenerator()
        case CCEmail => EmailConstraintGenerator()
        case CCIPV4 => IPV4ConstraintGenerator()
        case CCEnumStr => EnumStrConstraintGenerator()
        case CCEnumInt => EnumIntConstraintGenerator()
    }
}

func parseConstraint(catgory: ConstraintCatgory, input: Tokens): Unit {
    parseConstraint(catgory, None, input)
}

func parseConstraint(catgory: ConstraintCatgory, attr: ?Tokens, input: Tokens): Unit {
    let constraint: ConstraintGenerator = createConstraintGenerator(catgory)
    if (let Some(a) <- attr) {
        constraint.parseAttr(a)
    }

    let errMsg = "@${constraint.marcroName} macro only using for the func paramter or the var field of struct or class"
    try {
        let varDecl: Decl = parseDecl(input)
        match (varDecl) {
            case vd: VarDecl => FieldInfoCache.addCache(vd.identifier, false, constraint.toConstraint())
            case _ => diagReport(DiagReportLevel.ERROR, input, errMsg, "")
        }
    } catch (_: Exception) {
        try {
            let funcParam = FuncParam(input)
            FieldInfoCache.addCache(funcParam.identifier, true, constraint.toConstraint())
        } catch (ex: Exception) {
            ex.printStackTrace()
            diagReport(DiagReportLevel.ERROR, input, errMsg, "")
        }
    }
}
