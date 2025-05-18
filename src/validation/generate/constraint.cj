/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.validation.generate

import std.collection.{ArrayList, filter, first}
import cjoy.validation.api.*
import cjoy.utils.{parseKVAttr, joinTokens}
import std.convert.Parsable
import std.time.DateTime
import std.ast.*

public enum ConstraintCatgory {
    | C_SIZE
    | C_LENGTH
    | C_NOT_EMTPY
    | C_NOT_BLANK
    | C_NUBMER_RANGE
    | C_PATTERN
    | C_DATETIME_RANGE
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

    func genValidateTokens(): Tokens {
        if (constraints.isEmpty() && !nestedValid) {
            return Tokens()
        }

        var tokens = Tokens()
        if (!constraints.isEmpty()) {
            tokens += joinTokens(constraints, Token(TokenKind.COMMA))
        }
        if (inFunc) {
            if (constraints.isEmpty()) {
                quote($(id()).validate("", $nestedValid) 
                )
            } else {
                quote($(id()).validate("", $nestedValid, $tokens) 
                )
            }
        } else {
            let fieldName = Token(TokenKind.IDENTIFIER, "\"\${field}." + name() + "\"")
            if (constraints.isEmpty()) {
                if (name() == "Any") {
                    quote(match($(id())) {
                            case x: JoyValidatable => x.validate({=> if(field.isEmpty()) {$(name())} else { $fieldName } }(), $nestedValid) 
                            case _ => ()
                        }
                    )
                } else {
                    quote($(id()).validate({=> if(field.isEmpty()) {$(name())} else { $fieldName } }(), $nestedValid) 
                    )
                }
            } else {
                if (name() == "Any") {
                    quote(match($(id())) {
                            case x: JoyValidatable => x.$(id()).validate({=> if(field.isEmpty()) {$(name())} else { $fieldName } }(), $nestedValid, $tokens) 
                            case _ => ()
                        }
                    )
                } else {
                    quote($(id()).validate({=> if(field.isEmpty()) {$(name())} else { $fieldName } }(), $nestedValid, $tokens) 
                    )
                }
            }
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

    static func addCache(identifier: Token, inFunc: Bool, JoyConstraint: Tokens): Unit {
        let name = identifier.value
        for (fd in PARAMS) {
            if (fd.name() == name) {
                fd.constraints.add(JoyConstraint)
                return
            }
        }

        let info: FieldInfo = FieldInfo(identifier, inFunc)
        info.constraints.add(JoyConstraint)
        addCache(info)
    }

    static func setNestedValid(identifier: Token, inFunc: Bool): Unit {
        let name = identifier.value
        for (fd in PARAMS) {
            if (fd.name() == name) {
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
        parseKVAttr(attr, marcroName,
            {
                ident: Token, value: Token => match (ident.value) {
                    case "min" => this.min = value.value
                    case "max" => this.max = value.value
                    case "msg" => this.msg = value.value
                    case _ => throw Exception("${marcroName} attriable should be min, max, msg")
                }
            })
    }
}

abstract class MsgBaseConstraintGenerator <: ConstraintGenerator {
    var msg: String = ""

    init(marcroName: String) {
        super(marcroName)
    }

    protected func parseAttr(attr: Tokens): Unit {
        parseKVAttr(attr, marcroName,
            {
                ident: Token, value: Token => match (ident.value) {
                    case "msg" => this.msg = value.value
                    case _ => throw Exception("${marcroName} attriable should be msg")
                }
            })
    }
}

class SizeConstraintGenerator <: MinMaxBaseConstraintGenerator {
    init() {
        super("Size")
    }

    protected func toConstraint(): Tokens {
        quote(SizeConstraint(Int.tryParse($(min)).getOrDefault({=> 0}), Int.tryParse($(max)).getOrDefault({=> 100}), $msg))
    }
}

class LengthConstraintGenerator <: MinMaxBaseConstraintGenerator {
    init() {
        super("Length")
    }

    protected func toConstraint(): Tokens {
        quote(LengthConstraint(Int.tryParse($(min)).getOrDefault({=> 0}), Int.tryParse($(max)).getOrDefault({=> 100}), $msg))
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
        parseKVAttr(attr, marcroName,
            {
                ident: Token, value: Token => match (ident.value) {
                    case "msg" => this.msg = value.value
                    case "regex" => this.regex = value.value
                    case _ => throw Exception("${marcroName} attriable should be regex, msg")
                }
            })
    }

    protected func toConstraint(): Tokens {
        quote(PattenConstraint($regex, $msg))
    }
}

class DateTimeRangeConstraintGenerator <: ConstraintGenerator {
    var msg: String = ""
    var before: String = "DateTime.now().addYears(1)"
    var after: String = "DateTime.now()"

    init() {
        super("Pattern")
    }

    protected func parseAttr(attr: Tokens): Unit {
        parseKVAttr(attr, marcroName,
            {
                ident: Token, value: Token => match (ident.value) {
                    case "msg" => this.msg = value.value
                    case "before" => this.before = value.value
                    case "after" => this.after = value.value
                    case _ => throw Exception("${marcroName} attriable should be before, after, msg")
                }
            })
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

func createConstraintGenerator(catgory: ConstraintCatgory): ConstraintGenerator {
    match (catgory) {
        case C_SIZE => SizeConstraintGenerator()
        case C_LENGTH => LengthConstraintGenerator()
        case C_NOT_EMTPY => NotEmptyConstraintGenerator()
        case C_NOT_BLANK => NotBlankConstraintGenerator()
        case C_NUBMER_RANGE => RangeConstraintGenerator()
        case C_PATTERN => PatternConstraintGenerator()
        case C_DATETIME_RANGE => DateTimeRangeConstraintGenerator()
    }
}

public func parseConstraint(catgory: ConstraintCatgory, input: Tokens): Unit {
    parseConstraint(catgory, None, input)
}

public func parseConstraint(catgory: ConstraintCatgory, attr: ?Tokens, input: Tokens): Unit {
    let JoyConstraint: ConstraintGenerator = createConstraintGenerator(catgory)
    if (let Some(a) <- attr) {
        JoyConstraint.parseAttr(a)
    }

    try {
        let varDecl: Decl = parseDecl(input)
        match (varDecl) {
            case vd: VarDecl => FieldInfoCache.addCache(vd.identifier, false, JoyConstraint.toConstraint())
            case _ =>
                diagReport(DiagReportLevel.ERROR, input,
                    "${JoyConstraint.marcroName} macro only using for the var field of struct or class", "")
                throw Exception("${JoyConstraint.marcroName} macro only using for the var field of struct or class")
        }
    } catch (_: Exception) {
        try {
            let funcParam = FuncParam(input)
            FieldInfoCache.addCache(funcParam.identifier, true, JoyConstraint.toConstraint())
        } catch (_: Exception) {
            diagReport(DiagReportLevel.ERROR, input, "${JoyConstraint.marcroName} macro only using for the func paramter",
                "")
            throw Exception("${JoyConstraint.marcroName} macro only using for the func paramter")
        }
    }
}
