/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulansPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.concurrent.ConcurrentHashMap
import std.fs.{File, OpenMode}
import std.io.{readToEnd}
import stdx.net.tls.TlsServerConfig
import stdx.net.http.{Server, ServerBuilder}
import stdx.crypto.x509.{X509Certificate, PrivateKey}
import cjoy.log.macros.*
import cjoy.ioc.BeanFactoryManager
import cjoy.context.{ServiceContainer}
import cjoy.version.printBanner

@JoyCreateLogger("cjoy.framework")

/**
 * Configuration options for CJoy web server
 *
 */
public class JoyConfig {
    /**
     *  create JoyConfig instance
     *
     * @param remoteIPHeaders: list of header names to check for real client IP (e.g., "X-Forwarded-For")
     * @param enableDebugLog: enable debug logging (deprecated, use JoyLoggerFactory instead)
     * @param caseInsensitive: case-insensitive route matching
     * @param escapeAddedRoutes: escape special characters in route patterns
     * @param notFoundHandler: handler for 404 Not Found responses
     * @param methodNotAllowedHandler: handler for 405 Method Not Allowed responses
     * @param maxRequestBodySize: maximum request body size in bytes (default: 32MB)
     */
    public JoyConfig(
        public let remoteIPHeaders!: Array<String> = [],

        // enable debug log
        @Deprecated["Use JoyLoggerFactory", since: "v0.90.0"] public var enableDebugLog!: Bool = true,

        // whether case insensitive when add route handler
        public let caseInsensitive!: Bool = false,

        // whether escape path when add route handler
        public let escapeAddedRoutes!: Bool = false,

        // set not found handler
        public var notFoundHandler!: JoyRequestHandler = JoyNotFoundHandler(),

        // set method not allowed handler
        public var methodNotAllowedHandler!: JoyRequestHandler = JoyMethodNotAllowedHandler(),

        // max requestBodySize, 32M
        public let maxRequestBodySize!: Int = 32 * 1024 * 1024
    ) {}
}

/**
 * a wrapper for net.http.Server
 */
public class Joy {
    private static let _INSTANCES: ConcurrentHashMap<String, Joy> = ConcurrentHashMap()
    private var _server: ?Server = None
    private let _services: ServiceContainer = ServiceContainer()

    public let config: JoyConfig
    public let name: String
    public let router: JoyRouters

    private init(config: JoyConfig, name: String) {
        this.config = config
        this.name = name
        router = JoyRouteGroup(config, _services)
        printBanner()
        @JoyLogInfo("create joy app ${name}")
    }

    /**
     * return net.http.Server
     */
    public prop server: Server {
        get() {
            _server.getOrThrow()
        }
    }

    /**
     * return default Joy engine instance
     */
    public static func default(): Joy {
        // ~_~，bad sdk api, not have comptueIfAbsent func in map
        // func is not atomic
        if (_INSTANCES.contains("default")) {
            return _INSTANCES.get("default").getOrThrow()
        }
        return create()
    }

    /**
     * create Joy engine instance by default config
     *
     * @parame name: instance name
     * @return instance of Joy
     */
    public static func create(name!: String = "default"): Joy {
        create(JoyConfig(), name: name)
    }

    /**
     * create Joy engine instance by config
     *
     * @parame name: instance name
     * @param config: global config
     * @return instance of Joy
     * @throws IllegalArgumentException if name is existed
     */
    public static func create(config: JoyConfig, name!: String = "default"): Joy {
        if (_INSTANCES.contains(name)) {
            throw IllegalArgumentException("the instance name is already existing, name=${name}")
        }
        let joy = Joy(config, name)
        // 默认增加IoC服务
        joy._services.addServicesFrom(ServiceContainer.GLOBAL)
        _INSTANCES.add(name, joy)
        joy
    }

    /**
     * run http server at address:port
     *
     * @param addr: listen address
     * @param port: listen port
     */
    public func run(addr: String, port: UInt16): Unit {
        run(ServerBuilder().addr(addr).port(port))
    }

    /**
     * run https https server at address:port with certificate files
     *
     * @param addr: listen address
     * @param port: listen port
     * @param certFilePath: certificate server file path
     * @param keyFilePath: certificate server key file path
     * @param password: password of certificate server key
     * @param h2: run as http2
     */
    public func run(addr: String, port: UInt16, certFilePath: String, keyFilePath: String, password!: ?String = None,
        h2!: Bool = false): Unit {
        var tlsConfig = loadTlsConfig(certFilePath, keyFilePath, password)
        if (h2) {
            tlsConfig.supportedAlpnProtocols = ["h2"]
        }
        run(ServerBuilder().addr(addr).port(port).tlsConfig(tlsConfig))
    }

    /**
     * run http(s) server by ServerBuilder
     *
     * @param serverBuidler: server buidler
     */
    public func run(serverBuidler: ServerBuilder): Unit {
        let server = serverBuidler
            .distributor(router.distributor)
            .logger(_JOY_LOGGER)
            .maxRequestBodySize(config.maxRequestBodySize)
            .build()
        _server = Some(server)
        // 在Run之前至少要执行一次
        BeanFactoryManager.initAllBeans()
        @JoyLogInfo("run cjoy app ${name}, bind at ${server.addr}:${server.port}")
        @JoyLogInfo("route tree:\n${router.dump()}")
        server.serve()
    }

    /**
     * shutdown server
     *
     * @param gracefully: whether gracefully shutdown
     */
    public func shutdown(gracefully!: Bool = true): Unit {
        if (let Some(server) <- _server) {
            if (gracefully) {
                server.closeGracefully()
            } else {
                server.close()
            }
        }
        _INSTANCES.remove(this.name)
    }

    /**
     * add a service to joy instance
     *
     * @param name: service unqiue name
     * @param service : service instance object
     * @return joy instance
     */
    public func addService(name: String, service: Any): Joy {
        _services.addService(name, service)
        this
    }

    /**
     * get service by name from service container
     *
     * @param name: service name
     * @return: service instance or None if not found
     */
    public func getService<T>(name: String): ?T {
        _services.getService<T>(name)
    }

    private static func readPermFile(path: String): String {
        try (file = File(path, Read)) {
            return String.fromUtf8(readToEnd(file))
        }
        ""
    }

    private static func loadTlsConfig(certFilePath: String, keyFilePath: String, password: ?String): TlsServerConfig {
        let certText = readPermFile(certFilePath)
        let keyText = readPermFile(keyFilePath)

        let certificate = X509Certificate.decodeFromPem(certText)
        let privateKey = PrivateKey.decodeFromPem(keyText, password: password)

        TlsServerConfig(certificate, privateKey)
    }
}
