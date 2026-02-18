/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.ioc

import std.collection.ArrayList
import std.collection.concurrent.ConcurrentHashMap
import std.sync.AtomicBool
import std.env.atExit
import cjoy.context.ServiceContainer
import cjoy.log.macros.*

/**
 * IoC 容器的 Bean 工厂管理器。
 *
 * 用于管理 Bean 注册、依赖解析和生命周期管理的中央工厂。
 * 自动将自己注册为服务，并确保在应用退出时进行清理。
 */
public class BeanFactoryManager {
    private static let CONTEXT: DefaultApplicationContext = DefaultApplicationContext()
    private static let POST_FUNCS: ArrayList<() -> Unit> = ArrayList()

    static let EXECUTED: AtomicBool = AtomicBool(false)

    /**
     * 获取应用上下文。
     *
     * @return 应用上下文实例
     */
    public static func getApplicationContext(): ApplicationContext {
        CONTEXT
    }

    /**
     * 注册带有依赖的 Bean 工厂。
     *
     * @param beanType Bean 类型名称
     * @param depends 此 Bean 依赖的 Bean 类型名称数组
     * @param factory Bean 工厂
     */
    public static func register(beanType: String, depends: Array<String>, factory: BeanFactory): Unit {
        @JoyLogInfo("[IOC] 注册 Bean 信息, beanType=${beanType}, depends=${depends}")
        CONTEXT._factories.add(beanType, factory)
        CONTEXT._beanDependManager.addDepends(beanType, depends)
    }

    /**
     * 为接口注册 Bean 类型。
     *
     * @param beanType Bean 类型名称
     * @param interfaces 此 Bean 实现的接口类型名称数组
     */
    public static func registerTypes(beanType: String, interfaces: Array<String>): Unit {
        @JoyLogInfo("[IOC] 注册 Bean 类型, beanType=${beanType}, interfaces=${interfaces}")
        CONTEXT._beanDependManager.addTypes(beanType, interfaces)
    }

    /**
     * 注册后初始化函数。
     *
     * @param name 函数名称
     * @param fn Bean 初始化后要执行的函数
     */
    public static func registerPostFunc(name: String, fn: () -> Unit): Unit {
        @JoyLogInfo("[IOC] 注册后初始化函数, name=${name}")
        POST_FUNCS.add(fn)
    }

    /**
     * 执行注册的后函数。
     *
     * 每个函数在 Bean 初始化期间仅被调用一次。
     */
    private static func executePostFuncs(): Unit {
        if (EXECUTED.compareAndSwap(false, true)) {
            @JoyLogInfo("[IOC] 执行注册的后初始化函数")
            for (fn in POST_FUNCS) {
                fn()
            }
        }
    }

    /**
     * 按依赖顺序初始化所有 Bean。
     *
     * 创建所有单例 Bean 并调用 afterInit 回调。
     * 同时执行注册的后函数。
     */
    public static func initAllBeans(): Unit {
        CONTEXT.createAllBeans()
        executePostFuncs()
    }

    /**
     * 按反向依赖顺序销毁所有 Bean。
     *
     * 对所有 Bean 调用 beforeDestroy 回调并清除上下文。
     */
    public static func destroyAllBeans(): Unit {
        CONTEXT.destroyAllBeans()
    }

    /**
     * 按类型获取 Bean 工厂。
     *
     * @param beanType Bean 类型名称
     * @return Bean 工厂，如果未找到则返回 None
     */
    public static func get(beanType: String): ?BeanFactory {
        CONTEXT._factories.get(beanType)
    }
}

// 将 IoC 上下文注册为全局服务
private let _: Unit = ServiceContainer.GLOBAL.addService("ioc", BeanFactoryManager.getApplicationContext())
// 在应用退出时注册清理处理程序
private let _: Unit = atExit {BeanFactoryManager.destroyAllBeans()}
