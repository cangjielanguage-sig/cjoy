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

import std.collection.{ArrayList, HashMap, HashSet, map, forEach, any, filter, collectHashSet, collectArray}
import std.sort.sort

/**
 * Bean 依赖节点。
 *
 * 表示依赖图中的 Bean 类型，
 * 跟踪其依赖关系和被依赖关系，并计算深度。
 */
class BeanDepend <: Equatable<BeanDepend> & Hashable & ToString {
    /**
     * 创建 Bean 依赖节点。
     *
     * @param beanType Bean 类型名称
     */
    BeanDepend(let beanType: String,
        // 依赖的 Bean 类型
        let depends!: HashSet<BeanDepend> = HashSet(),
        // 被依赖的 Bean 类型
        let depons!: HashSet<BeanDepend> = HashSet(),
            // 树的反向深度
            var depth!: Int = Int.Max,
            // 是否是类（而非接口）
            var isClass!: Bool = false) {
    }

    /**
     * 生成此 Bean 依赖的哈希码。
     *
     * @return 哈希码
     */
    public func hashCode(): Int64 {
        beanType.hashCode()
    }

    /**
     * 检查与另一个 Bean 依赖的相等性。
     *
     * @param rhs 要比较的 Bean 依赖
     * @return 如果 Bean 类型相等则返回 true
     */
    public operator func ==(rhs: BeanDepend): Bool {
        this.beanType == rhs.beanType
    }

    /**
     * 转换为字符串表示形式。
     *
     * @return 包含 Bean 类型和深度的字符串
     */
    public func toString(): String {
        "{beanType:${beanType},depth:${depth}}"
    }
}

/**
 * Bean 依赖管理器。
 *
 * 管理 Bean 的依赖图，计算
 * 正确的初始化顺序并检测循环依赖。
 */
class BeanDependManager {
    // 键：beanType
    private let _beanTypes: HashMap<String, BeanDepend> = HashMap()
    // 键：接口类型，值：beanType 数组
    private let _extends: HashMap<String, HashSet<String>> = HashMap()

    /**
     * 获取或创建 Bean 依赖节点。
     *
     * @param beanType Bean 类型名称
     * @return Bean 依赖节点
     */
    private func get(beanType: String): BeanDepend {
        let bd = _beanTypes.get(beanType)
        match (bd) {
            case Some(d) => d
            case _ =>
                let d = BeanDepend(beanType)
                _beanTypes.add(beanType, d)
                d
        }
    }

    /**
     * 添加依赖关系。
     *
     * @param beanType Bean 类型名称
     * @param depends 此 Bean 依赖的 Bean 类型名称数组
     */
    func addDepends(beanType: String, depends: Array<String>): Unit {
        let bt = get(beanType)
        bt.isClass = true

        let deps = depends |> map {it => get(it)} |> collectArray
        for (dep in deps) {
            bt.depends.add(dep)
            dep.depons.add(bt)
        }
        resetDepth()
    }

    /**
     * 依赖关系变化后清除已计算的深度，避免后续查询使用过期结果
     */
    private func resetDepth(): Unit {
        for ((_, bd) in _beanTypes) {
            bd.depth = Int.Max
        }
    }

    /**
     * 添加接口实现。
     *
     * @param beanType Bean 类型名称
     * @param interfaces 此 Bean 实现的接口类型名称数组
     */
    func addTypes(beanType: String, interfaces: Array<String>): Unit {
        for (it in interfaces) {
            let inter = _extends.get(it)
            match (inter) {
                case Some(i) => i.add(beanType)
                case _ => _extends.add(it, HashSet([beanType]))
            }
        }
        resetDepth()
    }

    /**
     * 按接口或类名称获取类类型。
     *
     * @param btype 接口或类类型名称
     * @return 类类型名称的哈希集合
     */
    func getClassType(btype: String): HashSet<String> {
        _extends.get(btype) ?? HashSet<String>([btype])
    }

    /**
     * 获取排序后的 Bean 依赖。
     *
     * 计算依赖深度并返回按
     * 正确初始化顺序排序的 Bean。
     *
     * @param onlyClass true 表示只返回类 Bean，false 表示包含接口
     * @return 按深度排序的 Bean 依赖数组
     * @throws IocException 如果存在循环依赖
     */
    func getSortedBeanDepends(onlyClass!: Bool = true): Array<BeanDepend> {
        let noSetDepth = _beanTypes.values() |> any {it => it.depth == Int.Max}
        if (noSetDepth) {
            addDependForInterface()
            setDepth0()
            recursiveDepth(0)
        }

        let list = ArrayList<BeanDepend>()
        list.add(all: _beanTypes.values())
        // 按深度排序，最底层的 Bean 先出现
        sort(list, by: {a, b => a.depth.compare(b.depth)}, stable: true)
        if (onlyClass) {
            list |> filter {it => it.isClass} |> collectArray
        } else {
            list.toArray()
        }
    }

    /**
     * 为无依赖的 Bean 设置深度为 0。
     *
     * @throws IocException 如果不存在无依赖的 Bean（循环依赖）
     */
    private func setDepth0(): Unit {
        // 找到最底层（无依赖的 Bean）
        for ((k, v) in _beanTypes) {
            if (v.depends.isEmpty()) {
                v.depth = 0
                _beanTypes[k] = v
            }
        }

        let depth0 = _beanTypes.values() |> any {it => it.depth == 0}
        if (!depth0) {
            throw IocException("not found any bean has no dependent, maybe exist depend cycle")
        }
    }

    /**
     * 为接口类型添加依赖。
     *
     * 在接口及其实现类之间创建依赖关系。
     *
     * @throws IocException 如果实现类未注册
     */
    private func addDependForInterface(): Unit {
        // 过滤所有接口
        _beanTypes.values() |> filter {it => !it.isClass} |> forEach {
            // 根据接口查找实现类
            it: BeanDepend => match (_extends.get(it.beanType)) {
                case Some(bts) =>
                    // 构建接口到实现类的依赖关系
                    for (klass in bts) {
                        match (_beanTypes.get(klass)) {
                            case Some(bd) => it.depends.add(bd)
                            // 未找到对应的实现类已注册
                            case _ => throw IocException(
                                "not found class `${klass}` implements interface `${it.beanType}`")
                    }
                }
                // 未找到任何实现类
                case _ =>
                    // 注释掉异常以支持可选的接口依赖
                    // throw IocException("not found any class implements interface `${it.beanType}`")
                    ()
            }
        }
    }

    /**
     * 递归计算每个 Bean 类型的深度。
     *
     * @param depth 当前深度
     * @throws IocException 如果检测到循环依赖
     */
    private func recursiveDepth(depth: Int): Unit {
        // 找到上层 Bean 并设置深度值（它们在树中的深度）
        // 最底层的深度为 0，向上每层 +1
        let notSetDepth = _beanTypes.values() |> filter {it => it.depth == Int.Max} |> collectHashSet
        if (notSetDepth.isEmpty()) {
            return
        }

        var found = false
        let downs = _beanTypes.values() |> filter {it => it.depth <= depth} |> collectHashSet
        for (it in notSetDepth) {
            if (downs.contains(all: it.depends)) {
                it.depth = depth + 1
                _beanTypes[it.beanType] = it
                found = true
            }
        }

        if (!found) {
            throw IocException("not found any bean (has no dependent), maybe exist depend cycle")
        }
        recursiveDepth(depth + 1)
    }
}
