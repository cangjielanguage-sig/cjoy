/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.ast.*
import std.collection.{ArrayList, HashMap, HashSet, map, collectArray}
import std.convert.Parsable

protected interface TokenVisitor<T> {
    func onArrayBegin(): T
    func onArrayItem(value: T): Unit
    func onArrayEnd(): Unit

    func onObjBegin(): T
    func onObjItem(key: String, value: T): Unit
    func onObjEnd(): Unit

    func onVaule(value: Token): T
}

protected class TokenStrValueVisitor <: TokenVisitor<ToString> {
    var list: ArrayList<ToString> = ArrayList()
    var map: HashMap<String, ToString> = HashMap()
    public func onArrayBegin(): ToString {
        list = ArrayList()
        list
    }

    public func onArrayItem(value: ToString): Unit {
        list.add(value)
    }

    public func onArrayEnd(): Unit {
    }

    public func onObjBegin(): ToString {
        map = HashMap<String, ToString>()
        map
    }

    public func onObjItem(key: String, value: ToString): Unit {
        map.add(key, value)
    }

    public func onObjEnd(): Unit {
    }

    public func onVaule(value: Token): ToString {
        match (value.kind) {
            case IDENTIFIER | STRING_LITERAL | MULTILINE_STRING | MULTILINE_RAW_STRING => value.value
            case INTEGER_LITERAL => Int64.parse(value.value)
            case FLOAT_LITERAL => Float64.parse(value.value)
            case BOOL_LITERAL => Bool.parse(value.value)
            case _ => ""
        }
    }
}

protected open class TokenParser<T> {
    let _tokens: Tokens
    let _visitor: TokenVisitor<T>

    protected var _pos: Int64
    protected var _currToken: Token
    protected var _depth = 0

    public init(visitor: TokenVisitor<T>, tokens: Tokens, pos!: Int64 = 0) {
        _visitor = visitor
        _tokens = tokens
        _pos = pos
        _currToken = if (tokens.size == 0) {
            Token(TokenKind.ILLEGAL)
        } else {
            tokens[pos]
        }
    }

    func assert(kind: TokenKind) {
        if (_currToken.kind != kind) {
            _currToken.dump()
            throw Exception("fail to assert the current token kind. expecting: ${kind}")
        }
    }

    func next(skipNL!: Bool = true) {
        do {
            _pos += 1
        } while (_pos < _tokens.size && (skipNL && _tokens[_pos].kind == TokenKind.NL))

        _currToken = if (_pos < _tokens.size) {
            _tokens[_pos]
        } else {
            Token(TokenKind.ILLEGAL)
        }
    }

    func skip(kind: TokenKind) {
        assert(kind)
        next()
    }

    func skipNLs() {
        while (_currToken.kind == TokenKind.IDENTIFIER) {
            _pos += 1
            _currToken = if (_pos < _tokens.size) {
                _tokens[_pos]
            } else {
                Token(TokenKind.ILLEGAL)
            }
        }
    }

    public func parse(parseValue!: Bool = false): T {
        skipNLs()
        if (!parseValue && _currToken.kind == TokenKind.IDENTIFIER) {
            return parseAttr()
        } else if (_currToken.kind == TokenKind.LSQUARE) {
            return parseArray()
        } else if (_currToken.kind == TokenKind.LCURL) {
            return parseMap()
        } else if (parseValue && isValueToken()) {
            return _visitor.onVaule(_currToken)
        }
        _currToken.dump()
        throw Exception("unknown token ${_currToken.value} in parsing")
    }

    func isValueToken() {
        match (_currToken.kind) {
            case TokenKind.IDENTIFIER | TokenKind.INTEGER_LITERAL | TokenKind.FLOAT_LITERAL | TokenKind.STRING_LITERAL
                | TokenKind.MULTILINE_STRING | TokenKind.MULTILINE_RAW_STRING | TokenKind.BOOL_LITERAL => true
            case _ => false
        }
    }

    func checkMidToken() {
        if (_currToken.kind == TokenKind.ASSIGN || _currToken.kind == TokenKind.COLON) {
            next() // '=' or ':'
        } else {
            _currToken.dump()
            throw Exception("fail to parse attributes. expecting '=' or ':'.")
        }
    }

    func parseAttr(): T {
        let map = _visitor.onObjBegin()
        while (_pos < _tokens.size) {
            match (_currToken.kind) {
                case TokenKind.IDENTIFIER =>
                    let key = _currToken.value
                    next()

                    checkMidToken()

                    let value = parse(parseValue: true)
                    _visitor.onObjItem(key, value)
                    next()
                case TokenKind.COMMA => next() // ','
                case TokenKind.ILLEGAL => break
                case _ =>
                    _currToken.dump()
                    throw Exception("unknown token ${_currToken.value} in parsing")
            }
        }
        _visitor.onObjEnd()
        map
    }

    func parseArray(): T {
        skip(TokenKind.LSQUARE)
        _depth += 1

        let arr = _visitor.onArrayBegin()
        while (_pos < _tokens.size) {
            match (_currToken.kind) {
                case TokenKind.COMMA => next() // ','
                case TokenKind.RSQUARE => break
                case _ =>
                    let value = parse(parseValue: true)
                    _visitor.onArrayItem(value)
                    next()
            }
        }
        _depth -= 1
        if (_depth != 0) {
            _currToken.dump()
            throw Exception("unknown token ${_currToken.value} in parsing")
        }
        skip(TokenKind.RSQUARE)
        _visitor.onArrayEnd()
        arr
    }

    func parseMap(): T {
        skip(TokenKind.LCURL)
        _depth += 1

        let map = _visitor.onObjBegin()
        while (_pos < _tokens.size) {
            match (_currToken.kind) {
                case TokenKind.IDENTIFIER =>
                    let key = _currToken.value
                    next()
                    
                    checkMidToken()

                    let value = parse(parseValue: true)
                    _visitor.onObjItem(key, value)
                    next()
                case TokenKind.COMMA => next() // ','
                case TokenKind.RCURL => break
                case _ =>
                    _currToken.dump()
                    throw Exception("unknown token ${_currToken.value} in parsing")
            }
        }

        _depth -= 1
        if (_depth != 0) {
            _currToken.dump()
            throw Exception("unknown token ${_currToken.value} in parsing Attr")
        }
        skip(TokenKind.RCURL)
        _visitor.onArrayEnd()
        map
    }
}
