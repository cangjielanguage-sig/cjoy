/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy

import std.collection.{ArrayList, HashMap, forEach}
import std.deriving.*

@Derive[Comparable]
enum NodeType {
    STATIC | WILDCARD | CATCH_ALL
}

class Node<T> {
    private static let HANDLER_VALID_FUNC: (T) -> Bool = { _=> true }

    var _path: String = ""
    var _fullPath: String = ""
    var _nodeType: NodeType = STATIC
    
    var _priority: Int32 = 0
    var _addSlash: Bool = false
    
    var _staticIndices: ArrayList<Byte> = ArrayList()
    var _staticChild: ArrayList<Node<T>> = ArrayList()

    var _wildcardChild: Option<Node<T>> = None

    var _catchAllChild: Option<Node<T>> = None
    var _implicitHead: Bool = false

    var _leafHandlers: HashMap<String, T> = HashMap()
    var _leafParamNames: ArrayList<String> = ArrayList()

    init(path: String, nodeType: NodeType) {
        _path = path
        _nodeType = nodeType
    }

    func isCatchAll(): Bool {
        _nodeType == NodeType.CATCH_ALL
    }

    private func sortStaticChild(idx: Int64): Unit {
        var i = idx
        while (i > 0 && _staticChild[i]._priority > _staticChild[i-1]._priority) {
            (_staticChild[i], _staticChild[i-1]) = (_staticChild[i-1], _staticChild[i])
            (_staticIndices[i], _staticIndices[i-1]) = (_staticIndices[i-1], _staticIndices[i])
            i -= 1
        }
    }

    func setHandler(method: String, handler: T, implicitHead: Bool): Unit {
        let val = _leafHandlers.get(method)
        ifSome(val, { _=>
            if (method != "HEAD" || !_implicitHead ) {
                throw IllegalArgumentException("'${_path}' already handlers ${method}")
            }
        })

        _leafHandlers[method] = handler
        if (method == "HEAD") {
            _implicitHead = implicitHead
        }
    }

    private func checkParamName(paramNames: ArrayList<String>):Unit {
        if (_leafParamNames.size != paramNames.size) {
            throw IllegalArgumentException("reached leaf node with differing wildcard array length(${_leafParamNames.size}, ${paramNames.size}). please report this as a bug.")
        }

        for (idx in 0..paramNames.size) {
            if (_leafParamNames[idx] != paramNames[idx]) {
                throw IllegalArgumentException("wildcards ${_leafParamNames} are ambiguous with wildcards ${paramNames}")
            }
        }
    }

    func addPath(path: String, paramNames: ArrayList<String>, inStaticToken: Bool): Node<T> {
        if (path.isEmpty()) {
            if (!_leafParamNames.isEmpty()) {
                checkParamName(paramNames)
            } else {
                _leafParamNames = paramNames
            }
            return this
        }

        var firstByte = path[0]
        let nextSlash = path.indexOf(b'/').getOrDefault({=>-1})
        var (token, tokenEnd) = if (firstByte == b'/') {
            ("/", 1)
        } else if (nextSlash == -1) {
            (path, path.size)
        } else {
            (path[0..nextSlash], nextSlash)
        }

        let remainingPath = path[tokenEnd..path.size]
        // catch-all path
        if (firstByte == b'*' && !inStaticToken) {
            return addCatchAllPath(token, path, nextSlash, paramNames)
        }

        // named path 
        if (firstByte == b':' && !inStaticToken) {
            return addWildcardPath(token, remainingPath, paramNames)
        } 

        // other path
        var unesaceped = false
        if (token.size >= 2 && !inStaticToken) {
            if (token[0] == b'\\' && (token[1] == b'*' || token[1] == b':' || token[1] == b'\\')) {
                firstByte = token[1]
                token = token[1..token.size]
                unesaceped = true
            }
        }
        return addOtherPath(token, firstByte, path, remainingPath, unesaceped, paramNames)
    }

    private func addOtherPath(token: String, firstByte: Byte, path: String, remainingPath: String, unesaceped: Bool, paramNames: ArrayList<String>): Node<T> {
        let inStaticToken = (firstByte != b'/')
        for (i in 0.._staticIndices.size) {
            if (_staticIndices[i] == firstByte) {
                var (child, prefixSplit) = splitCommonPrefix(i, token)
                child._priority +=1
                sortStaticChild(i)
                if (unesaceped) {
                    prefixSplit +=1
                }
                return child.addPath(path[prefixSplit..path.size], paramNames, inStaticToken)
            }
        }

        let child = Node<T>(token, NodeType.STATIC)
        if (_nodeType == NodeType.WILDCARD) {
            child._nodeType = NodeType.WILDCARD
        }

        if (_staticIndices.isEmpty()) {
            _staticIndices = ArrayList([firstByte])
            _staticChild = ArrayList([child])
        } else {
            _staticIndices.append(firstByte)
            _staticChild.append(child)
        }
        return child.addPath(remainingPath, paramNames, inStaticToken)
    }

    private func addCatchAllPath(token: String, path: String, nextSlash: Int64, paramNames: ArrayList<String>): Node<T> {
        // token starts with a "*", it's a catch-all
        let thisToken = token[1..token.size]
        if (_catchAllChild.isNone()) {
            _catchAllChild = Node<T>(thisToken, NodeType.CATCH_ALL)
        }
        let catchAllChild = _catchAllChild.getOrThrow()
        
        if (path[1..path.size] != catchAllChild._path) {
            throw IllegalArgumentException("catch-all name in ${path} doesn't match ${catchAllChild._path}, you probably tried to define overlapping catchalls.")
        }
        if (nextSlash != -1) {
            throw IllegalArgumentException("/ after catch-all found in ${path}")
        }

        let lpn = ArrayList<String>(paramNames)
        lpn.append(thisToken)
        catchAllChild._leafParamNames = lpn
        return catchAllChild
    }

    private func addWildcardPath(token: String, remainingPath: String, paramNames: ArrayList<String>): Node<T> {
        let thisToken = token[1..token.size]
        let lpn = ArrayList<String>(paramNames)
        lpn.append(thisToken)
        
        if (_wildcardChild.isNone()) {
            _wildcardChild = Node<T>("wildcard", NodeType.WILDCARD)
        }
        let wildcardChild = _wildcardChild.getOrThrow()

        return wildcardChild.addPath(remainingPath, lpn, false)
    }

    private func splitCommonPrefix(existingNodeIndex: Int64, path: String): (Node<T>, Int64) {
        let childNode = _staticChild[existingNodeIndex]
        if (path.startsWith(childNode._path)) {
            return (childNode, childNode._path.size)
        }

        var idx = 0
        // find the length of the common prefix of the child node and the new path.
        for (i in 0..childNode._path.size) {
            if (i == path.size || path[i] != childNode._path[i]) {
                idx = i
                break
            }
        }

        let commonPrefix = path[0..idx]
        childNode._path = childNode._path[idx..childNode._path.size]

        let newNode = Node<T>(commonPrefix, NodeType.STATIC)
        newNode._priority = childNode._priority
        newNode._staticIndices = ArrayList([childNode._path[0]])
        newNode._staticChild = ArrayList([childNode])

        _staticChild[existingNodeIndex] = newNode
        (newNode, idx)
    }

    func search(method: String, path: String): (?Node<T>, ?T, Array<String>) {
        search(method, path, HANDLER_VALID_FUNC)
    }

    func search(method: String, path: String, isValid: (T) -> Bool): (?Node<T>, ?T, Array<String>) {
        let pathLen = path.size
        // root
        if (pathLen == 0) {
            if (_leafHandlers.size == 0) {
                return (None, None, Array<String>())
            }
            return (this, _leafHandlers.get(method), Array<String>())
        }

        // searchStatic
        var (sflag, found, handler, params) = searchStatic(method, path, isValid)
        if (sflag) {
            return (found, handler, params)
        }

        // searchWildchild
        let (wflag, wfound, whandler, wparams) = searchWildchild(method, path, found, isValid)
        if (wflag) {
            return (wfound, whandler, wparams)
        } else {
            if (wfound.isSome()) {
                (found, handler, params) = (wfound, whandler, wparams)
            }
        }

        // searchCatchAll
        let (cflag, cfound, chandler, cparams) = searchCatchAll(method, path, found, isValid)
        if (cflag) {
            return (cfound, chandler, cparams)
        }

        return (found, handler, params)
    }

    private func searchStatic(method: String, path: String, isValid: (T) -> Bool): (Bool, ?Node<T>, ?T, Array<String>) {
        var found: ?Node<T> = None
        var handler: ?T = None
        var params: Array<String> = []
        for (i in 0.._staticIndices.size) {
            if (_staticIndices[i] == path[0]) {
                let child = _staticChild[i]
                let childPathLen = child._path.size
                if (path.size >= childPathLen && child._path == path[0..childPathLen]) {
                    let nextPath = path[childPathLen..path.size]
                    (found, handler, params) = child.search(method, nextPath, isValid)
                }
                break
            }
        }

        if (handler.isSome() && isValid(handler.getOrThrow())) {
            return (true, found, handler, params)
        }
        return (false, found, handler, params)
    }

    private func searchWildchild(method: String, path: String, found: ?Node<T>, isValid: (T) -> Bool): (Bool, ?Node<T>, ?T, Array<String>) {
        if (_wildcardChild.isNone()) {
            return (false, None, None, [])
        }

        var nextSlash = path.indexOf(b'/').getOrDefault({=>-1})
        if (nextSlash <= 0) {
            nextSlash = path.size
        }

        let thisToken = path[0..nextSlash]
        let nextToken = path[nextSlash..path.size]

        if (!thisToken.isEmpty()) {
            let (wcfound, wchandler, wcparams) = _wildcardChild.getOrThrow().search(method, nextToken, isValid)
            let valid = wchandler.isSome() && isValid(wchandler.getOrThrow())
            if (valid || (found.isNone() && wcfound.isSome())) {
                let unescaped = unescape(thisToken)
                let newparams = ArrayList(wcparams)
                newparams.append(unescaped)
                if (valid) {
                    return (true, wcfound, wchandler, newparams.toArray())
                }
                return (false, wcfound, wchandler, newparams.toArray())
            }
        }
        return (false, None, None, [])
    }

    private func searchCatchAll(method: String, path: String, found: ?Node<T>, isValid: (T) -> Bool): (Bool, ?Node<T>, ?T, Array<String>) {
        if (_catchAllChild.isNone()) {
            return (false, None, None, [])
        }

        let handler = _catchAllChild.getOrThrow()._leafHandlers.get(method)
        let valid = handler.isSome() && isValid(handler.getOrThrow())
        if (valid || found.isNone()) {
            let unescaped = unescape(path)
            return (true, _catchAllChild, handler, [unescaped])
        }
        (false, None, None, [])
    }

    static func unescape(path: String): String {
	    return path
    }

    func dumpTree(prefix: String, nodeType: String): String {
        let methods = _leafHandlers.keys()
        let builder = StringBuilder()
        let line = "${prefix} ${_path} ${nodeType} ${methods.toArray()}, childres[${_staticChild.size}], params ${_leafParamNames}, ${_priority}\n"
        builder.append(line)
        
        let prefixStr = prefix + " "
        _staticChild |> forEach { val => builder.append(val.dumpTree(prefixStr, " ")) }
        ifSome(_wildcardChild, { val =>  builder.append(val.dumpTree(prefixStr, ":")) })
        ifSome(_catchAllChild, { val =>  builder.append(val.dumpTree(prefixStr, "*")) })

        builder.toString()
    }
}