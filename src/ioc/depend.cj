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
 * Bean dependency node.
 *
 * Represents a bean type in the dependency graph,
 * tracking its dependencies and dependents with depth calculation.
 */
class BeanDepend <: Equatable<BeanDepend> & Hashable & ToString {
    /**
     * Create bean dependency node.
     *
     * @param beanType bean type name
     */
    BeanDepend(let beanType: String,
        // dependent bean types
        let depends!: HashSet<BeanDepend> = HashSet(),
        // dependent on bean types
        let depons!: HashSet<BeanDepend> = HashSet(),
            // tree reverse depth
            var depth!: Int = Int.Max,
            // class or interface
            var isClass!: Bool = false) {
    }

    /**
     * Generate hash code for this bean dependency.
     *
     * @return hash code
     */
    public func hashCode(): Int64 {
        beanType.hashCode()
    }

    /**
     * Check equality with another bean dependency.
     *
     * @param rhs bean dependency to compare
     * @return true if bean types are equal
     */
    public operator func ==(rhs: BeanDepend): Bool {
        this.beanType == rhs.beanType
    }

    /**
     * Convert to string representation.
     *
     * @return string containing bean type and depth
     */
    public func toString(): String {
        "{beanType:${beanType},depth:${depth}}"
    }
}

/**
 * Bean dependency manager.
 *
 * Manages the dependency graph for beans, calculating
 * proper initialization order and detecting circular dependencies.
 */
class BeanDependManager {
    // key: beanType
    private let _beanTypes: HashMap<String, BeanDepend> = HashMap()
    // key: interface type, value: array of beanType
    private let _extends: HashMap<String, HashSet<String>> = HashMap()

    /**
     * Get or create bean dependency node.
     *
     * @param beanType bean type name
     * @return bean dependency node
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
     * Add dependency relationship.
     *
     * @param beanType bean type name
     * @param depends array of bean type names this bean depends on
     */
    func addDepends(beanType: String, depends: Array<String>): Unit {
        let bt = get(beanType)
        bt.isClass = true

        let deps = depends |> map {it => get(it)} |> collectArray
        for (dep in deps) {
            bt.depends.add(dep)
            dep.depons.add(bt)
        }
    }

    /**
     * Add interface implementations.
     *
     * @param beanType bean type name
     * @param interfaces array of interface type names this bean implements
     */
    func addTypes(beanType: String, interfaces: Array<String>): Unit {
        for (it in interfaces) {
            let inter = _extends.get(it)
            match (inter) {
                case Some(i) => i.add(beanType)
                case _ => _extends.add(it, HashSet([beanType]))
            }
        }
    }

    /**
     * Get class types by interface or class name.
     *
     * @param btype interface or class type name
     * @return hash set of class type names
     */
    func getClassType(btype: String): HashSet<String> {
        _extends.get(btype) ?? HashSet<String>([btype])
    }

    /**
     * Get sorted bean dependencies.
     *
     * Calculates dependency depth and returns beans sorted
     * in proper initialization order.
     *
     * @param onlyClass true to return only class beans, false to include interfaces
     * @return array of bean dependencies sorted by depth
     * @throws IocException if circular dependency exists
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
        // sort by depth, bottom-most beans come first
        sort(list, by: {a, b => a.depth.compare(b.depth)}, stable: true)
        if (onlyClass) {
            list |> filter {it => it.isClass} |> collectArray
        } else {
            list.toArray()
        }
    }

    /**
     * Set depth to 0 for beans with no dependencies.
     *
     * @throws IocException if no bean with no dependencies exists (circular dependency)
     */
    private func setDepth0(): Unit {
        // find bottom layer (beans with no dependencies)
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
     * Add dependencies for interface types.
     *
     * Creates dependency relationships between interfaces and their implementing classes.
     *
     * @throws IocException if implementing class is not registered
     */
    private func addDependForInterface(): Unit {
        // filter all interfaces
        _beanTypes.values() |> filter {it => !it.isClass} |> forEach {
            // find implementing classes based on interface
            it: BeanDepend => match (_extends.get(it.beanType)) {
                case Some(bts) =>
                    // build interface-to-implementation class dependency relationship
                    for (klass in bts) {
                        match (_beanTypes.get(klass)) {
                            case Some(bd) => it.depends.add(bd)
                            // haven't found corresponding implementation class registered
                            case _ => throw IocException(
                                "not found class `${klass}` implements interface `${it.beanType}`")
                    }
                }
                // haven't found any implementing class
                case _ =>
                    // commented out exception to support optional interface dependency
                    // throw IocException("not found any class implements interface `${it.beanType}`")
                    ()
            }
        }
    }

    /**
     * Recursively calculate depth for each bean type.
     *
     * @param depth current depth being
     * @throws IocException if circular dependency detected
     */
    private func recursiveDepth(depth: Int): Unit {
        // find beans going up and set Depth value (their depth in tree)
        // bottom layer has depth 0, going up +1
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
