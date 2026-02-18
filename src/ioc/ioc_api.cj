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

/**
 * Bean 生命周期管理接口。
 *
 * 实现此接口的 Bean 在初始化和销毁阶段接收生命周期回调。
 */
public interface BeanLifecycle {
    /**
     * Bean 构造后调用的回调。
     *
     * 在所有 Bean 依赖解析完成且 Bean 完全构造后调用。
     * 重写以执行初始化逻辑。
     */
    func afterInit(): Unit {
    }

    /**
     * Bean 销毁前调用的回调。
     *
     * 在应用上下文被销毁时调用。
     * 重写以执行清理逻辑。
     */
    func beforeDestroy(): Unit {
    }
}

/**
 * 用于 Bean 管理的应用上下文接口。
 *
 * 提供在 IoC 容器中检索和管理 Bean 的方法。
 */
public interface ApplicationContext {
    /**
     * 从应用上下文中按名称获取 Bean
     *
     * @param name 要检索的 Bean 名称
     * @return Bean 实例，如果未找到则返回 None
     */
    func getBean<T>(name: String): ?T

    /**
     * 从应用上下文中按类型获取 Bean
     *
     * @return Bean 实例，如果未找到则返回 None
     * @throws IocException 如果存在多个候选者
     */
    func getBean<T>(): ?T

    /**
     * 从应用上下文中按类型获取所有 Bean
     *
     * @return 匹配类型 T 的 Bean 实例集合
     */
    func getBeans<T>(): Collection<T>

    /**
     * 从应用上下文中按类型名称获取 Bean
     *
     * 如果 Bean 作用域为 PROTOTYPE，将创建新的 Bean
     *
     * @param beanType Bean 的类型名称
     * @return Bean 实例（已存在或新创建的），如果未找到则返回 None
     * @throws IocException 如果未找到 Bean 工厂
     */
    func getBeanByTypeName<T>(beanType: String): ?T

    /**
     * 从应用上下文中按类型名称获取 Bean
     *
     * 如果 Bean 作用域为 PROTOTYPE 将抛出 IocException
     *
     * @param beanType Bean 的类型名称
     * @return Bean 实例集合
     * @throws IocException 如果未找到 Bean 工厂或是原型作用域
     */
    func getBeansByTypeName<T>(beanType: String): Collection<T>

    /**
     * 从应用上下文中获取所有 Bean
     *
     * @return 所有实现 BeanLifecycle 的 Bean 实例集合
     */
    func getAllBeans(): Collection<BeanLifecycle>

    /**
     * 向应用上下文中添加 Bean
     *
     * @param name Bean 的名称
     * @param beanType Bean 的类型名称
     * @param bean 实现 BeanLifecycle 的 Bean 实例
     */
    func addBean(name: String, beanType: String, bean: BeanLifecycle): Unit
}

/**
 * Bean 作用域类型定义。
 *
 * 定义 Bean 实例在容器中的管理方式。
 */
public type BeanScope = String

/**
 * 单例 Bean 作用域。
 *
 * 容器中只存在一个 Bean 实例。
 * 所有请求都返回同一个实例。
 */
const SINGLETON: BeanScope = "singleton"

/**
 * 原型 Bean 作用域。
 *
 * 每个请求都会创建新的实例。
 * 实例不受容器管理。
 */
const PROTOTYPE: BeanScope = "prototype"

/**
 * 用于创建 Bean 实例的 Bean 工厂接口。
 *
 * 实现类提供创建 Bean 的逻辑，
 * 并解析其依赖关系。
 */
public interface BeanFactory {
    /**
     * Bean 类型名称。
     */
    prop beanType: String

    /**
     * Bean 作用域（单例或原型）。
     */
    prop beanScope: BeanScope

    /**
     * 创建 Bean 实例。
     *
     * @param ctx 用于解析依赖的应用上下文
     * @return Bean 名称和 Bean 实例的元组
     */
    func create(ctx: ApplicationContext): (String, BeanLifecycle)
}

/**
 * IoC 相关错误的异常。
 *
 * 当 Bean 解析或依赖注入失败时抛出。
 */
public class IocException <: Exception {
    /**
     * 使用消息创建 IoC 异常。
     *
     * @param message 错误消息
     */
    public IocException(message: String) {
        super(message)
    }
}
