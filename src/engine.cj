/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy

import net.http.{Server, ServerBuilder}
import log.{LogLevel, Logger}
import logger.SimpleLogger
import std.console.Console
import std.collection.concurrent.ConcurrentHashMap
import std.collection.ArrayList

/**
 * joy config
 */
public class JoyConfig {
    // the trust remote ip headers
    public var remoteIPHeaders: Array<String> = []

    // enable debug log
    public var enableDebugLog: Bool = false

    // whether case insensitive when add route handler
    public var caseInsensitive: Bool = false

    // whether escape the path when add route handler
    public var escapeAddedRoutes: Bool = false

    // set not found handler 
    public var notFoundHandler: JoyRequestHandler = JoyNotFoundHandler()
    
    // set method not allowed handler 
    public var methodNotAllowedHandler: JoyRequestHandler = JoyMethodNotAllowedHandler()
    
    private var _logger: ?Logger = None

    mut prop logger: Logger {
        get() {
            if (_logger.isNone()) {
                _logger = Some(SimpleLogger(Console.stdOut))
            }
            return _logger.getOrThrow()
        }
        set(value) {
            _logger = Some(value)
        }
    }
}

/**
 * a wrapper for net.http.Server
 */
public class Joy {
    private static let _INSTANCES: ConcurrentHashMap<String, Joy> = ConcurrentHashMap()

    private var _server: ?Server = None
    private let _config: JoyConfig
    private let _name: String
    public let router: JoyRouters

    private init(config: JoyConfig, name: String) {
        _config = config
        _name = name
        router = JoyRouteGroup(config)
    }

    /**
    * return the default Joy engine instance
    */
    public static func default(): Joy {
        // ~_~，bad sdk api, not have comptueIfAbsent func in map
        // the func is not atomic
        if (_INSTANCES.contains("default")) {
            return _INSTANCES.get("default").getOrThrow()
        }
        let joy = create()
        _INSTANCES.put("default", joy)
        return joy
    }

    /**
     * create Joy engine instance by default config
     *
     * @parame name: the instance name
     * @return the instance of Joy
     */
    public static func create(name!: String = "default"): Joy {
        create(JoyConfig(), name:name)
    }

    /**
     * create Joy engine instance by config
     *
     * @parame name: the instance name
     * @param config: the global config
     * @return the instance of Joy
     */
    public static func create(config: JoyConfig, name!: String = "default"): Joy {
        if (_INSTANCES.contains(name)) {
            throw IllegalArgumentException("the instance name is already existing, name=${name}")
        }
        let joy = Joy(config, name)
        _INSTANCES.put(name, joy)
        joy
    }

    /**
     * run http server at address:port
     *
     * @param addr: the listen address
     * @param port: the listen port
     */
    public func run(addr: String, port: UInt16): Unit {
        run(ServerBuilder().addr(addr).port(port))
    }

    /**
     * run http server by ServerBuilder
     * 
     * @param serverBuidler: the server buidler 
     */
    public func run(serverBuidler: ServerBuilder): Unit {
        let server = serverBuidler.distributor(router.distributor).build()
        if (_config.enableDebugLog) {
            server.logger.level = LogLevel.DEBUG
        }        
        _config.logger = server.logger
        _server = Some(server)
        _config.logger.debug("[Joy#run] route tree:\n${router.dump()}")
        server.serve()
    }

    /**
     * shutdown the server
     * 
     * @param gracefully: whether gracefully shutdown
     */
    public func shutdown(gracefully!: Bool = true) {
        if (let Some(server) <- _server) {
            if (gracefully) {
                server.closeGracefully()
            } else {
                server.close()
            }
        }
        _INSTANCES.remove(_name)
    }
}
