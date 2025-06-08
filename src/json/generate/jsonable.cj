/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.json.generate

import std.ast.*
import cjoy.utils.*

class JsonTokenVisitor <: TokenVisitor<Tokens> {
    public func onArrayBegin(): Tokens {
        let t = quote(ArrayList<JsonSerializable>)
        Tokens().append(t).append(Token(TokenKind.LPAREN)).append(Token(TokenKind.LSQUARE))
    }

    public func onArrayItem(list: Tokens, value: Tokens): Unit {
        if (list.size > 1 && list[list.size - 1].kind != TokenKind.LSQUARE) {
            list.append(Token(TokenKind.COMMA))
        }
        list.append(value)
    }

    public func onArrayEnd(list: Tokens): Unit {
        list.append(Token(TokenKind.RSQUARE)).append(Token(TokenKind.RPAREN))
    }

    public func onObjBegin(): Tokens {
        let t = quote(HashMap<String, JsonSerializable>)
        Tokens().append(t).append(Token(TokenKind.LPAREN)).append(Token(TokenKind.LSQUARE))
    }

    public func onObjItem(map: Tokens, key: String, value: Tokens): Unit {
        if (map.size > 1 && map[map.size - 1].kind != TokenKind.LSQUARE) {
            map.append(Token(TokenKind.COMMA))
        }
        map.append(Token(TokenKind.LPAREN))
        map.append(Token(TokenKind.STRING_LITERAL, key)).append(Token(TokenKind.COMMA)).append(value)
        map.append(Token(TokenKind.RPAREN))
    }

    public func onObjEnd(map: Tokens): Unit {
        map.append(Token(TokenKind.RSQUARE)).append(Token(TokenKind.RPAREN))
    }

    public func onVaule(value: Token): Tokens {
        Tokens().append(value)
    }
}

public func parseJsonable(input: Tokens): Tokens {
    let visitor = JsonTokenVisitor()
    let parser = TokenParser(visitor, input)
    let res = parser.parse()
    res
}
