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

import std.collection.{ArrayList, map, collectArray}
import std.collection.concurrent.ConcurrentHashMap
import std.sync.{Mutex, AtomicBool}
import cjoy.log.macros.*

class DefaultApplicationContext <: ApplicationContext {
    private let _beans = ConcurrentHashMap<String, BeanLifecycle>()
    private let _beansByTypes = ConcurrentHashMap<String, BeanLifecycle>()
    private let _mutex: Mutex = Mutex()

    let _factories: ConcurrentHashMap<String, BeanFactory> = ConcurrentHashMap()
    let _beanDependManger: BeanDependManager = BeanDependManager()
    let _inited: AtomicBool = AtomicBool(false)

    public func getBean<T>(name: String): ?T {
        let res = _beans.get(name)
        convert<T>(res)
    }

    private func convert<T>(res: ?BeanLifecycle): ?T {
        match (res) {
            case Some(v) => match (v) {
                case x: T => x
                case _ => None
            }
            case _ => None
        }
    }

    /**
     * @throws IocException if exist multiple candidate
     */
    public func getBean<T>(): ?T {
        let res = getBeansByType<T>()
        if (res.isEmpty()) {
            None
        } else if (res.size == 1) {
            res[0]
        } else {
            throw IocException("there are multiple candidate implementations")
        }
    }

    public func getBeans<T>(): Collection<T> {
        return getBeansByType<T>()
    }

    /**
     * @throws IocException if exist multiple candidate
     */
    public func getBeanByTypeName<T>(beanType: String): ?T {
        let res = getBeanByTypeNameInner(beanType)
        convert<T>(res)
    }

    /**
     * @throws IocException if exist multiple candidate
     */
    private func getBeanByTypeNameInner(beanType: String): ?BeanLifecycle {
        let classTypes = _beanDependManger.getClassType(beanType)
        let res = ArrayList<BeanLifecycle>()
        for (bt in classTypes) {
            let factory = _factories.get(bt)
            match (factory) {
                case Some(f) =>
                    let bean = getBeanByTypeNameInner(f, bt, classTypes.size)
                    if (let Some(b) <- bean) {
                        res.add(b)
                    }
                case _ => ()
            }
        }
        if (res.isEmpty()) {
            None
        } else if (res.size == 1) {
            res[0]
        } else {
            throw IocException("there are multiple candidate implementations")
        }
    }

    /**
     * @throws IocException if exist multiple candidate
     */
    private func getBeanByTypeNameInner(f: BeanFactory, bt: String, classTypeSize: Int): ?BeanLifecycle {
        if (f.beanScope == SINGLETON) {
            let bean = _beansByTypes.get(bt)
            match (bean) {
                case Some(b) => return b
                case _ => return None
            }
        } else {
            // Prototype Bean只支持单个get
            if (classTypeSize == 1) {
                let (_, bean) = f.create(this)
                bean.afterInit()
                return bean
            } else {
                throw IocException("there are multiple candidate implementations")
            }
        }
    }

    public func getBeansByTypeName<T>(beanType: String): Collection<T> {
        let res = getBeansByTypeNameInner(beanType)
        res |> map {it => convert<T>(it).getOrThrow({=> IocException("${beanType} object is not T type")})} |>
            collectArray
    }

    private func getBeansByTypeNameInner(beanType: String): Collection<BeanLifecycle> {
        let classTypes = _beanDependManger.getClassType(beanType)
        let res = ArrayList<BeanLifecycle>()
        for (bt in classTypes) {
            let factory = _factories.get(bt)
            match (factory) {
                case Some(f) =>
                    let bean = getBeanByTypeNameInner(f, bt, classTypes.size)
                    if (let Some(b) <- bean) {
                        res.add(b)
                    }
                case _ => ()
            }
        }
        res
    }

    public func getAllBeans(): Collection<BeanLifecycle> {
        let iter = _beans.iterator()
        let res = ArrayList<BeanLifecycle>()
        while (let Some((_, v)) <- iter.next()) {
            res.add(v)
        }
        res
    }

    private func getBeansByType<T>(): ArrayList<T> {
        let iter = _beans.iterator()
        let res = ArrayList<T>()
        while (let Some((k, v)) <- iter.next()) {
            match (v) {
                // T可以Bean实现的接口，遍历所有Bean查找匹配T的Bean
                case x: T => res.add(x)
                case _ => ()
            }
        }
        return res
    }

    public func addBean(name: String, beanType: String, bean: BeanLifecycle): Unit {
        // 按Bean Name建立关系
        _beans.add(name, bean)
        // 按Bean类型建立关系
        _beansByTypes.add(beanType, bean)
    }

    /**
     * @throws IocException if not found bean factory
     */
    public func createAllBeans(): Unit {
        if (_inited.compareAndSwap(false, true)) {
            // 按Bean依赖关系排序，创建所有Bean
            let beans = _beanDependManger.getSortedBeanDepends()
            for (b in beans) {
                match (_factories.get(b.beanType)) {
                    case Some(factory) =>
                        // Prototype Bean 每次getBeanByTypeName都创建，不存储避免太多导致内存泄露
                        if (factory.beanScope == SINGLETON) {
                            let (name, bean) = factory.create(this)
                            @LogInfo("[IOC] created bean, name=${name}, beanType=${b.beanType}")
                            addBean(name, b.beanType, bean)
                        }
                    case _ => throw IocException("not found bean factory for `${b.beanType}`")
                }
            }

            // 初始化所有Bean
            for (bean in getAllBeans()) {
                bean.afterInit()
            }
        }
    }

    public func destroyAllBeans(): Unit {
        let beans = getAllBeans()
        for (b in beans) {
            b.beforeDestroy()
        }

        let iter = _beans.iterator()
        while (let Some((k, _)) <- iter.next()) {
            _beans.remove(k)
        }
    }
}
