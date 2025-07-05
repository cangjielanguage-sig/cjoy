/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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
import std.collection.{ArrayList, HashMap, forEach}
import cjoy.log.LogTool

class Endpoint<T> <: ToString {
    Endpoint(let handler: T, let pattern: String, let paramKeys: Array<String>) {
    }

    public func toString(): String {
        return "Endpoint[pattern:${pattern},paramKeys:${paramKeys}]"
    }
}

type Endpoints<T> = HashMap<String, Endpoint<T>>

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

    public func getParams(): HashMap<String, String> {
        let paramMap: HashMap<String, String> = HashMap()
        if (!routeParamKeys.isEmpty()) {
            if (routeParamKeys.size != routeParamValues.size) {
                LogTool.error("parameter list length mismatch when find route target")
                throw Exception("parameter list length mismatch")
            }
            for (idx in 0..routeParamKeys.size) {
                paramMap[routeParamKeys[idx]] = routeParamValues[idx]
            }
        }
        paramMap
    }
}

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

public class TreeNode<T> {
    // regex matcher for regexp nodes
    var _regex: ?Regex = None

    // handler endpoints on the leaf node
    var _endpoints: Endpoints<T> = Endpoints()

    // prefix is the common prefix we ignore
    var _prefix: String = ""

    // child nodes should be stored in-order for iteration in groups of the node type.
    var _children: Array<TreeNodes<T>> = Array<TreeNodes<T>>(NT_CATCH_ALL + 1, {_ => TreeNodes<T>()})

    // node type
    var _type: NodeType = 0

    // first byte of the prefix
    var _label: Byte = b'\0'
    // first byte of the child prefix
    var _tail: Byte = b'\0'

    init(cat: NodeType, label: Byte, prefix: String, tail!: Byte = b'\0') {
        _type = cat
        _label = label
        _prefix = prefix
        _tail = tail
    }

    public init() {
        this(NT_STATIC, b'\0', "")
    }

    private func setEndpoint(method: String, pattern: String, handler: T) {
        let paramKeys = Segment.parseParamKeys(pattern)
        _endpoints.add(method, Endpoint(handler, pattern, paramKeys))
    }

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

    private func addChild(child: TreeNode<T>, prefix: String): TreeNode<T> {
        var search = prefix
        var hn = child

        // parse next segment
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

    private func findParamOrRegexRoute(ri: RouteInfo<T>, nds: ArrayList<TreeNode<T>>, nt: NodeType, search: String,
        method: String): (?TreeNode<T>, String, Bool) {
        var xsearch = search
        var ret: ?TreeNode<T> = None
        // serially loop through each node grouped by the tail delimiter
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

    private func findRouteByMethod(ri: RouteInfo<T>, xn: TreeNode<T>, method: String, search: String): ?TreeNode<T> {
        if (search.isEmpty() && xn.isLeaf()) {
            let epOpt = xn._endpoints.get(method)
            if (let Some(ep) <- epOpt) {
                ri.routeParamKeys.add(all: ep.paramKeys)
                return xn
            }

            ri.methodsAllowed.add(all: xn._endpoints.keys())
            // flag that the routing context found a route, but not a corresponding supported method
            ri.methodNotAllowed = true
        }

        // recursively find the next node on this branch
        xn.findRoute(ri, method, search)
    }

    func findRoute(ri: RouteInfo<T>, method: String, path: String): ?TreeNode<T> {
        var search = path
        var label = if (search != "") {
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

            // did not find final handler, let's remove the param here if it was set
            if (tnode._type > NT_STATIC) {
                if (!ri.routeParamValues.isEmpty()) {
                    ri.routeParamValues = ri.routeParamValues[0..(ri.routeParamValues.size - 1)]
                }
            }
        }
        None
    }

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

    private func findEdge(ntype: NodeType, label: Byte): ?TreeNode<T> {
        let nds = _children[ntype]
        return if (ntype == NT_CATCH_ALL) {
            nds[0]
        } else {
            nds.findEdge(label)
        }
    }

    private func isLeaf(): Bool {
        return !_endpoints.isEmpty()
    }

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
            builder.append(",endpoints:${node._endpoints}")
        }
        builder.append("\n")

        for (nds in node._children) {
            let prefixStr = prefix + "  "
            for (node in nds) {
                dumpTreeInner(builder, layer + 1, prefixStr, node)
            }
        }
    }

    public func dumpTree(): String {
        let builder = StringBuilder()
        dumpTreeInner(builder, 0, "", this)
        builder.toString()
    }

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

type TreeNodes<T> = ArrayList<TreeNode<T>>

extend<T> TreeNodes<T> {
    func sortByLableTail() {
        // sort the list of nodes by label
        sort(this, by: {a, b => a._label.compare(b._label)})
        // pushes nodes with '/' as the tail to the end of the list for param nodes.
        let last = this.size - 1
        for (i in last..=0 : -1) {
            if (this[i]._type > NT_STATIC && this[i]._tail == b'/') {
                (this[i], this[last]) = (this[last], this[i])
                return
            }
        }
    }

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
                // break the while loop
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

class Segment {
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

    private static func findEndIdx(pattern: String, ps: Int): Int {
        // read to closing } taking into account opens and closes in curl count (cc)
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

    static func parseNext(pattern: String): Segment {
        let seg = Segment()
        seg.parse(pattern)
        seg
    }

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

        rex = normRexpat(rex)
    }

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
