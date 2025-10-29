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

/**
 * the bean class implements this interface
 */
public interface BeanLifecycle {
    /**
     * invoke this func when the bean post construct
     */
    func afterInit(): Unit {
    }

    /**
     * invoke this func when the bean before destory
     */
    func beforeDestroy(): Unit {
    }
}

/**
 * the interface of application context
 */
public interface ApplicationContext {
    /**
     * get bean by name from app context
     *
     * @param name: the name of bean
     * @return: the existed bean
     */
    func getBean<T>(name: String): ?T

    /**
     * get bean by type from app context
     *
     * @return: the existed bean
     */
    func getBean<T>(): ?T

    /**
     * get all beans by type from app context
     *
     * @return: the existed bean list
     */
    func getBeans<T>(): Collection<T>

    /**
     *  get bean by name from app context, it will create new bean if the bean scope is Prototype
     *
     * @param beanType: the type of bean
     * @return: the existed bean or new created bean
     * @throws IocException if not exist factory
     */
    func getBeanByTypeName<T>(beanType: String): ?T

    /**
     *  get bean by name from app context, it will throw IocException if the bean scope is Prototype
     *
     * @param beanType: the type of bean
     * @return: the existed bean
     * @throws IocException if not exist factory or is prototype
     */
    func getBeansByTypeName<T>(beanType: String): Collection<T>

    /**
     * get all beans from app context
     *
     * @return: the existed bean list
     */
    func getAllBeans(): Collection<BeanLifecycle>

    /**
     * add a bean to app context
     *
     * @param name: the name of bean
     * @param beanType: the type name of bean
     * @param bean: the bean object
     */
    func addBean(name: String, beanType: String, bean: BeanLifecycle): Unit
}

public type BeanScope = String

const SINGLETON: BeanScope = "singleton"
const PROTOTYPE: BeanScope = "prototype"

public interface BeanFactory {
    prop beanType: String
    prop beanScope: BeanScope

    /**
     * create a bean return the bean name and instance
     *
     * @param ctx: the application context
     */
    func create(ctx: ApplicationContext): (String, BeanLifecycle)
}

public class IocException <: Exception {
    public IocException(message: String) {
        super(message)
    }
}
