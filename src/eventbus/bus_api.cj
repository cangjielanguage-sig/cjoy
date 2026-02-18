/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.eventbus

import cjoy.context.{Context, MapContext}

/**
 * 事件订阅者接口。
 *
 * 实现此接口以处理发布到事件总线的事件。
 */
public interface EventSubscriber {
    /**
     * 处理事件。
     *
     * @param ctx 应用上下文
     * @param evt 要处理的事件
     */
    func handle(ctx: Context, evt: Event): Unit
}

/**
 * 事件订阅者函数的类型别名。
 *
 * 可直接用作订阅者的函数类型。
 */
public type EventSubscriberFunc = (ctx: Context, evt: Event) -> Unit

/**
 * 包装函数的事件订阅者。
 *
 * 允许将函数用作事件订阅者。
 */
public class EventFuncSubscriber <: EventSubscriber {
    /**
     * 创建新的 EventFuncSubscriber。
     *
     * @param fn 事件订阅者函数
     */
    public EventFuncSubscriber(let fn: EventSubscriberFunc) {
    }

    /**
     * 通过调用包装函数处理事件。
     *
     * @param ctx 应用上下文
     * @param evt 要处理的事件
     */
    public func handle(ctx: Context, evt: Event): Unit {
        fn(ctx, evt)
    }
}

/**
 * 事件总线接口。
 *
 * 定义事件总线实现的约定，
 * 提供订阅和触发事件的方法。
 */
public interface EventBus {
    /**
     * 注册订阅者以处理事件。
     *
     * @param pattern 匹配模式。匹配规则：
     *   - "*" 匹配任何非点字符序列
     *   - "**" 匹配到结尾的所有字符，仅在模式开头或结尾允许
     *   示例：
     *     - "evt.some.*.*"       -> 匹配 "evt.some.thing.run", "evt.some.thing.do"
     *     - "evt.some.*.run"     -> 匹配 "evt.some.thing.run", 但不匹配 "evt.some.thing.do"
     *     - "evt.some.**"        -> 匹配任何以 "evt.some." 开头的内容，例如 "evt.some.thing.run", "evt.some.thing.do"
     *     - "**.thing.run"       -> 匹配任何以 ".thing.run" 结尾的内容，例如 "evt.some.thing.run"
     * @param name 订阅者名称
     * @param subscriber 事件订阅者
     * @param priority 处理事件的优先级（值越高越先执行）
     * @throws EventBusException 如果模式无效
     */
    func onEvent(pattern: String, name: String, subscriber: EventSubscriber, priority: Array<Int>): Unit

    /**
     * 注册订阅者函数以处理事件。
     *
     * @param pattern 匹配模式
     * @param name 订阅者名称
     * @param subscriber 事件订阅者函数
     * @param priority 处理事件的优先级
     * @throws EventBusException 如果模式无效
     */
    func onEvent(pattern: String, name: String, subscriber: EventSubscriberFunc, priority: Array<Int>): Unit {
        onEvent(pattern, name, EventFuncSubscriber(subscriber), priority)
    }

    /**
     * 注册订阅者以处理事件，仅触发一次。
     *
     * 处理完第一个事件后自动移除订阅者。
     *
     * @param pattern 匹配模式
     * @param name 订阅者名称
     * @param listener 事件订阅者
     * @param priority 处理事件的优先级
     */
    func onceEvent(pattern: String, name: String, listener: EventSubscriber, priority: Array<Int>): Unit {
        let onceListener = {
            ctx: Context, evt: Event => try {
                listener.handle(ctx, evt)
            } finally {
                removeSubscriber(pattern, name)
            }
        }
        onEvent(pattern, name, onceListener, priority)
    }

    /**
     * 注册订阅者函数以处理事件，仅触发一次。
     *
     * @param pattern 匹配模式
     * @param name 订阅者名称
     * @param subscriber 事件订阅者函数
     * @param priority 处理事件的优先级
     */
    func onceEvent(pattern: String, name: String, subscriber: EventSubscriberFunc, priority: Array<Int>): Unit {
        onceEvent(pattern, name, EventFuncSubscriber(subscriber), priority)
    }

    /**
     * 通过模式和名称移除订阅者。
     *
     * @param pattern 匹配模式
     * @param name 订阅者名称
     */
    func removeSubscriber(pattern: String, name: String): Unit

    /**
     * 通过队列异步触发事件。
     *
     * 事件被排队并由消费者线程处理。
     *
     * @param cxt 应用上下文
     * @param evts 要触发的事件
     */
    func fireEventAsync(cxt: Context, evts: Array<Event>): Unit

    /**
     * 同步触发事件。
     *
     * 事件在调用线程上立即处理。
     *
     * @param cxt 应用上下文
     * @param evts 要触发的事件
     */
    func fireEvent(cxt: Context, evts: Array<Event>): Unit

    /**
     * 通过线程异步触发事件。
     *
     * 在新线程中使用新上下文触发事件。
     *
     * @param _ 上下文（被忽略，会创建新的 MapContext）
     * @param evts 要触发的事件
     */
    func asyncFireEvent(_: Context, evts: Array<Event>): Unit {
        spawn {
            fireEvent(MapContext(), evts)
        }
    }

    /**
     * 关闭事件总线并等待所有异步事件完成。
     *
     * 取消消费者线程并等待待处理事件被处理。
     *
     * @throws InterruptedException 如果在等待时被中断
     */
    func closeAndWait(): Unit
}

/**
 * 事件总线异常。
 *
 * 用于抛出事件总线相关的错误，如无效模式等。
 */
public class EventBusException <: Exception {
    /**
     * 创建新的事件总线异常。
     *
     * @param message 错误消息
     */
    public EventBusException(message: String) {
        super(message)
    }
}

/**
 * 常量配置的常量。
 */
public struct EventConsts {
    /**
     * 最低优先级 (-1000)。
     */
    public static const PRIORITY_MIN: Int = -1000

    /**
     * 低优先级 (-500)。
     */
    public static const PRIORITY_LOW: Int = -500

    /**
     * 正常优先级 (0)。
     */
    public static const PRIORITY_NORMAL: Int = 0

    /**
     * 高优先级 (500)。
     */
    public static const PRIORITY_HIGH: Int = 500

    /**
     * 最高优先级 (1000)。
     */
    public static const PRIORITY_MAX: Int = 1000

    /**
     * 匹配任何单个节点的通配符 (*)。
     */
    public static const ANY_NODE: String = "*"

    /**
     * 匹配到末尾所有节点的通配符 (**)。
     */
    public static const ALL_NODE: String = "**"
}
