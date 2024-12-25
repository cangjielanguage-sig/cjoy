package cjoy

import std.collection.{ArrayList, HashMap, forEach}
import std.regex.Regex

enum NodeType {
    STATIC | WILDCARD | REGEXP | CATCH_ALL

    public operator func ==(that: NodeType) {
        match ((this, that)) {
            case (STATIC, STATIC) => true
            case (WILDCARD, WILDCARD) => true
            case (REGEXP, REGEXP) => true
            case (CATCH_ALL, CATCH_ALL) => true
            case _ => false
        }
    }

    public operator func !=(that: NodeType) {
        !(this == that)
    }
}

class Node<T> {
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
        _nodeType == CATCH_ALL
    }

    func sortStaticChild(idx: Int64): Unit {
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

    func checkParamName(paramNames: ArrayList<String>):Unit {
        if (_leafParamNames.size != paramNames.size) {
            throw IllegalArgumentException("Reached leaf node with differing wildcard array length. Please report this as a bug.")
        }

        for (idx in 0..paramNames.size) {
            if (_leafParamNames[idx] != paramNames[idx]) {
                throw IllegalArgumentException("wildcards ${_leafParamNames} are ambiguous with wildcards ${paramNames}")
            }
        }
    }

    func addPath(path: String, paramNames: ArrayList<String>, inStaticToken: Bool): Node<T> {
        let leaf = path.isEmpty()
        if (leaf) {
            if (!paramNames.isEmpty()) {
                checkParamName(paramNames)
            } else {
                _leafParamNames = paramNames
            }

            return this
        }

        var c = path[0]
        let nextSlash = path.indexOf(b'/').getOrDefault({=>-1})
        var thisToken: String = ""
        var tokenEnd = -1

        (thisToken, tokenEnd) = if (c == b'/') {
            ("/", 1)
        } else if (nextSlash == -1) {
            (path, path.size)
        } else {
            (path[0..nextSlash], nextSlash)
        }

        let remainingPath = path[tokenEnd..path.size]
        if (c == b'*' && !inStaticToken) {
            // token starts with a "*", it's a catch-all
            thisToken = thisToken[1..thisToken.size]
            if (_catchAllChild.isNone()) {
                _catchAllChild = Node<T>(path, CATCH_ALL)
            }

            if (path[1..path.size] != _catchAllChild.getOrThrow()._path) {
                throw IllegalArgumentException("Catch-all name in ${path} doesn't match ${_catchAllChild.getOrThrow()._path}, You probably tried to define overlapping catchalls.")
            }

            if (nextSlash != -1) {
                throw IllegalArgumentException(" / after catch-all found in ${path}")
            }
            let lpn = ArrayList<String>(paramNames)
            lpn.append(thisToken)
            _catchAllChild.getOrThrow()._leafParamNames = lpn
            return _catchAllChild.getOrThrow()
        } 
        if (c == b':' && !inStaticToken) {
            thisToken = thisToken[1..thisToken.size]
            paramNames.append(thisToken)
            if (_wildcardChild.isNone()) {
                _wildcardChild = Node<T>("wildcard", WILDCARD)
            }
            return _wildcardChild.getOrThrow().addPath(remainingPath, paramNames, false)
        } 

        var unesaceped = false
        if (thisToken.size >= 2 && !inStaticToken) {
            if (thisToken[0] == b'\\' && (thisToken[1] == b'*' || thisToken[1] == b':' || thisToken[1] == b'~' || thisToken[1] == b'\\')) {
                c = thisToken[1]
                thisToken = thisToken[1..thisToken.size]
                unesaceped = true
            }
        }

        let inStaticToken_ = (c != b'/')
        for (i in 0.._staticIndices.size) {
            var (child, prefixSplit) = splitCommonPrefix(i, thisToken)
            child._priority +=1
            sortStaticChild(i)
            if (unesaceped) {
                prefixSplit +=1
            }
            return child.addPath(path[prefixSplit..path.size], paramNames, inStaticToken_)
        }

        let child = Node<T>(thisToken, STATIC)
        if (_nodeType == WILDCARD) {
            child._nodeType = WILDCARD
        }

        if (_staticIndices.isEmpty()) {
            _staticIndices = ArrayList([c])
            _staticChild = ArrayList([child])
        } else {
            _staticIndices.append(c)
            _staticChild.append(child)
        }
        return child.addPath(remainingPath, paramNames, inStaticToken_)
    }

    func splitCommonPrefix(existingNodeIndex: Int64, path: String): (Node<T>, Int64) {
        let childNode = _staticChild[existingNodeIndex]
        if (path.startsWith(childNode._path)) {
            return (childNode, childNode._path.size)
        }

        var i = 0
        for (i in 0..childNode._path.size) {
            if (i == path.size) {
                break
            }
            if (path[i] == childNode._path[i]) {
                break
            }
        }

        let commonPrefix = path[0..i]
        childNode._path = childNode._path[i..childNode._path.size]

        let newNode = Node<T>(commonPrefix, STATIC)
        newNode._staticIndices = ArrayList([childNode._path[0]])
        newNode._staticChild = ArrayList([childNode])

        _staticChild[existingNodeIndex] = newNode
        (newNode, i)
    }

    func search(method: String, path: String, isValid: (T) -> Bool): (?Node<T>, ?T, Array<String>) {
        let pathLen = path.size
        if (pathLen == 0) {
            if (_leafHandlers.size == 0) {
                return (Option<Node<T>>.None, Option<T>.None, Array<String>())
            }
            return (this, _leafHandlers.get(method), Array<String>())
        }
        let firstChar = path[0]

        var found: ?Node<T> = Option<Node<T>>.None
        var handler: ?T = Option<T>.None
        var params: Array<String> = []
        for (i in 0.._staticIndices.size) {
            if (_staticIndices[i] == firstChar) {
                let child = _staticChild[i]
                let childPathLen = child._path.size
                if (pathLen >= childPathLen && child._path == path[0..childPathLen]) {
                    let nextPath = path[childPathLen..path.size]
                    (found, handler, params) = child.search(method, nextPath, isValid)
                }
                break
            }
        }

        if (handler.isSome() && isValid(handler.getOrThrow())) {
            return (found, handler, params)
        }

        if (_wildcardChild.isSome()) {
            var nextSlash = path.indexOf(b'/').getOrDefault({=>-1})
            if (nextSlash <= 0) {
                nextSlash = pathLen
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
                        return (wcfound, wchandler, newparams.toArray())
                    }
                    (found, handler, params) = (wcfound, wchandler, newparams.toArray())
                }
            }
        }

        if (_catchAllChild.isSome()) {
            let handler = _catchAllChild.getOrThrow()._leafHandlers.get(method)
            let valid = handler.isSome() && isValid(handler.getOrThrow())
            if (valid || found.isNone()) {
                let unescaped = unescape(path)
                return (_catchAllChild, handler, [unescaped])
            }
        }

        return (found, handler, params)
     }

    static func unescape(path: String): String {
	    return path
    }

    func dumpTree(prefix: String, nodeType: String): String {
        let methods = _leafHandlers.keys()
        let builder = StringBuilder()
        let line = "${prefix} ${_priority} ${nodeType} ${_path}, ${_staticChild.size}, ${methods.toArray()} params ${_leafParamNames}\n"
        builder.append(line)
        
        let prefixStr = prefix + " "
        _staticChild |> forEach { val => val.dumpTree(prefixStr, "") }
        ifSome(_wildcardChild, { val =>  builder.append(val.dumpTree(prefix, ":"))})
        ifSome(_catchAllChild, { val =>  builder.append(val.dumpTree(prefix, "*"))})

        builder.toString()
    }
}