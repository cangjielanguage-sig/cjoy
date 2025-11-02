/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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

class BeanDepend <: Equatable<BeanDepend> & Hashable & ToString {
    BeanDepend(let beanType: String,
        // dependent bean types
        let depends!: HashSet<BeanDepend> = HashSet(),
        // dependent on bean types
        let depons!: HashSet<BeanDepend> = HashSet(),
            // the tree reverse depth 
            var depth!: Int = Int.Max,
            // class or interface 
            var isClass!: Bool = false) {
    }

    public func hashCode(): Int64 {
        beanType.hashCode()
    }

    public operator func ==(rhs: BeanDepend): Bool {
        this.beanType == rhs.beanType
    }

    public func toString(): String {
        "{beanType:${beanType},depth:${depth}}"
    }
}

class BeanDependManager {
    // key: beanType
    private let _beanTypes: HashMap<String, BeanDepend> = HashMap()
    // key: interface type, value: the array of beanType
    private let _extends: HashMap<String, HashSet<String>> = HashMap()

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

    func addDepends(beanType: String, depends: Array<String>): Unit {
        let bt = get(beanType)
        bt.isClass = true

        let deps = depends |> map {it => get(it)} |> collectArray
        for (dep in deps) {
            bt.depends.add(dep)
            dep.depons.add(bt)
        }
    }

    func addTypes(beanType: String, interfaces: Array<String>): Unit {
        for (it in interfaces) {
            let inter = _extends.get(it)
            match (inter) {
                case Some(i) => i.add(beanType)
                case _ => _extends.add(it, HashSet([beanType]))
            }
        }
    }

    func getClassType(btype: String): HashSet<String> {
        _extends.get(btype) ?? HashSet<String>([btype])
    }

    /**
     * @throws IocException if exist depend cycle
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
        // 按深度排序，最底层排在最前面
        sort(list, by: {a, b => a.depth.compare(b.depth)}, stable: true)

        if (onlyClass) {
            list |> filter {it => it.isClass} |> collectArray
        } else {
            list.toArray()
        }
    }

    /**
     * @throws IocException if not found the type
     */
    private func setDepth0(): Unit {
        // 先找到最底层，即没有任何依赖的Bean类型
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
     * @throws IocException if not found the type
     */
    private func addDependForInterface(): Unit {
        // 过滤所有接口
        _beanTypes.values() |> filter {it => !it.isClass} |> forEach {
            // 根据接口找到实现类
            it: BeanDepend => match (_extends.get(it.beanType)) {
                case Some(bts) =>
                    // 构建接口到实现类的依赖关系
                    for (klass in bts) {
                    match (_beanTypes.get(klass)) {
                        case Some(bd) => it.depends.add(bd)
                        // 没有找到对应实现类的注册过其信息
                        case _ => throw IocException(
                            "not found the class `${klass}` implements inferface `${it.beanType}`")
                    }
                }
                // 没有没有找到任何实现类
                case _ =>
                    // 注释掉异常表示支持接口可选依赖
                    // throw IocException("not found any class implements inferface `${it.beanType}`")
                    ()
            }
        }
    }

    /**
     * @throws IocException if exist depend cycle
     */
    private func recursiveDepth(depth: Int): Unit {
        // 从下往上找到Bean类型，并修改Depth值，即所在深度
        // 最下层深度为0，往上依次+1
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
            throw IocException("not found any bean has no dependent, maybe exist depend cycle")
        }
        recursiveDepth(depth + 1)
    }
}
