/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils.ast

import std.ast.*
import std.collection.{ArrayList, HashMap}
import std.convert.Parsable
import cjoy.utils.{ListToString, MapToString}

/**
 * visitor pattern interface for parsing tokens into structured values
 *
 * @param T: the type of value to return from each visitor method
 */
protected interface TokenVisitor<T> {
    /**
     * called when array parsing begins
     *
     * @return: container for array values
     */
    func onArrayBegin(): T

    /**
     * called for each array item
     *
     * @param list: the array container
     * @param value: the item value
     */
    func onArrayItem(list: T, value: T): Unit

    /**
     * called when array parsing ends
     *
     * @param list: the array container
     */
    func onArrayEnd(list: T): Unit

    /**
     * called when object parsing begins
     *
     * @return: container for object key-value pairs
     */
    func onObjBegin(): T

    /**
     * called for each object key-value pair
     *
     * @param map: the object container
     * @param key: the key
     * @param value: the value
     */
    func onObjItem(map: T, key: String, value: T): Unit

    /**
     * called when object parsing ends
     *
     * @param map: the object container
     */
    func onObjEnd(map: T): Unit

    /**
     * called for each atomic value
     *
     * @param value: the value token
     * @return: the converted value
     */
    func onValue(value: Token): T
}

/**
 * default visitor implementation that converts tokens to ToString values
 */
protected class TokenStrValueVisitor <: TokenVisitor<ToString> {
    public func onArrayBegin(): ToString {
        ListToString()
    }

    public func onArrayItem(list: ToString, value: ToString): Unit {
        let l: ListToString = (list as ListToString).getOrThrow()
        l.add(value)
    }

    public func onArrayEnd(_: ToString): Unit {
    }

    public func onObjBegin(): ToString {
        MapToString()
    }

    public func onObjItem(map: ToString, key: String, value: ToString): Unit {
        let m: MapToString = (map as MapToString).getOrThrow()
        if (m.contains(key)) {
            throw Exception("duplicated key in map, key: ${key}")
        }
        m.add(key, value)
    }

    public func onObjEnd(_: ToString): Unit {
    }

    public func onValue(value: Token): ToString {
        match (value.kind) {
            case IDENTIFIER | STRING_LITERAL | MULTILINE_STRING | MULTILINE_RAW_STRING => value.value
            case INTEGER_LITERAL => Int64.parse(value.value)
            case FLOAT_LITERAL => Float64.parse(value.value)
            case BOOL_LITERAL => Bool.parse(value.value)
            case _ => ""
        }
    }
}

/**
 * generic token parser that uses visitor pattern to build values
 *
 * @param T: result type from parsing
 */
protected open class TokenParser<T> {
    let _tokens: Tokens
    let _visitor: TokenVisitor<T>

    protected var _pos: Int64
    protected var _currToken: Token
    protected var _depth = 0

    /**
     * creates a new token parser
     *
     * @param visitor: the visitor for building parsed values
     * @param tokens: tokens to parse
     * @param pos: starting position in tokens
     */
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

    /**
     * asserts current token is of specified kind
     *
     * @param kind: expected token kind
     * @throws Exception if current token kind doesn't match
     */
    func assertToken(kind: TokenKind) {
        if (_currToken.kind != kind) {
            _currToken.dump()
            throw Exception(
                "fail to assertToken the current token kind. expecting: ${kind}, real: ${_currToken.kind}, pos: ${_pos}"
            )
        }
    }

    /**
     * moves to next token, optionally skipping newlines
     *
     * @param skipNL: if true, skip newline tokens
     */
    func next(skipNL!: Bool = true) {
        do {
            _pos += 1
        } while (_pos < _tokens.size && skipNL && _tokens[_pos].kind == TokenKind.NL)

        _currToken = if (_pos < _tokens.size) {
            _tokens[_pos]
        } else {
            Token(TokenKind.ILLEGAL)
        }
    }

    /**
     * asserts current token kind and moves to next
     *
     * @param kind: token kind to skip
     */
    func skip(kind: TokenKind) {
        assertToken(kind)
        next()
    }

    /**
     * skips all newline tokens
     */
    func skipNLs() {
        while (_pos < _tokens.size && _currToken.kind == TokenKind.NL) {
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
            return _visitor.onValue(_currToken)
        }
        _currToken.dump()
        throw Exception("unknown token ${_currToken.value} in parsing")
    }

    /**
     * checks if current token is a value token
     *
     * @return: true if current token is a value (identifier, literal, etc.)
     */
    func isValueToken() {
        match (_currToken.kind) {
            case TokenKind.IDENTIFIER | TokenKind.INTEGER_LITERAL | TokenKind.FLOAT_LITERAL | TokenKind.STRING_LITERAL
                | TokenKind.MULTILINE_STRING | TokenKind.MULTILINE_RAW_STRING | TokenKind.BOOL_LITERAL | TokenKind.MUL => true
            case _ => false
        }
    }

    /**
     * checks and skips assignment or colon token
     *
     * @throws Exception if current token is not ASSIGN or COLON
     */
    func checkMidToken() {
        if (_currToken.kind == TokenKind.ASSIGN || _currToken.kind == TokenKind.COLON) {
            next() // '=' or ':'
        } else {
            _currToken.dump()
            throw Exception("fail to parse, expecting: '=' or ':', real: ${_currToken.value}")
        }
    }

    /**
     * parses key-value attributes (name = value pairs)
     *
     * @return: parsed map of attributes
     */
    func parseAttr(): T {
        let map = _visitor.onObjBegin()
        while (_pos < _tokens.size) {
            match (_currToken.kind) {
                case TokenKind.IDENTIFIER =>
                    let key = _currToken.value
                    next()

                    checkMidToken()

                    let value = parse(parseValue: true)
                    _visitor.onObjItem(map, key, value)
                    next()
                case TokenKind.COMMA => next() // ','
                case TokenKind.ILLEGAL => break
                case _ =>
                    _currToken.dump()
                    throw Exception("unknown token ${_currToken.value} in parsing")
            }
        }
        _visitor.onObjEnd(map)
        map
    }

    /**
     * parses array tokens [item1, item2, ...]
     *
     * @return: parsed array value
     */
    func parseArray(): T {
        skip(TokenKind.LSQUARE)
        _depth += 1
        let depth = _depth

        let arr = _visitor.onArrayBegin()
        while (_pos < _tokens.size) {
            match (_currToken.kind) {
                case TokenKind.COMMA => next() // ','
                case TokenKind.RSQUARE =>
                    if (_depth == depth) {
                        break
                    }
                case _ =>
                    let value = parse(parseValue: true)
                    _visitor.onArrayItem(arr, value)
                    next()
            }
        }
        _depth -= 1
        assertToken(TokenKind.RSQUARE)
        _visitor.onArrayEnd(arr)
        arr
    }

    /**
     * parses map tokens {key: value, ...}
     *
     * @return: parsed map value
     */
    func parseMap(): T {
        skip(TokenKind.LCURL)
        _depth += 1
        let depth = _depth

        let map = _visitor.onObjBegin()
        while (_pos < _tokens.size) {
            match (_currToken.kind) {
                case TokenKind.IDENTIFIER | TokenKind.STRING_LITERAL =>
                    let key = _currToken.value
                    next()

                    checkMidToken()

                    let value = parse(parseValue: true)
                    _visitor.onObjItem(map, key, value)
                    next()
                case TokenKind.COMMA => next() // ','
                case TokenKind.RCURL =>
                    if (_depth == depth) {
                        break
                    }
                case _ =>
                    _currToken.dump()
                    throw Exception("unknown token ${_currToken.value} in parsing")
            }
        }

        _depth -= 1
        assertToken(TokenKind.RCURL)
        _visitor.onObjEnd(map)
        map
    }
}
