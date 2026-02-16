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
 */
public class JoyConfig {
    /**
     * Creates a JoyConfig instance with default or specified values
     *
     * @param remoteIPHeaders List of header names to check for real client IP (e.g., "X-Forwarded-For")
     * @param enableDebugLog Enable debug logging (deprecated, use JoyLoggerFactory instead)
     * @param caseInsensitive Whether route matching is case-insensitive
     * @param escapeAddedRoutes Whether to escape special characters in route patterns
     * @param notFoundHandler Handler for 404 Not Found responses
     * @param methodNotAllowedHandler Handler for 405 Method Not Allowed responses
     * @param maxRequestBodySize Maximum request body size in bytes (default: 32MB)
     */
    public JoyConfig(
        public let remoteIPHeaders!: Array<String> = [],
        @Deprecated["Use JoyLoggerFactory", since: "v0.90.0"] public var enableDebugLog!: Bool = true,
        public let caseInsensitive!: Bool = false,
        public let escapeAddedRoutes!: Bool = false,
        public var notFoundHandler!: JoyRequestHandler = JoyNotFoundHandler(),
        public var methodNotAllowedHandler!: JoyRequestHandler = JoyMethodNotAllowedHandler(),
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
     * Returns the default Joy engine instance
     *
     * @return The default Joy engine instance
     */
    public static func default(): Joy {
        // ~_~，bad sdk api, not have computeIfAbsent func in map
        // func is not atomic
        if (_INSTANCES.contains("default")) {
            return _INSTANCES.get("default").getOrThrow()
        }
        return create()
    }

    /**
     * Creates a Joy engine instance with default configuration
     *
     * @param name Instance name (default: "default")
     * @return New Joy engine instance
     */
    public static func create(name!: String = "default"): Joy {
        create(JoyConfig(), name: name)
    }

    /**
     * Creates a Joy engine instance with custom configuration
     *
     * @param config Global configuration
     * @param name Instance name (default: "default")
     * @return New Joy engine instance
     * @throws IllegalArgumentException If an instance with the same name already exists
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
     * Runs the HTTP server at the specified address and port
     *
     * @param addr Listen address
     * @param port Listen port
     */
    public func run(addr: String, port: UInt16): Unit {
        run(ServerBuilder().addr(addr).port(port))
    }

    /**
     * Runs the HTTPS server at the specified address and port with certificate files
     *
     * @param addr Listen address
     * @param port Listen port
     * @param certFilePath Certificate server file path
     * @param keyFilePath Certificate server key file path
     * @param password Password of certificate server key (optional)
     * @param h2 Whether to run as HTTP/2 (default: false)
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
     * Runs the HTTP(S) server using a ServerBuilder
     *
     * @param serverBuilder Server builder with configured options
     */
    public func run(serverBuilder: ServerBuilder): Unit {
        let server = serverBuilder
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
     * Shuts down the server
     *
     * @param gracefully Whether to shutdown gracefully (default: true)
     */
    public func shutdown(gracefully!: Bool = true): Unit {
        if (let Some(server) <- _server) {
            if (gracefully) {
                server.closeGracefully()
            } else {
                server.close()
            }
            _server = None
        }
        _INSTANCES.remove(this.name)
    }

    /**
     * Adds a service to the Joy instance
     *
     * @param name Service unique name
     * @param service Service instance object
     * @return Current Joy instance for method chaining
     */
    public func addService(name: String, service: Any): Joy {
        _services.addService(name, service)
        this
    }

    /**
     * Gets a service by name from the service container
     *
     * @param name Service name
     * @return Service instance or None if not found
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
