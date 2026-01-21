/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.ioc.macros

import std.ast.*
import std.collection.{ArrayList, map, collectArray}
import cjoy.utils.ast.{ClassGenentor, parserAttrs, joinTokens, TypeNodeInfo}
import cjoy.utils.{converterList, MapToString, MapListGetFunc}

class ControllerClassInfo <: ComponentClassInfo {
    private let _path: String

    init(attr: ?Tokens, classId: Token, initFunc: ?FuncDecl, fn: (attr: Tokens) -> MapToString) {
        super(attr, classId, initFunc, fn)
        if (attr.isSome()) {
            _path = _attrMap.getString("path") ?? ""
        } else {
            _path = ""
        }
    }

    func getHanldersTokens(): (Tokens, Tokens) {
        let methods = ["Get", "Post", "Put", "Patch", "Patch", "Delete", "Handler"]
        var handlerFuns = Tokens()
        var register = Tokens()
        for (m in methods) {
            let msgs = getChildMessages(m)
            for (msg in msgs) {
                handlerFuns += msg.getTokens("handler.func")
                let name = msg.getString("handler.name")
                let path = getPath(msg.getString("handler.path"))
                let methods = getMethods(msg.getString("handler.methods"))
                let bt = Token(TokenKind.IDENTIFIER, _beanType)
                let hn = Token(TokenKind.IDENTIFIER, name)
                let pfName = m + "." + _beanName + "." + name
                let err = "not found bean by name `${_beanName}` for type `${_beanType}`"
                register += quote(
                        let _: Unit = BeanFactoryManager.registerPostFunc($pfName) {=>
                            let bean = BeanFactoryManager.getApplicationContext().getBean<$bt>($_beanName).getOrThrow({=>IocException($err)})
                            JoyHandlers.addHandler($(path), $methods, bean.$hn)
                        }
                    )
            }
        }
        (handlerFuns, register)
    }

    func getPath(path: String): String {
        _path.trimEnd("/") + path
    }

    func getMethods(methods: String): Array<String> {
        let array = methods.split(",", removeEmpty: true)
        array |> map {a: String => a.toAsciiUpper().trimAscii()} |> collectArray
    }
}

func parseController(attr: ?Tokens, input: Tokens): Tokens {
    let (decl, pos) = parseDeclFragment(input)
    let classGen = ClassGenentor("Component", decl)
    let ident = decl.identifier
    let classInfo = ControllerClassInfo(attr, ident, getInitFunc(classGen)) {
        attr: Tokens => parserAttrs(attr, validKeys: ["name", "scope", "extends", "path"], macroName: "Controller")
    }
    let supperTokens = quote(BeanLifecycle)
    let (handlerFuns, register) = classInfo.getHanldersTokens()
    let otherTokens = register + Token(TokenKind.NL) + classInfo.getSubMacroTokens()
    let tokens = classGen.genTokens(supperTokens, handlerFuns, createCtor: false)

    tokens + Token(TokenKind.NL) + input[pos..] + Token(TokenKind.NL) + classInfo.getFactoryTokens() + otherTokens
}
