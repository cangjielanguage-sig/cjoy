/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.regex.Regex
import std.sort.sort
import std.collection.{ArrayList, HashMap}
import cjoy.log.macros.*

/**
 * 表示存储处理器、模式和参数键的路由端点
 *
 * @param T 处理器类型
 */
class Endpoint<T> <: ToString {
    /**
     * 创建新的端点实例
     *
     * @param handler 路由处理器
     * @param pattern URL 模式
     * @param paramKeys 路由的参数键
     */
    Endpoint(let handler: T, let pattern: String, let paramKeys: Array<String>) {
    }

    /**
     * 将端点转换为字符串表示
     *
     * @return 端点的字符串表示
     */
    public func toString(): String {
        return "(pattern:${pattern},paramKeys:${paramKeys})"
    }
}

/**
 * 端点映射的类型别名，键是 HTTP 方法，值是 Endpoint
 *
 * @param T 处理器的类型
 */
type Endpoints<T> = HashMap<String, Endpoint<T>>

/**
 * 存储匹配路由数据的路由信息
 *
 * @param T 处理器的类型
 */
public class RouteInfo<T> {
    public RouteInfo(
        public var pattern!: String = "",
        public let patterns!: ArrayList<String> = ArrayList(),
        public let routeParamKeys!: ArrayList<String> = ArrayList(),
        public var routeParamValues!: ArrayList<String> = ArrayList(),
        public let methodsAllowed!: ArrayList<String> = ArrayList(),
        public var methodNotAllowed!: Bool = false,
        public var handler!: ?T = None
    ) {
    }

    /**
     * 获取路由参数映射
     *
     * @return 路由参数的映射
     */
    public func getParams(): HashMap<String, String> {
        let paramMap: HashMap<String, String> = HashMap()
        if (!routeParamKeys.isEmpty()) {
            if (routeParamKeys.size != routeParamValues.size) {
                @JoyLogError("parameter list length mismatch when find route target")
                throw Exception("parameter list length mismatch")
            }
            for (idx in 0..routeParamKeys.size) {
                paramMap[routeParamKeys[idx]] = routeParamValues[idx]
            }
        }
        paramMap
    }
}

/**
 * 路由树的节点类型
 */
type NodeType = Int

const NT_STATIC: NodeType = 0
const NT_REGEXP: NodeType = 1
const NT_PARAM: NodeType = 2
const NT_CATCH_ALL: NodeType = 3

extend NodeType {
    public func str(): String {
        match (this) {
            case 0 => "static"
            case 1 => "regex"
            case 2 => "param"
            case 3 => "catchAll"
            case _ => ""
        }
    }
}

/**
 * 路由匹配的树节点
 */
public class TreeNode<T> {
    // 正则节点的正则匹配器
    var _regex: ?Regex = None

    // 叶子节点上的处理器端点
    var _endpoints: Endpoints<T> = Endpoints()

    // 前缀是我们忽略的公共前缀
    var _prefix: String = ""

    // 子节点应按节点类型的组迭代顺序存储
    var _children: Array<TreeNodes<T>> = Array<TreeNodes<T>>(NT_CATCH_ALL + 1, {_ => TreeNodes<T>()})

    // 节点类型
    var _type: NodeType = 0

    // 前缀的第一个字节
    var _label: Byte = b'\0'
    // 子前缀的第一个字节
    var _tail: Byte = b'\0'

    /**
     * 使用指定的类型、标签、前缀和尾部创建新的树节点
     *
     * @param cat 节点类型（静态、正则、参数、全匹配）
     * @param label 前缀的第一个字节
     * @param prefix 此节点的公共前缀
     * @param tail 子前缀的第一个字节
     */
    init(cat: NodeType, label: Byte, prefix: String, tail!: Byte = b'\0') {
        _type = cat
        _label = label
        _prefix = prefix
        _tail = tail
    }

    /**
     * 使用默认值创建新的静态树节点
     */
    public init() {
        this(NT_STATIC, b'\0', "")
    }

    /**
     * 设置特定 HTTP 方法的端点
     *
     * @param method HTTP 方法
     * @param pattern URL 模式
     * @param handler 路由处理器
     */
    private func setEndpoint(method: String, pattern: String, handler: T) {
        let paramKeys = Segment.parseParamKeys(pattern)
        _endpoints.add(method, Endpoint(handler, pattern, paramKeys))
    }

    /**
     * 用给定的标签和尾部替换子节点
     *
     * @param label 要替换的子节点的标签字节
     * @param tail 要替换的子节点的尾部字节
     * @param child 新的子节点
     * @throws IllegalStateException 如果未找到要替换的子节点
     */
    private func replaceChild(label: Byte, tail: Byte, child: TreeNode<T>) {
        let ns = _children[child._type]
        for (i in 0..ns.size) {
            if (ns[i]._label == label && ns[i]._tail == tail) {
                ns[i] = child
                ns[i]._label = label
                ns[i]._tail = tail
                return
            }
        }
        throw IllegalStateException("replace missing child")
    }

    /**
     * 将具有给定前缀的子节点添加到此节点
     *
     * @param child 要添加的子节点
     * @param prefix 子节点的前缀
     * @return 添加的子节点
     */
    private func addChild(child: TreeNode<T>, prefix: String): TreeNode<T> {
        var search = prefix
        var hn = child

        // 解析下一个段
        let seg = Segment.parseNext(search)
        if (seg.typ == NT_REGEXP) {
            child._prefix = seg.rex
            child._regex = Regex(seg.rex)
        }

        if (seg.typ != NT_STATIC) {
            if (seg.startPos == 0) {
                // route starts with a param
                child._type = seg.typ
                var segStartIdx = if (seg.typ == NT_CATCH_ALL) {
                    seg.startPos - 1
                } else {
                    seg.endPos
                }
                if (segStartIdx < 0) {
                    segStartIdx = search.size
                }

                child._tail = seg.tail
                if (segStartIdx != search.size) {
                    search = search[segStartIdx..search.size]
                    let nn = TreeNode<T>(NT_STATIC, search[0], search)
                    hn = child.addChild(nn, search)
                }
            } else if (seg.startPos > 0) {
                // route has some param
                // starts with a static segment
                child._type = NT_STATIC
                child._prefix = search[0..seg.startPos]
                // add the param edge node
                search = search[seg.startPos..search.size]
                let nn = TreeNode<T>(seg.typ, search[0], "", tail: seg.tail)
                hn = child.addChild(nn, search)
            }
        }

        _children[child._type].add(child)
        _children[child._type].sortByLableTail()
        hn
    }

    /**
     * 向树中添加路由
     *
     * @param method HTTP 方法（GET、POST 等）
     * @param pattern URL 模式（例如："/users/{id}"）
     * @param handler 路由处理器
     * @return 树节点
     */
    public func addRoute(method: String, pattern: String, handler: T): TreeNode<T> {
        var parent = this
        var node = this
        var search = pattern
        while (true) {
            if (search.isEmpty()) {
                node.setEndpoint(method, pattern, handler)
                return node
            }

            var label = search[0]
            let seg = if (label == b'{' || label == b'*') {
                Segment.parseNext(search)
            } else {
                Segment()
            }

            var prefix = if (seg.typ == NT_REGEXP) {
                seg.rex
            } else {
                ""
            }

            parent = node
            let edge = node.getEdge(seg.typ, label, seg.tail, prefix)
            if (edge.isNone()) {
                let child = TreeNode<T>(NT_STATIC, label, search, tail: seg.tail)
                let hn = parent.addChild(child, search)
                hn.setEndpoint(method, pattern, handler)
                return hn
            } else {
                node = edge.getOrThrow()
            }

            // found an edge to match the pattern
            if (node._type > NT_STATIC) {
                search = search[seg.endPos..search.size]
                continue
            }

            // static node
            let nprefix = longestPrefix(search, node._prefix)
            if (nprefix == node._prefix.size) {
                search = search[nprefix..search.size]
                continue
            }

            let child = TreeNode<T>(NT_STATIC, search[0], search[0..nprefix])
            parent.replaceChild(search[0], seg.tail, child)

            // restorethe existing node 
            node._label = node._prefix[nprefix]
            node._prefix = node._prefix[nprefix..node._prefix.size]
            child.addChild(node, node._prefix)

            search = search[nprefix..search.size]
            if (search.isEmpty()) {
                child.setEndpoint(method, pattern, handler)
                return child
            }

            // create a new edge for the node
            let schild = TreeNode<T>(NT_STATIC, search[0], search)
            let hn = child.addChild(schild, search)
            hn.setEndpoint(method, pattern, handler)
            return hn
        }

        throw IllegalStateException("can not run to this line")
    }

    /**
     * 在给定的树节点中查找静态路由
     *
     * @param nds 要搜索的树节点
     * @param search 搜索路径
     * @param label 要匹配的标签字节
     * @return （找到的节点，剩余搜索路径）的元组
     */
    private func findStaticRoute(nds: ArrayList<TreeNode<T>>, search: String, label: Byte): (?TreeNode<T>, String) {
        let en = nds.findEdge(label)
        if (let Some(n) <- en) {
            if (!search.startsWith(n._prefix)) {
                return (None, "")
            }
            return (en, search[n._prefix.size..search.size])
        }
        return (None, "")
    }

    /**
     * 在给定的树节点中查找参数或正则路由
     *
     * @param ri 用于存储匹配数据的路由信息
     * @param nds 要搜索的树节点
     * @param nt 要搜索的节点类型
     * @param search 搜索路径
     * @param method HTTP 方法
     * @return （找到的节点，剩余搜索路径，是否匹配）的元组
     */
    private func findParamOrRegexRoute(ri: RouteInfo<T>, nds: ArrayList<TreeNode<T>>, nt: NodeType, search: String,
        method: String): (?TreeNode<T>, String, Bool) {
        var xsearch = search
        var ret: ?TreeNode<T> = None
        // 逐个遍历按尾部分组的节点
        for (n in nds) {
            let xn = n
            ret = n

            // label for param nodes is the delimiter byte
            var p = xsearch.indexOf(xn._tail) ?? -1
            if (p < 0) {
                if (xn._tail == b'/') {
                    p = xsearch.size
                } else {
                    continue
                }
            } else if (nt == NT_REGEXP && p == 0) {
                continue
            }

            if (let Some(re) <- xn._regex && nt == NT_REGEXP) {
                if (!re.matches(xsearch[0..p])) {
                    continue
                }
            } else if (xsearch[0..p].indexOf(b'/').isSome()) {
                // avoid a match across path segments
                continue
            }

            let prevlen = ri.routeParamValues.size
            ri.routeParamValues.add(search[0..p])
            var xsearch = xsearch[p..xsearch.size]

            let fin = findRouteByMethod(ri, xn, method, xsearch)
            if (fin.isSome()) {
                return (fin, xsearch, true)
            }

            // not found on this branch, reset vars
            ri.routeParamValues = ri.routeParamValues[0..prevlen]
            xsearch = search
        }

        ri.routeParamValues.add("")
        return (ret, xsearch, false)
    }

    /**
     * 在给定的树节点中按方法查找路由处理器
     *
     * @param ri 用于存储匹配数据的路由信息
     * @param xn 要搜索的树节点
     * @param method HTTP 方法
     * @param search 剩余的搜索路径
     * @return 找到的树节点，如果未找到则返回 None
     */
    private func findRouteByMethod(ri: RouteInfo<T>, xn: TreeNode<T>, method: String, search: String): ?TreeNode<T> {
        if (search.isEmpty() && xn.isLeaf()) {
            let epOpt = xn._endpoints.get(method)
            if (let Some(ep) <- epOpt) {
                ri.routeParamKeys.add(all: ep.paramKeys)
                return xn
            }

            ri.methodsAllowed.add(all: xn._endpoints.keys())
            // 标记：路由上下文已找到路由，但未找到相应的受支持的方法
            ri.methodNotAllowed = true
        }

        // recursively find the next node on this branch
        xn.findRoute(ri, method, search)
    }

    /**
     * 在树中按方法和路径查找路由处理器
     *
     * @param ri 用于存储匹配数据的路由信息
     * @param method HTTP 方法
     * @param path 要搜索的 URL 路径
     * @return 找到的树节点，如果未找到则返回 None
     */
    func findRoute(ri: RouteInfo<T>, method: String, path: String): ?TreeNode<T> {
        var search = path
        let label = if (search != "") {
            search[0]
        } else {
            b'\0'
        }

        for (idx in 0.._children.size) {
            let nt: NodeType = idx
            var node: ?TreeNode<T> = None
            let nds = _children[idx]
            if (nds.isEmpty()) {
                continue
            }

            var xsearch = search
            if (nt == NT_STATIC) {
                (node, xsearch) = findStaticRoute(nds, search, label)
                if (node.isNone()) {
                    continue
                }
            } else if (nt == NT_PARAM || nt == NT_REGEXP) {
                if (xsearch == "") {
                    continue
                }
                var ret = false
                (node, xsearch, ret) = findParamOrRegexRoute(ri, nds, nt, search, method)
                if (node.isSome() && ret) {
                    return node
                }
            } else {
                ri.routeParamValues.add(search)
                node = nds[0]
                xsearch = ""
            }

            if (node.isNone()) {
                continue
            }

            let tnode = node.getOrThrow()
            let fin = findRouteByMethod(ri, tnode, method, xsearch)
            if (fin.isSome()) {
                return fin
            }

            // 未找到最终处理程序，如果已设置路由参数，在此处将其移除
            if (tnode._type > NT_STATIC) {
                if (!ri.routeParamValues.isEmpty()) {
                    ri.routeParamValues = ri.routeParamValues[0..(ri.routeParamValues.size - 1)]
                }
            }
        }
        None
    }

    /**
     * 按方法和路径查找路由处理器
     *
     * @param ri 用于存储匹配路由数据的路由信息
     * @param method HTTP 方法
     * @param path URL 路径
     * @return 如果找到返回树节点，否则返回 None
     */
    public func findRouteHandler(ri: RouteInfo<T>, method: String, path: String): ?TreeNode<T> {
        let rn = findRoute(ri, method, path)
        if (let Some(node) <- rn) {
            let ep = node._endpoints[method]
            if (ep.pattern != "") {
                ri.pattern = ep.pattern
                ri.patterns.add(ri.pattern)
            }
            ri.handler = ep.handler
        }
        rn
    }

    /**
     * 检查树是否包含具有给定模式的路由
     *
     * @param pattern 要检查的路由模式
     * @return 如果模式存在返回 True，否则返回 False
     */
    func findPattern(pattern: String): Bool {
        for (nds in _children) {
            if (nds.isEmpty()) {
                continue
            }

            let edge = findEdge(nds[0]._type, pattern[0])
            if (edge.isNone()) {
                continue
            }
            let node = edge.getOrThrow()

            var idx = 0
            if (node._type == NT_STATIC) {
                idx = longestPrefix(pattern, node._prefix)
                if (idx < node._prefix.size) {
                    continue
                }
            } else if (node._type == NT_PARAM || node._type == NT_REGEXP) {
                idx = (pattern.lastIndexOf(b'}') ?? -1) + 1
            } else if (node._type == NT_CATCH_ALL) {
                idx = longestPrefix(pattern, "*")
            }

            let xpattern = pattern[idx..pattern.size]
            if (xpattern.isEmpty()) {
                return true
            }
            return node.findPattern(xpattern)
        }

        false
    }

    /**
     * 按类型和标签在子节点中查找边
     *
     * @param ntype 要搜索的节点类型
     * @param label 要搜索的标签字节
     * @return 找到的树节点，如果未找到则返回 None
     */
    private func findEdge(ntype: NodeType, label: Byte): ?TreeNode<T> {
        let nds = _children[ntype]
        return if (ntype == NT_CATCH_ALL) {
            nds[0]
        } else {
            nds.findEdge(label)
        }
    }

    /**
     * 检查节点是否为叶子节点（有端点）
     *
     * @return 如果节点是叶子返回 True，否则返回 False
     */
    private func isLeaf(): Bool {
        return !_endpoints.isEmpty()
    }

    /**
     * 按类型、标签、尾部和前缀从子节点中获取边
     *
     * @param nt 要搜索的节点类型
     * @param label 要搜索的标签字节
     * @param tail 要搜索的尾部字节
     * @param prefix 要匹配的前缀（用于正则节点）
     * @return 找到的树节点，如果未找到则返回 None
     */
    private func getEdge(nt: NodeType, label: Byte, tail: Byte, prefix: String): ?TreeNode<T> {
        let nds = _children[nt]
        for (node in nds) {
            if (node._label == label && node._tail == tail) {
                if (nt == NT_REGEXP && node._prefix != prefix) {
                    continue
                }
                return node
            }
        }
        None
    }

    /**
     * 递归将树结构转储到字符串构建器
     *
     * @param builder 要写入的字符串构建器
     * @param layer 树中的当前层/深度
     * @param prefix 用于缩进的前缀字符串
     * @param node 要转储的当前树节点
     */
    private static func dumpTreeInner(builder: StringBuilder, layer: Int, prefix: String, node: TreeNode<T>): Unit {
        var num = 0
        for (nds in node._children) {
            num += nds.size
        }

        builder.append("${prefix}${layer}")
        builder.append(",type:${node._type.str()}")
        builder.append(",prefix:${node._prefix}")
        builder.append(",label:${String.fromUtf8([node._label])}")
        builder.append(",tail:${String.fromUtf8([node._tail])}")
        builder.append(",numEdges:${num}")
        builder.append(",isLeaf:${node.isLeaf()}")
        if (!node._endpoints.isEmpty()) {
            builder.append(",endpoints:{${node._endpoints.keys().toArray()} ${node._endpoints.values().toArray()[0]}}")
        }
        builder.append("\n")

        for (nds in node._children) {
            let prefixStr = prefix + "  "
            for (node in nds) {
                dumpTreeInner(builder, layer + 1, prefixStr, node)
            }
        }
    }

    /**
     * 将树结构转储为字符串用于调试
     *
     * @return 树结构字符串
     */
    public func dumpTree(): String {
        let builder = StringBuilder()
        dumpTreeInner(builder, 0, "", this)
        builder.toString()
    }

    /**
     * 查找两个字符串之间最长公共前缀的长度
     *
     * @param s1 要比较的第一个字符串
     * @param s2 要比较的第二个字符串
     * @return 最长公共前缀的长度
     */
    private static func longestPrefix(s1: String, s2: String): Int {
        let len = min(s1.size, s2.size)
        var idx = 0
        for (i in 0..len) {
            if (s1[i] != s2[i]) {
                break
            } else {
                idx += 1
            }
        }
        idx
    }
}

/**
 * 树节点列表的类型别名
 *
 * @param T 处理器的类型
 */
type TreeNodes<T> = ArrayList<TreeNode<T>>

/**
 * TreeNodes 的扩展函数
 *
 * @param T 处理器的类型
 */
extend<T> TreeNodes<T> {
    /**
     * 按标签和尾部分隔符对树节点进行排序
     * 静态节点按标签排序
     * 带有 '/' 尾部的参数节点被推到列表末尾
     */
    func sortByLableTail() {
        // 根据标签对节点列表进行排序
        sort(this, by: {a, b => a._label.compare(b._label)})
        // 将尾部为 '/' 的参数节点推到列表末尾
        let last = this.size - 1
        for (i in last..=0 : -1) {
            if (this[i]._type > NT_STATIC && this[i]._tail == b'/') {
                (this[i], this[last]) = (this[last], this[i])
                return
            }
        }
    }

    /**
     * 使用二分查找按标签在树节点列表中查找边
     *
     * @param label 要搜索的标签字节
     * @return 找到的树节点，如果未找到则返回 None
     */
    func findEdge(label: Byte): ?TreeNode<T> {
        let num = this.size
        var idx = 0
        var i = 0
        var j = num - 1
        while (i <= j) {
            idx = i + (j - i) / 2
            if (label > this[idx]._label) {
                i = idx + 1
            } else if (label < this[idx]._label) {
                j = idx - 1
            } else {
                // 退出 while 循环
                i = num
            }
        }

        if (this[idx]._label != label) {
            None
        } else {
            this[idx]
        }
    }
}

/**
 * 表示路由模式的段，用于解析和匹配路由
 */
private class Segment {
    var typ: NodeType = NT_STATIC
    var key: String = ""
    var rex: String = ""
    var tail: Byte = b'\0'
    var startPos: Int = 0
    var endPos: Int = 0

    private static func normRexpat(rexpat: String): String {
        if (rexpat.isEmpty()) {
            return rexpat
        }

        var ret = rexpat
        if (rexpat[0] != b'^') {
            ret = "^" + ret
        }
        if (ret[ret.size - 1] != b'$') {
            ret = ret + "$"
        }
        return ret
    }

    /**
     * @throws IllegalArgumentException 如果缺少关闭分隔符 '}'
     */
    private static func findEndIdx(pattern: String, ps: Int): Int {
        // 读取到关闭的 }，考虑到在大括号计数 (cc) 中的打开和关闭
        var cc = 0
        var pe = ps

        let xpat = pattern[ps..pattern.size]
        for (i in 0..xpat.size) {
            if (xpat[i] == b'{') {
                cc += 1
            } else if (xpat[i] == b'}') {
                cc -= 1
                if (cc == 0) {
                    pe = ps + i
                    return pe
                }
            }
        }

        if (pe == ps) {
            throw IllegalArgumentException("route param closing delimiter '}' is missing")
        }
        pe
    }

    /**
     * 从给定模式解析下一个段
     *
     * @param pattern 要解析的路由模式
     * @return 解析的段
     * @throws IllegalArgumentException 如果模式无效
     */
    static func parseNext(pattern: String): Segment {
        let seg = Segment()
        seg.parse(pattern)
        seg
    }

    /**
     * 从给定模式解析段
     *
     * @param pattern 要解析的路由模式
     * @throws IllegalArgumentException 如果模式无效
     */
    private func parse(pattern: String): Unit {
        let ps = pattern.indexOf(b'{') ?? -1
        let ws = pattern.indexOf(b'*') ?? -1
        let len = pattern.size

        if (ps < 0 && ws < 0) {
            endPos = len
            return
        }

        if (ps >= 0 && ws >= 0 && ws < ps) {
            throw IllegalArgumentException("wildcard '*' must be the last pattern in a route, otherwise use a '{param}")
        }

        if (ps < 0) {
            if (ws < len - 1) {
                throw IllegalArgumentException(
                    "wildcard '*' must be the last value in a route. trim trailing text or use a '{param}' instead")
            }
            typ = NT_CATCH_ALL
            key = "*"
            startPos = ws
            endPos = len
            return
        }

        typ = NT_PARAM
        tail = b'/'
        startPos = ps
        endPos = findEndIdx(pattern, ps)
        key = pattern[(ps + 1)..endPos]
        endPos += 1
        if (endPos < len) {
            tail = pattern[endPos]
        }

        if (let idx <- key.indexOf(b':') && idx.isSome()) {
            typ = NT_REGEXP
            let idx_ = idx.getOrThrow()
            rex = key[(idx_ + 1)..key.size]
            key = key[0..idx_]
        }

        if (key == "") {
            throw IllegalArgumentException("param can't is {}")
        }

        rex = normRexpat(rex)
    }

    /**
     * 从路由模式解析参数键
     *
     * @param pattern 要解析的路由模式
     * @return 参数键数组
     * @throws IllegalArgumentException 如果模式包含重复参数键或无效
     */
    static func parseParamKeys(pattern: String): Array<String> {
        var pat = pattern
        var paramKeys = ArrayList<String>()
        while (true) {
            let seg = Segment.parseNext(pat)
            if (seg.typ == NT_STATIC) {
                return paramKeys.toArray()
            }
            if (paramKeys.contains(seg.key)) {
                throw IllegalArgumentException(
                    "routing pattern '${pattern}' contains duplicate param key, '${seg.key}'")
            }
            paramKeys.add(seg.key)
            pat = pat[seg.endPos..pat.size]
        }
        paramKeys.toArray()
    }
}
