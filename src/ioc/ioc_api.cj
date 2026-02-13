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
 * Bean lifecycle management interface.
 *
 * Beans implementing this interface receive lifecycle callbacks
 * during initialization and destruction phases.
 */
public interface BeanLifecycle {
    /**
     * Callback invoked after bean construction.
     *
     * Called after all bean dependencies are resolved and the bean
     * is fully constructed. Override to perform initialization logic.
     */
    func afterInit(): Unit {
    }

    /**
     * Callback invoked before bean destruction.
     *
     * Called when the application context is being destroyed.
     * Override to perform cleanup logic.
     */
    func beforeDestroy(): Unit {
    }
}

/**
 * Application context interface for bean management.
 *
 * Provides methods to retrieve and manage beans in the IoC container.
 */
public interface ApplicationContext {
    /**
     * Get bean by name from application context.
     *
     * @param name name of bean
     * @return bean instance, or None if not found
     */
    func getBean<T>(name: String): ?T

    /**
     * Get bean by type from application context.
     *
     * @return bean instance, or None if not found
     * @throws IocException if multiple candidates exist
     */
    func getBean<T>(): ?T

    /**
     * Get all beans by type from application context.
     *
     * @return collection of bean instances matching type T
     */
    func getBeans<T>(): Collection<T>

    /**
     * Get bean by type name from application context.
     *
     * Will create new bean if bean scope is PROTOTYPE.
     *
     * @param beanType type name of bean
     * @return bean instance (existing or newly created), or None if not found
     * @throws IocException if bean factory not found
     */
    func getBeanByTypeName<T>(beanType: String): ?T

    /**
     * Get beans by type name from application context.
     *
     * Will throw IocException if bean scope is PROTOTYPE.
     *
     * @param beanType type name of bean
     * @return collection of bean instances
     * @throws IocException if bean factory not found or is prototype
     */
    func getBeansByTypeName<T>(beanType: String): Collection<T>

    /**
     * Get all beans from application context.
     *
     * @return collection of all bean instances implementing BeanLifecycle
     */
    func getAllBeans(): Collection<BeanLifecycle>

    /**
     * Add a bean to application context.
     *
     * @param name name of bean
     * @param beanType type name of bean
     * @param bean bean instance implementing BeanLifecycle
     */
    func addBean(name: String, beanType: String, bean: BeanLifecycle): Unit
}

/**
 * Bean scope type definition.
 *
 * Defines how bean instances are managed in the container.
 */
public type BeanScope = String

/**
 * Singleton bean scope.
 *
 * Only one instance of the bean exists in the container.
 * The same instance is returned on all requests.
 */
const SINGLETON: BeanScope = "singleton"

/**
 * Prototype bean scope.
 *
 * A new instance is created on each request.
 * Instances are not managed by the container.
 */
const PROTOTYPE: BeanScope = "prototype"

/**
 * Bean factory interface for creating bean instances.
 *
 * Implementations provide the logic for creating beans
 * with their dependencies resolved.
 */
public interface BeanFactory {
    /**
     * Bean type name.
     */
    prop beanType: String

    /**
     * Bean scope (singleton or prototype).
     */
    prop beanScope: BeanScope

    /**
     * Create a bean instance.
     *
     * @param ctx application context for resolving dependencies
     * @return tuple of bean name and bean instance
     */
    func create(ctx: ApplicationContext): (String, BeanLifecycle)
}

/**
 * IoC exception for IoC related errors.
 *
 * Thrown when bean resolution or dependency injection fails.
 */
public class IocException <: Exception {
    /**
     * Create IoC exception with message.
     *
     * @param message error message
     */
    public IocException(message: String) {
        super(message)
    }
}
