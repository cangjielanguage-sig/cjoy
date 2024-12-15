package cjoy

public interface JoyRouters {
    func use(mw: JoyFuncHandler): JoyRouters
    func group(relativePath: String): JoyRouters
    func basePath(): String

    func GET(relativePath: String, hanler: JoyFuncHandler): JoyRouters
    func POST(relativePath: String, hanler: JoyFuncHandler): JoyRouters
    func PUT(relativePath: String, hanler: JoyFuncHandler): JoyRouters
    func DELETE(prelativePathath: String, hanler: JoyFuncHandler): JoyRouters
    func PATCH(relativePath: String, hanler: JoyFuncHandler): JoyRouters
    func OPTION(relativePath: String, hanler: JoyFuncHandler): JoyRouters
    func HEAD(relativePath: String, hanler: JoyFuncHandler): JoyRouters
    func handle(method: Array<String>, relativePath: String, handler: JoyFuncHandler): JoyRouters

    func staticFile(relativePath: String, filePath: String): JoyRouters
    func staticAll(relativePath: String, rootPath: String): JoyRouters
}

class JoyRouteGroup <: JoyRouters {
    public func use(mw: JoyFuncHandler): JoyRouters {
        this
    }

    public func group(relativePath: String): JoyRouters {
        this
    }

    public func basePath(): String {
        ""
    }

    public func GET(relativePath: String, hanler: JoyFuncHandler): JoyRouters {
        this
    }

    public func POST(relativePath: String, hanler: JoyFuncHandler): JoyRouters {
        this
    }

    public func PUT(relativePath: String, hanler: JoyFuncHandler): JoyRouters {
        this
    }

    public func DELETE(prelativePathath: String, hanler: JoyFuncHandler): JoyRouters {
        this
    }

    public func PATCH(relativePath: String, hanler: JoyFuncHandler): JoyRouters {
        this
    }

    public func OPTION(relativePath: String, hanler: JoyFuncHandler): JoyRouters {
        this
    }

    public func HEAD(relativePath: String, hanler: JoyFuncHandler): JoyRouters {
        this
    }

    public func handle(method: Array<String>, relativePath: String, handler: JoyFuncHandler): JoyRouters {
        this
    }

    public func staticFile(relativePath: String, filePath: String): JoyRouters {
        this
    }

    public func staticAll(relativePath: String, rootPath: String): JoyRouters {
        this
    }
}