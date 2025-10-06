/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.ioc.api

import std.collection.ArrayList
import std.collection.concurrent.ConcurrentHashMap
import std.sync.AtomicBool
import cjoy.log.*

public class BeanFactoryManager {
    private static let CONTEXT: DefaultApplicationContext = DefaultApplicationContext()
    private static let POST_FUNCS: ArrayList<() -> Unit> = ArrayList()

    static let EXECUTED: AtomicBool = AtomicBool(false)

    public static func getApplicationContext(): ApplicationContext {
        CONTEXT
    }

    public static func register(beanType: String, depends: Array<String>, factory: BeanFactory): Unit {
        @LogInfo("[IOC] register bean info, beanType=${beanType}, depends=${depends}")
        CONTEXT._factories.add(beanType, factory)
        CONTEXT._beanDependManger.addDepends(beanType, depends)
    }

    public static func registerTypes(beanType: String, interfaces: Array<String>): Unit {
        @LogInfo("[IOC] register bean types, beanType=${beanType}, interfaces=${interfaces}")
        CONTEXT._beanDependManger.addTypes(beanType, interfaces)
    }

    public static func registerPostFunc(beanType: String, fn: () -> Unit): Unit {
         @LogInfo("[IOC] register post func , beanType=${beanType}")
        POST_FUNCS.add(fn)
    }

    public static func executePostFuncs(): Unit {
        @LogInfo("[IOC] exeucte registered post func ")
        if (EXECUTED.compareAndSwap(false, true)) {
            for (fn in POST_FUNCS) {
                fn()
            }
        }
    }

    public static func get(beanType: String): ?BeanFactory {
        CONTEXT._factories.get(beanType)
    }
}
