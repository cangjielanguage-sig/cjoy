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
 * Bean class implements this interface for lifecycle management
 */
public interface BeanLifecycle {
    /**
     * Invoke this function when bean is constructed
     */
    func afterInit(): Unit {
    }

    /**
     * Invoke this function when bean is about to be destroyed
     */
    func beforeDestroy(): Unit {
    }
}

/**
 * Interface of application context for bean management
 */
public interface ApplicationContext {
    /**
     * Get bean by name from application context
     *
     * @param name name of bean
     * @return existed bean or None
     */
    func getBean<T>(name: String): ?T

    /**
     * Get bean by type from application context
     *
     * @return existed bean or None
     */
    func getBean<T>(): ?T

    /**
     * Get all beans by type from application context
     *
     * @return collection of bean instances
     */
    func getBeans<T>(): Collection<T>

    /**
     * Get bean by type name from application context,
     * will create new bean if bean scope is Prototype
     *
     * @param beanType type name of bean
     * @return existed bean or newly created bean
     * @throws IocException if bean factory not found
     */
    func getBeanByTypeName<T>(beanType: String): ?T

    /**
     * Get beans by type name from application context,
     * will throw IocException if bean scope is Prototype
     *
     * @param beanType type name of bean
     * @return collection of bean instances
     * @throws IocException if bean factory not found or is prototype
     */
    func getBeansByTypeName<T>(beanType: String): Collection<T>

    /**
     * Get all beans from application context
     *
     * @return collection of all bean instances
     */
    func getAllBeans(): Collection<BeanLifecycle>

    /**
     * Add a bean to application context
     *
     * @param name name of bean
     * @param beanType type name of bean
     * @param bean bean object instance
     */
    func addBean(name: String, beanType: String, bean: BeanLifecycle): Unit
}

/**
 * Bean scope type definition
 */
public type BeanScope = String

/**
 * Singleton bean scope
 */
const SINGLETON: BeanScope = "singleton"

/**
 * Prototype bean scope
 */
const PROTOTYPE: BeanScope = "prototype"

/**
 * Bean factory interface for creating bean instances
 */
public interface BeanFactory {
    prop beanType: String
    prop beanScope: BeanScope

    /**
     * Create a bean instance
     *
     * @param ctx application context
     * @return tuple of bean name and bean instance
     */
    func create(ctx: ApplicationContext): (String, BeanLifecycle)
}

/**
 * IoC exception for IoC related errors
 */
public class IocException <: Exception {
    /**
     * Create IoC exception with message
     *
     * @param message error message
     */
    public IocException(message: String) {
        super(message)
    }
}
