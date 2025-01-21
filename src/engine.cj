/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy

import net.http.{Server, ServerBuilder}
import log.{LogLevel, Logger}
import logger.SimpleLogger
import std.console.Console

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
    private var _server: ?Server = None
    private var _config: JoyConfig
    public let router: JoyRouters

    private init(config: JoyConfig) {
        _config = config
        router = JoyRouteGroup(config)
    }

    /**
     * create Joy engine instance by default config
     *
     * @return the instance of Joy
     */
    public static func create(): Joy {
        create(JoyConfig())
    }

    /**
     * create Joy engine instance by config
     *
     * @param config: the global config
     * @return the instance of Joy
     */
    public static func create(config: JoyConfig): Joy {
        Joy(config)
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
    }
}
