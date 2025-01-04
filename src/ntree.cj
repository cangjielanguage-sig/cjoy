/*
 * Copyright (c) lanlingx 2024-2025. All rights resvered.
 */

package cjoy

import std.regex.Regex
import std.collection.*

class Endpoint<T> {
    let handler: T
    let pattern: String
    let paramKeys: Array<String>
    init(handler: T, pattern: String, paramKeys: Array<String>) {
        this.handler = handler
        this.pattern = pattern
        this.paramKeys = paramKeys
    }
}

type Endpoints<T> = HashMap<String, Endpoint<T>>

extend<T> Endpoints<T> {
    func computeIfAbsent(method: String, initFunc: ?(() -> Endpoint<T>)): Endpoint<T> {
        let v = this.get(method)
        match (v) {
            case Some(val) => val
            case _ =>
                let val = initFunc.getOrThrow()()
                this[method] = val
                val
        }
    }
}

class RouteInfo {
    public RouteInfo(
        let pattern!: String = "",
        let patterns!: ArrayList<String> = ArrayList(),
        let routeParamKeys!: ArrayList<String> = ArrayList(),
        var routeParamValues!: ArrayList<String> = ArrayList(),
        let methodsAllowed!: ArrayList<String> = ArrayList(),
        var methodNotAllowed!: Bool = false
    ) {
    }
}

type NodeTyp = Int

class TreeNode<T> {
    static const NT_STATIC: NodeTyp = 0
    static const NT_REGEXP: NodeTyp = 1
    static const NT_PARAM: NodeTyp = 2
    static const NT_CATCH_ALL: NodeTyp = 3

    // Regex matcher for regexp nodes
    var _regex: ?Regex = None

    // handler endpoints on the leaf node
    var _endpoints: Endpoints<T> = Endpoints()

    // prefix is the common prefix we ignore
    var _prefix: String = ""

    // child nodes should be stored in-order for iteration in groups of the node type.
    var _children: Array<TreeNodes<T>> = Array<TreeNodes<T>>(NT_CATCH_ALL + 1, {_ => TreeNodes<T>()})

    // node type
    var _type: NodeTyp = 0

    // first byte of the prefix
    var _label: Byte = b'\0'
    // first byte of the child prefix
    var _tail: Byte = b'\0'

    init(cat: NodeTyp, label: Byte, prefix: String) {
        _type = cat
        _label = label
        _prefix = prefix
    }

    init(cat: NodeTyp, label: Byte, tail: Byte) {
        _type = cat
        _label = label
        _tail = tail
    }

    private func setEndpoint(method: String, pattern: String, handler: T) {
        let paramKeys = parseParamKeys(pattern)
        _endpoints.computeIfAbsent(method, {=> Endpoint(handler, pattern, paramKeys)})
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
    }

    private func addChild(child: TreeNode<T>, prefix: String): TreeNode<T> {
        var search = prefix
        var hn = child
        var (segCat, _, segRexpat, segTail, segStartIdx, segEndIdx) = parseNexSegment(search)

        if (segCat == NT_REGEXP) {
            child._prefix = segRexpat
            child._regex = Regex(segRexpat)
        }

        if (segCat != NT_STATIC) {
            if (segStartIdx == 0) {
                // route starts with a param
                child._type = segCat
                segStartIdx = if (segCat == NT_CATCH_ALL) {
                    segStartIdx - 1
                } else {
                    segEndIdx
                }
                if (segStartIdx < 0) {
                    segStartIdx = search.size
                }

                child._tail = segTail
                if (segStartIdx != search.size) {
                    search = search[segStartIdx..search.size]
                    let nn = TreeNode<T>(NT_STATIC, search[0], search)
                    hn = child.addChild(nn, search)
                }
            } else if (segStartIdx > 0) {
                // route has some param
                // starts with a static segment
                child._type = NT_STATIC
                child._prefix = search[0..segStartIdx]
                // add the param edge node
                search = search[segStartIdx..search.size]
                let nn = TreeNode<T>(segCat, search[0], segTail)
                hn = child.addChild(nn, search)
            }
        }

        _children[child._type].append(child)
        _children[child._type].sortByLableTail()
        hn
    }

    func addRoute(method: String, pattern: String, handler: T): TreeNode<T> {
        var parent = this
        var current = this
        var search = pattern
        while (true) {
            println("${search}")
            if (search.size == 0) {
                setEndpoint(method, pattern, handler)
                return this
            }

            var label = search[0]
            var (segCat, _, segRexpat, segTail, _, segEndIdx) = if (label == b'{' || label == b'*') {
                parseNexSegment(search)
            } else {
                (NT_STATIC, "", "", b'\0', 0, 0)
            }

            var prefix = if (segCat == NT_REGEXP) {
                segRexpat
            } else {
                ""
            }

            parent = current
            let edge = current.getEdge(segCat, label, segTail, prefix)
            if (edge.isNone()) {
                let child = TreeNode<T>(segCat, label, search)
                child._tail = segTail
                let hn = parent.addChild(child, search)
                hn.setEndpoint(method, pattern, handler)
                return hn
            }

            current = edge.getOrThrow()
            if (current._type > NT_STATIC) {
                search = search[segEndIdx..search.size]
                continue
            }

            let nprefix = longestPrefix(search, current._prefix)
            if (nprefix == current._prefix.size) {
                search = search[nprefix..search.size]
                continue
            }

            let child = TreeNode<T>(NT_STATIC, search[0], search[0..nprefix])
            parent.replaceChild(search[0], segTail, child)

            // restorethe existing node 
            current._label = current._prefix[nprefix]
            current._prefix = current._prefix[nprefix..current._prefix.size]
            child.addChild(current, current._prefix)

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

        unsafe { zeroValue<TreeNode<T>>() }
    }

    private func findStaticRoute(nds: ArrayList<TreeNode<T>>, xsearch: String, label: Byte): (?TreeNode<T>, String) {
        let en = nds.findEdge(label)
        if (en.isNone()) {
            return (None, "")
        }

        let n = en.getOrThrow()
        if (!xsearch.startsWith(n._prefix)) {
            return (None, "")
        }

        (en, xsearch[n._prefix.size..xsearch.size])
    }

    private func findParamOrRegexRoute(ri: RouteInfo, nds: ArrayList<TreeNode<T>>, nt: NodeTyp, search: String,
        method: String): (?TreeNode<T>, String) {
        var xsearch = search

        // serially loop through each node grouped by the tail delimiter
        for (n in nds) {
            let xn = n

            // label for param nodes is the delimiter byte
            var p = xsearch.indexOf(xn._tail).getOrDefault({=> -1})
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
                if (re.matches(xsearch[0..p]).isNone()) {
                    continue
                }
            } else if (xsearch[0..p].indexOf(b'/').isSome()) {
                // avoid a match across path segments
                continue
            }

            let prevlen = ri.routeParamValues.size
            ri.routeParamValues.append(search[0..p])
            var xsearch = xsearch[p..xsearch.size]

            let fin = findRouteByMethod(ri, xn, method, xsearch)
            if (fin.isSome()) {
                return (fin, xsearch)
            }

            // not found on this branch, reset vars
            ri.routeParamValues = ri.routeParamValues[0..prevlen]
            xsearch = search
        }

        return (None, xsearch)
    }

    private func findRouteByMethod(ri: RouteInfo, xn: TreeNode<T>, method: String, search: String): ?TreeNode<T> {
        if (search.isEmpty() && xn.isLeaf()) {
            let epOpt = xn._endpoints.get(method)
            if (let Some(ep) <- epOpt) {
                ri.routeParamKeys.appendAll(ep.paramKeys)
                return xn
            }

            ri.methodsAllowed.appendAll(xn._endpoints.keys())
            // flag that the routing context found a route, but not a corresponding supported method
            ri.methodNotAllowed = true
        }

        // recursively find the next node on this branch
        let fin = xn.findRoute(ri, method, search)
        fin
    }

    func findRoute(ri: RouteInfo, method: String, path: String): ?TreeNode<T> {
        var xn: ?TreeNode<T> = None
        var search = path
        var label = if (search != "") {
            search[0]
        } else {
            b'\0'
        }

        for (idx in 0.._children.size) {
            let nt: NodeTyp = idx
            let nds = _children[idx]
            if (nds.isEmpty()) {
                continue
            }

            var xsearch = search
            if (nt == NT_STATIC) {
                (xn, xsearch) = findStaticRoute(nds, search, label)
                if (xn.isSome()) {
                    return xn
                }
            } else if (nt == NT_PARAM || nt == NT_REGEXP) {
                if (search == "") {
                    continue
                }
                (xn, xsearch) = findParamOrRegexRoute(ri, nds, nt, search, method)
                if (xn.isSome()) {
                    return xn
                }
            } else {
                ri.routeParamValues.append(search)
                xn = nds[0]
                xsearch = ""
            }

            if (xn.isNone()) {
                continue
            }

            let fin = findRouteByMethod(ri, xn.getOrThrow(), method, xsearch)
            if (fin.isSome()) {
                return fin
            }

            // did not find final handler, let's remove the param here if it was set
            if (xn.getOrThrow()._type > NT_STATIC) {
                if (!ri.routeParamValues.isEmpty()) {
                    ri.routeParamValues = ri.routeParamValues[0..(ri.routeParamValues.size - 1)]
                }
            }
        }
        xn
    }

    private func isLeaf(): Bool {
        return !_endpoints.isEmpty()
    }

    private func getEdge(nt: NodeTyp, label: Byte, tail: Byte, prefix: String): ?TreeNode<T> {
        let ns = _children[nt]
        let node = ns |>
            filter {
            it: TreeNode<T> =>
            if (it._label == label && it._tail == tail) {
                if (nt == NT_REGEXP && it._prefix != prefix) {
                    return false
                }
                return true
            }
            return false
        } |> first
        node
    }

    private static func longestPrefix(s1: String, s2: String): Int {
        let maxLen = min(s1.size, s2.size)
        var idx = 0
        for (i in 0..maxLen) {
            if (s1[i] != s2[i]) {
                return i
            }
        }
        idx
    }

    private static func parseNexSegment(pattern: String): (NodeTyp, String, String, Byte, Int, Int) {
        let ps = pattern.indexOf(b'{').getOrDefault({=> -1})
        let ws = pattern.indexOf(b'*').getOrDefault({=> -1})
        let pl = pattern.size
        if (ps < 0 && ws < 0) {
            return (NT_STATIC, "", "", 0, 0, pl)
        }
        if (ps >= 0 && ws >= 0 && ws < ps) {
            throw IllegalArgumentException("wildcard '*' must be the last pattern in a route, otherwise use a '{param}")
        }

        if (ps < 0) {
            if (ws < pl - 1) {
                throw IllegalArgumentException(
                    "wildcard '*' must be the last value in a route. trim trailing text or use a '{param}' instead")
            }
            return (NT_CATCH_ALL, "*", "", 0, ws, pl)
        }

        var tail = b'/'
        var nt = NT_PARAM
        var cc = 0
        var pe = ps
        let xpat = pattern[ps..pl]
        for (i in 0..xpat.size) {
            if (xpat[i] == b'{') {
                cc += 1
            } else if (xpat[i] == b'}') {
                cc -= 1
                if (cc == 0) {
                    pe = ps + i
                    break
                }
            }
        }
        if (pe == ps) {
            throw IllegalArgumentException("route param closing delimiter '}' is missing")
        }

        var key = pattern[(ps + 1)..pe]
        pe += 1
        if (pe < pl) {
            tail = pattern[pe]
        }

        var rexpat = ""
        if (let idx <- key.indexOf(b':') && idx.isSome()) {
            nt = NT_REGEXP
            let idx_ = idx.getOrThrow()
            rexpat = key[(idx_ + 1)..key.size]
            key = key[0..idx_]
        }

        if (rexpat.size > 0) {
            if (rexpat[0] != b'^') {
                rexpat = "^" + rexpat
            }
            if (rexpat[rexpat.size - 1] != b'$') {
                rexpat += "$"
            }
        }
        return (nt, key, rexpat, tail, ps, pe)
    }

    private func parseParamKeys(pattern: String): Array<String> {
        var pat = pattern
        var paramKeys = ArrayList<String>()
        while (true) {
            let (nt, paramKey, _, _, _, pe) = parseNexSegment(pat)
            if (nt == NT_STATIC) {
                return paramKeys.toArray()
            }
            if (paramKeys.contains(paramKey)) {
                throw IllegalArgumentException(
                    "routing pattern '${pattern}' contains duplicate param key, '${paramKey}'")
            }
            paramKeys.append(paramKey)
            pat = pat[pe..pat.size]
        }
        paramKeys.toArray()
    }
}

type TreeNodes<T> = ArrayList<TreeNode<T>>

extend<T> TreeNodes<T> {
    func sortByLableTail() {
        this.sortBy(comparator: {a, b => a._label.compare(b._label)})
        this.sortBy(comparator: {
            a, _ => if (a._type > 0 && a._tail == b'/') {
                Ordering.GT
            } else {
                Ordering.EQ
            }
        })
    }

    func findEdge(label: Byte): ?TreeNode<T> {
        let num = this.size
        var idx = 0
        var i = 0
        var j = num - 1
        while (i <= j) {
            idx = (i + (j - i) / 2)
            if (label > this[idx]._label) {
                i = idx + 1
            } else if (label < this[idx]._label) {
                i = idx - 1
            } else {
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
