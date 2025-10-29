/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.ioc.macros

import std.ast.*
import std.collection.ArrayList
import cjoy.utils.ast.{ClassGenentor, parserAttrs, joinTokens, TypeNodeInfo}
import cjoy.utils.{converterList, MapToString, MapListGetFunc, randStr}

open class ComponentClassInfo {
    let _classId: Token
    let _beanType: String
    let _beanName: String
    let _beanScope: String
    let _extends: ArrayList<String>
    let _ctorFuncDecl: ?FuncDecl
    var _attrMap: MapToString = MapToString()

    init(attr: ?Tokens, classId: Token, initFunc: ?FuncDecl, fn: (attr: Tokens) -> MapToString) {
        _classId = classId
        _beanType = classId.value
        _ctorFuncDecl = initFunc
        if (attr.isSome()) {
            _attrMap = fn(attr.getOrThrow())
            _beanName = _attrMap.getString("name") ?? toBeanName(_beanType)
            _beanScope = (_attrMap.getString("scope") ?? "Singleton").toAsciiLower()
            _extends = converterList(_attrMap.getList("extends") ?? ArrayList<ToString>())
            checkBeanSceop(attr.getOrThrow(), _beanScope)
        } else {
            _beanName = toBeanName(_beanType)
            _beanScope = "singleton"
            _extends = ArrayList()
        }
    }

    // 获取@Autowired[name=""]的name值
    private func getBeanNameOnAutowired(msgs: Collection<MacroMessage>, name: String): String {
        for (msg in msgs) {
            let res = msg.getString(name)
            if (res != "") {
                return res
            }
        }
        ""
    }

    private func getBeanToken(): (Tokens, Tokens) {
        let msgs = getChildMessages("Autowired")
        let supportTypes = "interface or bean type"
        if (let Some(ctor) <- _ctorFuncDecl) {
            let tokens = ArrayList<Tokens>()
            let depends = ArrayList<Tokens>()
            for (fp in ctor.funcParams) {
                let pid = fp.identifier // 参数类型
                let typeNode = TypeNodeInfo(supportTypes)
                typeNode.parse(fp.toTokens(), fp.paramType)
                if (typeNode.isPrimitive) {
                    diagReport(DiagReportLevel.ERROR, fp.toTokens(), "the Autowired type can not is primitive type",
                        "the type should be ${supportTypes}")
                    return (Tokens(), Tokens())
                }
                let name = getBeanNameOnAutowired(msgs, pid.value + ".name")
                let t = if (name != "") { // @Autowired[name=""]
                    depends.add(quote($(typeNode.vtype.value)))
                    let msg = "not found bean by name `${name}` for type `${typeNode.vtype.value}`"
                    quote(ctx.getBean<$(typeNode.vtype)>($name).getOrThrow({=>IocException($msg)}))
                } else if (typeNode.vtype.value == "Collection") {
                    depends.add(quote($(typeNode.genericType.value)))
                    quote(ctx.getBeansByTypeName<$(typeNode.genericType)>($(typeNode.genericType.value)))
                } else if (typeNode.vtype.value == "Array") {
                    depends.add(quote($(typeNode.genericType.value)))
                    quote(ctx.getBeansByTypeName<$(typeNode.genericType)>($(typeNode.genericType.value)).toArray())
                } else if (typeNode.vtype.value == "ArrayList") {
                    depends.add(quote($(typeNode.genericType.value)))
                    quote(ArrayList(ctx.getBeansByTypeName<$(typeNode.genericType)>($(typeNode.genericType.value))))
                } else if (typeNode.vtype.value == "Option") {
                    depends.add(quote($(typeNode.genericType.value)))
                    quote(ctx.getBeanByTypeName<$(typeNode.genericType)>($(typeNode.genericType.value)))
                } else {
                    let msg = "not found bean for type `${typeNode.vtype.value}`"
                    depends.add(quote($(typeNode.vtype.value)))
                    quote(ctx.getBeanByTypeName<$(typeNode.vtype)>($(typeNode.vtype.value)).getOrThrow({=>IocException($msg)}))
                }
                tokens.add(t)
            }
            let params: Tokens = joinTokens(tokens, Token(TokenKind.COMMA))
            let dps = joinTokens(depends, Token(TokenKind.COMMA))
            (quote(let bean: BeanLifecycle = $_classId($params)
            ), quote([$dps]))
        } else { // 无构造函数
            (quote(let bean: BeanLifecycle = $_classId()
            ), quote([]))
        }
    }

    func getFactoryTokens(): Tokens {
        let factoryName = Token(TokenKind.IDENTIFIER, _classId.value.toAsciiTitle() + "BeanFactory")
        let (bean, deps) = getBeanToken()
        let inferfaces = _extends.toArray()
        quote(
            public class $factoryName <: BeanFactory {
                public static let INSTANE: BeanFactory = $(factoryName)()
                private init() {
                    BeanFactoryManager.register($_beanType, $deps, this)
                    BeanFactoryManager.registerTypes($_beanType, $inferfaces)
                }
                public prop beanType: String {
                    get() { $_beanType }
                }
                public prop beanScope: BeanScope {
                    get() { $_beanScope }
                }
                public func create(ctx: ApplicationContext): (String, BeanLifecycle) {
                    let beanName = $_beanName
                    $bean
                    (beanName, bean)
                }
            }
        )
    }

    func getSchuedleTokens(): Tokens {
        let msgs = getChildMessages("Scheduled")
        var register = Tokens()
        for (msg in msgs) {
            let name = "schedule." + _beanName + "." + msg.getString("schedule.name")
            let cron = msg.getString("schedule.cron")
            let funcName = msg.getTokens("schedule.funcName")
            let bt = Token(TokenKind.IDENTIFIER, _beanType)
            let err = "not found bean by name `${_beanName}` for type `${_beanType}`"
            register += quote(
                let _: Unit = BeanFactoryManager.registerPostFunc($name) {=>
                    let bean = BeanFactoryManager.getApplicationContext().getBean<$bt>($_beanName).getOrThrow({=>IocException($err)})
                    Crontab.INSTANCE.addJob($name, $cron, bean.$funcName)
                }
            )
        }
        register
    }

    func getEventBusTokens(): Tokens {
        let msgs = getChildMessages("SubscribeEvent")
        var register = Tokens()
        for (msg in msgs) {
            let name = "eventbus." + _beanName + "." + msg.getString("eventbus.name")
            let pattern = msg.getString("eventbus.pattern")
            let priority = msg.getInt64("eventbus.priority")
            let funcName = msg.getTokens("eventbus.funcName")
            let bt = Token(TokenKind.IDENTIFIER, _beanType)
            let err = "not found bean by name `${_beanName}` for type `${_beanType}`"
            register += quote(
                let _: Unit = BeanFactoryManager.registerPostFunc($name) {=>
                    let bean = BeanFactoryManager.getApplicationContext().getBean<$bt>($_beanName).getOrThrow({=>IocException($err)})
                    LocalEventBus.INSTANCE.onEvent($pattern, $name, bean.$funcName, $priority)
                }
            )
        }
        register
    }

    func getSubMacroTokens(): Tokens {
        getSchuedleTokens()
        getEventBusTokens()
    }
}

/**
 * @throws Exception
 */
func checkBeanSceop(attr: Tokens, beanScope: String): Unit {
    if (beanScope != "singleton" && beanScope != "prototype") {
        diagReport(DiagReportLevel.ERROR, attr,
            "scope in @Component value `${beanScope}` must be singleton or prototype", "")
    }
}

func toBeanName(str: String): String {
    let arr = str.toRuneArray()
    arr[0] = arr[0].toAsciiLowerCase()
    String(arr)
}

/**
 * @throws Exception
 */
func getInitFunc(classGen: ClassGenentor) {
    let ctors = classGen.constructors
    var initFunc: ?FuncDecl = None
    if (ctors.size == 0) {
        initFunc = None
    } else if (ctors.size == 1) {
        initFunc = ctors[0]
    } else {
        throw Exception("only allowed exist zero or one init func")
    }
    initFunc
}

func parseComponent(attr: ?Tokens, input: Tokens): Tokens {
    let (decl, pos) = parseDeclFragment(input)
    let classGen = ClassGenentor("Component", decl)
    let ident = decl.identifier
    let classInfo = ComponentClassInfo(attr, ident, getInitFunc(classGen)) {
        attr: Tokens => parserAttrs(attr, validKeys: ["name", "scope", "extends"], macroName: "Component")
    }
    let supperTokens = quote(BeanLifecycle)
    let tokens = classGen.genTokens(supperTokens, Tokens(), createCtor: false)

    tokens + Token(TokenKind.NL) + input[pos..] + Token(TokenKind.NL) + classInfo.getFactoryTokens() + Token(
        TokenKind.NL) + classInfo.getSubMacroTokens()
}
