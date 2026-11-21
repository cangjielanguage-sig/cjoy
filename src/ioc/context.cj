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

/**
 * 默认应用上下文实现。
 *
 * 使用 ConcurrentHashMap 提供线程安全的 Bean 存储和检索。
 * 管理命名和类型化的 Bean 查找。
 */
class DefaultApplicationContext <: ApplicationContext {
    private let _beans = ConcurrentHashMap<String, BeanLifecycle>()
    private let _beansByTypes = ConcurrentHashMap<String, BeanLifecycle>()
    private let _mutex: Mutex = Mutex()

    let _factories: ConcurrentHashMap<String, BeanFactory> = ConcurrentHashMap()
    let _beanDependManager: BeanDependManager = BeanDependManager()
    let _inited: AtomicBool = AtomicBool(false)

    /**
     * 按名称获取 Bean。
     *
     * @param name Bean 名称
     * @return Bean 实例，如果未找到则返回 None
     */
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
     * 按类型获取 Bean。
     *
     * @return Bean 实例，如果未找到则返回 None
     * @throws IocException 如果存在多个候选者
     */
    public func getBean<T>(): ?T {
        let res = getBeansByType<T>()
        if (res.isEmpty()) {
            None
        } else if (res.size == 1) {
            res[0]
        } else {
            throw IocException("存在多个候选实现")
        }
    }

    /**
     * 按类型获取所有 Bean。
     *
     * @return Bean 实例集合
     */
    public func getBeans<T>(): Collection<T> {
        return getBeansByType<T>()
    }

    /**
     * 按类型名称获取 Bean。
     *
     * @param beanType Bean 类型名称
     * @return Bean 实例，如果未找到则返回 None
     * @throws IocException 如果存在多个候选者
     */
    public func getBeanByTypeName<T>(beanType: String): ?T {
        let res = getBeanByTypeNameInner(beanType)
        convert<T>(res)
    }

    /**
     * 按类型名称获取 Bean（内部）。
     *
     * @param beanType Bean 类型名称
     * @return Bean 生命周期，如果未找到则返回 None
     * @throws IocException 如果存在多个候选者
     */
    private func getBeanByTypeNameInner(beanType: String): ?BeanLifecycle {
        let classTypes = _beanDependManager.getClassType(beanType)
        let res = ArrayList<BeanLifecycle>()
        for (bt in classTypes) {
            let factory = _factories.get(bt)
            match (factory) {
                case Some(f) =>
                    let bean = getBeanByTypeNameInner(f, bt, classTypes.size, allowPrototype: false)
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
     * 按类型名称和工厂获取 Bean（内部）。
     *
     * @param f Bean 工厂
     * @param bt Bean 类型名称
     * @param classTypeSize 类类型数量
     * @return Bean 生命周期，如果未找到则返回 None
     * @throws IocException 如果存在多个候选者
     */
    private func getBeanByTypeNameInner(f: BeanFactory, bt: String, classTypeSize: Int,
        allowPrototype!: Bool = false): ?BeanLifecycle {
        if (f.beanScope == SINGLETON) {
            let bean = _beansByTypes.get(bt)
            match (bean) {
                case Some(b) => return b
                case _ => return None
            }
        } else {
            // 单值查询在候选者不唯一时拒绝原型 Bean；复数查询应返回全部实现
            if (classTypeSize == 1 || allowPrototype) {
                let (_, bean) = f.create(this)
                bean.afterInit()
                return bean
            } else {
                throw IocException("there are multiple candidate implementations")
            }
        }
    }

    /**
     * 按类型名称获取所有 Bean。
     *
     * @param beanType Bean 类型名称
     * @return Bean 实例集合
     * @throws IocException 如果 Bean 不是 T 类型
     */
    public func getBeansByTypeName<T>(beanType: String): Collection<T> {
        let res = getBeansByTypeNameInner(beanType)
        res |> map {it => convert<T>(it).getOrThrow({=> IocException("${beanType} 对象不是 T 类型")})} |>
            collectArray
    }

    /**
     * 按类型名称获取所有 Bean（内部）。
     *
     * @param beanType Bean 类型名称
     * @return Bean 生命周期集合
     */
    private func getBeansByTypeNameInner(beanType: String): Collection<BeanLifecycle> {
        let classTypes = _beanDependManager.getClassType(beanType)
        let res = ArrayList<BeanLifecycle>()
        for (bt in classTypes) {
            let factory = _factories.get(bt)
            match (factory) {
                case Some(f) =>
                    let bean = getBeanByTypeNameInner(f, bt, classTypes.size, allowPrototype: true)
                    if (let Some(b) <- bean) {
                        res.add(b)
                    }
                case _ => ()
            }
        }
        res
    }

    /**
     * 获取所有 Bean。
     *
     * @return 所有 Bean 生命周期集合
     */
    public func getAllBeans(): Collection<BeanLifecycle> {
        let iter = _beans.iterator()
        let res = ArrayList<BeanLifecycle>()
        while (let Some((_, v)) <- iter.next()) {
            res.add(v)
        }
        res
    }

    /**
     * 按类型获取 Bean（内部）。
     *
     * @return 匹配类型 T 的 Bean 数组
     */
    private func getBeansByType<T>(): ArrayList<T> {
        let iter = _beans.iterator()
        let res = ArrayList<T>()
        while (let Some((k, v)) <- iter.next()) {
            match (v) {
                // T 可以是 Bean 实现的接口，遍历所有 Bean 查找匹配 T 的 Bean
                case x: T => res.add(x)
                case _ => ()
            }
        }
        return res
    }

    /**
     * 向上下文添加 Bean。
     *
     * @param name Bean 名称
     * @param beanType Bean 类型名称
     * @param bean Bean 实例
     */
    public func addBean(name: String, beanType: String, bean: BeanLifecycle): Unit {
        // 按Bean Name建立关系
        _beans.add(name, bean)
        // 按Bean类型建立关系
        _beansByTypes.add(beanType, bean)
    }

    /**
     * 按依赖顺序创建所有 Bean。
     *
     * @throws IocException 如果未找到 Bean 工厂
     */
    public func createAllBeans(): Unit {
        if (_inited.compareAndSwap(false, true)) {
            // 按Bean依赖关系排序，创建所有Bean
            let beans = _beanDependManager.getSortedBeanDepends()
            for (b in beans) {
                match (_factories.get(b.beanType)) {
                    case Some(factory) =>
                        // Prototype Bean 每次调用 getBeanByTypeName 时创建新实例，不存储以避免内存泄漏
                        if (factory.beanScope == SINGLETON) {
                            let (name, bean) = factory.create(this)
                            @JoyLogInfo("[IOC] created bean, name=${name}, beanType=${b.beanType}")
                            addBean(name, b.beanType, bean)
                        }
                    case _ => throw IocException("未找到 `${b.beanType}` 的 Bean 工厂")
                }
            }

            // 初始化所有Bean
            for (bean in getAllBeans()) {
                bean.afterInit()
            }
        }
    }

    /**
     * 销毁所有 Bean。
     *
     * 调用所有 Bean 的 beforeDestroy 方法并从上下文中移除它们。
     */
    public func destroyAllBeans(): Unit {
        let beans = getAllBeans()
        for (b in beans) {
            b.beforeDestroy()
        }

        let iter = _beans.iterator()
        while (let Some((k, _)) <- iter.next()) {
            _beans.remove(k)
        }
        // 同时清理按类型缓存，并允许后续重新初始化
        let typeIter = _beansByTypes.iterator()
        while (let Some((k, _)) <- typeIter.next()) {
            _beansByTypes.remove(k)
        }
        _inited.store(false)
        BeanFactoryManager.EXECUTED.store(false)
    }
}
