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
 * Bean factory manager for IoC container.
 *
 * Central factory for managing bean registration, dependency resolution,
 * and lifecycle management. Automatically registers itself as a service
 * and ensures cleanup on application exit.
 */
public class BeanFactoryManager {
    private static let CONTEXT: DefaultApplicationContext = DefaultApplicationContext()
    private static let POST_FUNCS: ArrayList<() -> Unit> = ArrayList()
    
    static let EXECUTED: AtomicBool = AtomicBool(false)

    /**
     * Get application context.
     *
     * @return application context instance
     */
    public static func getApplicationContext(): ApplicationContext {
        CONTEXT
    }

    /**
     * Register bean factory with dependencies.
     *
     * @param beanType bean type name
     * @param depends array of bean type names this bean depends on
     * @param factory bean factory
     */
    public static func register(beanType: String, depends: Array<String>, factory: BeanFactory): Unit {
        @JoyLogInfo("[IOC] register bean info, beanType=${beanType}, depends=${depends}")
        CONTEXT._factories.add(beanType, factory)
        CONTEXT._beanDependManager.addDepends(beanType, depends)
    }

    /**
     * Register bean types for interfaces.
     *
     * @param beanType bean type name
     * @param interfaces array of interface type names this bean implements
     */
    public static func registerTypes(beanType: String, interfaces: Array<String>): Unit {
        @JoyLogInfo("[IOC] register bean types, beanType=${beanType}, interfaces=${interfaces}")
        CONTEXT._beanDependManager.addTypes(beanType, interfaces)
    }

    /**
     * Register post initialization function.
     *
     * @param name function name
     * @param fn function to execute after bean initialization
     */
    public static func registerPostFunc(name: String, fn: () -> Unit): Unit {
        @JoyLogInfo("[IOC] register post func, name=${name}")
        POST_FUNCS.add(fn)
    }

    /**
     * Execute registered post functions.
     *
     * Each function is called exactly once during bean initialization.
     */
    private static func executePostFuncs(): Unit {
        if (EXECUTED.compareAndSwap(false, true)) {
            @JoyLogInfo("[IOC] execute registered post func")
            for (fn in POST_FUNCS) {
                fn()
            }
        }
    }

    /**
     * Initialize all beans in dependency order.
     *
     * Creates all singleton beans and invokes afterInit callbacks.
     * Also executes registered post functions.
     */
    public static func initAllBeans(): Unit {
        CONTEXT.createAllBeans()
        executePostFuncs()
    }

    /**
     * Destroy all beans in reverse dependency order.
     *
     * Invokes beforeDestroy callbacks on all beans and clears the context.
     */
    public static func destroyAllBeans(): Unit {
        CONTEXT.destroyAllBeans()
    }

    /**
     * Get bean factory by type.
     *
     * @param beanType bean type name
     * @return bean factory, or None if not found
     */
    public static func get(beanType: String): ?BeanFactory {
        CONTEXT._factories.get(beanType)
    }
}

// Register IoC context as a global service
private let _: Unit = ServiceContainer.GLOBAL.addService("ioc", BeanFactoryManager.getApplicationContext())
// Register cleanup handler on application exit
private let _: Unit = atExit {BeanFactoryManager.destroyAllBeans()}
