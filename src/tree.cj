package cjoy

import std.collection.{ArrayList, HashMap}
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
    var path: String = ""
    var fullPath: String = ""
    var nodeType: NodeType = STATIC
    
    var priority: Int32 = 0

    var staticIndices: ArrayList<Byte> = ArrayList()
    var staticChild: ArrayList<Node<T>> = ArrayList()

    var wildcardChild: Option<Node<T>> = None

    var regexChild: ArrayList<Node<T>> = ArrayList()
    var regExper: ?Regex = None

    var catchAllChild: Option<Node<T>> = None
    var implicitHead: Bool = false

    var leafHandlers: HashMap<String, T> = HashMap()
    var leafParamNames: ArrayList<String> = ArrayList()

    init(path: String, nodeType: NodeType) {
        this.path = path
        this.nodeType = nodeType
    }

    func isCatchAll(): Bool {
        this.nodeType == CATCH_ALL
    }

    func sortStaticChild(idx: Int64): Unit {
        var i = idx
        while (i > 0 && staticChild[i].priority > staticChild[i-1].priority) {
            (staticChild[i], staticChild[i-1]) = (staticChild[i-1], staticChild[i])
            (staticIndices[i], staticIndices[i-1]) = (staticIndices[i-1], staticIndices[i])
            i -= 1
        }
    }

    func setHandler(method: String, handler: T, implicitHead: Bool): Unit {
        let val = leafHandlers.get(method)
        ifSome(val, { v=>
            if (method != "HEAD" || !this.implicitHead ) {
                throw IllegalArgumentException("'${path}' already handlers ${method}")
            }
        })
        leafHandlers[method] = handler
        if (method == "HEAD") {
            this.implicitHead = implicitHead
        }
    }

    func checkParamName(paramNames: Array<String>):Unit {
        if (leafParamNames.size != paramNames.size) {
            throw IllegalArgumentException("Reached leaf node with differing wildcard array length. Please report this as a bug.")
        }

        for (idx in 0..paramNames.size) {
            if (leafParamNames[idx] != paramNames[idx]) {
                throw IllegalArgumentException("wildcards ${leafParamNames} are ambiguous with wildcards ${paramNames}")
            }
        }
    }

    func addPath(path: String, paramNames: ArrayList<String>, inStaticToken: Bool): Node<T> {
        let leaf = path.isEmpty()
        if (leaf) {
            if (!paramNames.isEmpty()) {
                checkParamName(paramNames)
            } else {
                leafParamNames = paramNames
            }

            return this
        }

        var c = path[0]
        let nextSlash = path.indexOf(b'/').getOrDefault({=>-1})
        var thisToken: String = ""
        var tokenEnd = -1

        if (c == b'/') {
            thisToken = "/"
            tokenEnd = 1
        } else if (nextSlash == -1) {
            thisToken = path
            tokenEnd = path.size
        } else {
            thisToken = path[0..nextSlash]
            tokenEnd = nextSlash
        }

        let remainingPath = path[tokenEnd..path.size]
        if (c == b'*' && !inStaticToken) {
            // token starts with a "*", it's a catch-all
            thisToken = thisToken[1..thisToken.size]
            if (this.catchAllChild.isNone()) {
                this.catchAllChild = Node<T>(path, CATCH_ALL)
            }

            if (path[1..path.size] != this.catchAllChild.getOrThrow().path) {
                throw IllegalArgumentException("Catch-all name in ${path} doesn't match ${catchAllChild.getOrThrow().path}, You probably tried to define overlapping catchalls.")
            }

            if (nextSlash != -1) {
                throw IllegalArgumentException(" / after catch-all found in ${path}")
            }
            let lpn = ArrayList<String>(paramNames)
            lpn.append(thisToken)
            catchAllChild.getOrThrow().leafParamNames = lpn
            return catchAllChild.getOrThrow()
        } else if (c == b'~' && !inStaticToken) {
            thisToken = thisToken[1..thisToken.size]
            for (child in regexChild) {
                if ( thisToken == child.path) {
                    return child
                }
            }
            let regex = Regex(thisToken)
            let child = Node<T>(thisToken, REGEXP)
            child.regExper = regex
            this.regexChild.append(child)
            child.leafParamNames = ArrayList<String>(paramNames)
            child.leafParamNames.appendAll(getRegexParamNames(regex))
            return child
        } else if (c == b':' && !inStaticToken) {
            thisToken = thisToken[1..thisToken.size]
            paramNames.append(thisToken)
            if (wildcardChild.isNone()) {
                wildcardChild = Node<T>("wildcard", WILDCARD)
            }
            return wildcardChild.getOrThrow().addPath(remainingPath, paramNames, false)
        } else {
            var unesaceped = false
            if (thisToken.size >= 2 && !inStaticToken) {
                if (thisToken[0] == b'\\' && (thisToken[1] == b'*' || thisToken[1] == b':' || thisToken[1] == b'~' || thisToken[1] == b'\\')) {
                    c = thisToken[1]
                    thisToken = thisToken[1..thisToken.size]
                    unesaceped = true
                }
            }

            let inStaticToken = (c != b'/')
            for (i in 0..staticIndices.size) {
                var (child, prefixSplit) = splitCommonPrefix(i, thisToken)
                child.priority +=1
                sortStaticChild(i)
                if (unesaceped) {
                    prefixSplit +=1
                }
                return child.addPath(path[prefixSplit..path.size], paramNames, inStaticToken)
            }

            let child = Node<T>(thisToken, STATIC)
            if (nodeType == WILDCARD) {
                child.nodeType = WILDCARD
            }

            if (staticIndices.isEmpty()) {
                staticIndices = ArrayList([c])
                staticChild = ArrayList([child])
            } else {
                staticIndices.append(c)
                staticChild.append(child)
            }
            return child.addPath(remainingPath, paramNamesm, inStaticToken)
        }
    }

    func splitCommonPrefix(existingNodeIndex: Int64, path: String): (Node<T>, Int64) {
        let childNode = staticChild[existingNodeIndex]
        if (path.startsWith(childNode.path)) {
            return (childNode, childNode.path.size)
        }

        var i = 0
        for (i in 0..childNode.path.size) {
            if (i == path.size) {
                break
            }
            if (path[i] == childNode.path[i]) {
                break
            }
        }

        let commonPrefix = path[0..i]
        childNode.path = childNode.path[i..childNode.path.size]

        let newNode = Node<T>(commonPrefix, STATIC)
        newNode.staticIndices = ArrayList([childNode.path[0]])
        newNode.staticChild = ArrayList([childNode])
        staticChild[existingNodeIndex] = newNode
        (newNode, i)
    }

    func search(method: String, path: String, isValid: (T) -> Bool): (?Node<T>, ?T, Array<String>) {
        let pathLen = path.size
        if (pathLen == 0) {
            if (leafHandlers.size == 0) {
                return (Option<Node<T>>.None, Option<T>.None, Array<String>())
            }
            return (this, leafHandlers.get(method), Array<String>())
        }
        let firstChar = path[0]

        var found: ?Node<T> = Option<Node<T>>.None
        var handler: ?T = Option<T>.None
        var params: Array<String> = []
        for (i in 0..staticIndices.size) {
            if (staticIndices[i] == firstChar) {
                let child = staticChild[i]
                let childPathLen = child.path.size
                if (pathLen >= childPathLen && child.path == path[0..childPathLen]) {
                    let nextPath = path[childPathLen..path.size]
                    (found, handler, params) = child.search(method, nextPath, isValid)
                }
                break
            }
        }

        if (handler.isSome() && isValid(handler.getOrThrow())) {
            return (found, handler, params)
        }

        if (wildcardChild.isSome()) {
            var nextSlash = path.indexOf(b'/').getOrDefault({=>-1})
            if (nextSlash <= 0) {
                nextSlash = pathLen
            }

            let thisToken = path[0..nextSlash]
            let nextToken = path[nextSlash..path.size]

            if (!thisToken.isEmpty()) {
                let (wcfound, wchandler, wcparams) = wildcardChild.getOrThrow().search(method, nextToken, isValid)
                let valid = wchandler.isSome() && isValid(wchandler.getOrThrow())
                if (valid || (found.isNone() && wcfound.isSome())){
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

        if (regexChild.size > 0) {
            let (refound, rehandler, reparams) = searchRegexChild(method, path, isValid)
            let valid = rehandler.isSome() && isValid(rehandler.getOrThrow())
            if (valid || (found.isNone() && refound.isSome())){
                if (valid) {
                    return (refound, rehandler, reparams)
                }
                (found, handler, params) = (refound, rehandler, reparams)
            }
        }

        if (catchAllChild.isSome()) {
            let handler = catchAllChild.getOrThrow().leafHandlers.get(method)
            let valid = handler.isSome() && isValid(handler.getOrThrow())
            if (valid || found.isNone()) {
                let unescaped = unescape(path)
                return (catchAllChild, handler, [unescaped])
            }
        }

        return (found, handler, params)
     }

    func searchRegexChild(method: String, path: String, isValid: (T) -> Bool): (?Node<T>, ?T, Array<String>) {
        throw UnsupportedException("unsupported ")
    }

    static func getRegexParamNames(reg: Regex): ArrayList<String> {
        throw UnsupportedException("unsupported ")
    }

    static func unescape(path: String): String {
	    return path
    }

    func dumpTree(prefix: String, nodeType: String): String {
        let methods = this.leafHandlers.keys()
        let builder = StringBuilder()
        let line = "${prefix} ${priority} ${nodeType} ${path}, ${staticChild.size}, ${methods.toArray()} params ${leafParamNames}\n"
        builder.append(line)
        var prefixStr = prefix + " "
        for (node in staticChild) {
            builder.append(node.dumpTree(prefixStr, ""))
        }
        if (wildcardChild.isSome()) {
            builder.append(wildcardChild.getOrThrow().dumpTree(prefix, ":"))
        }
        for (child in regexChild) {
            builder.append(child.dumpTree(prefixStr, "~"))
        }
        if (catchAllChild.isSome()) {
            builder.append(catchAllChild.getOrThrow().dumpTree(prefix, "*"))
        }

        builder.toString()
    }
}