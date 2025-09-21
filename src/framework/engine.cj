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

import std.collection.concurrent.ConcurrentHashMap
import std.fs.{File, OpenMode}
import std.io.{readToEnd}
import stdx.net.tls.TlsServerConfig
import stdx.net.http.{Server, ServerBuilder}
import stdx.crypto.x509.{X509Certificate, PrivateKey}
import cjoy.log.LogTool

public const VERSION = "v0.60.0"
const LOGO = ##"
 ________        ___  ________      ___    ___ 
|\   ____\      |\  \|\   __  \    |\  \  /  /|
\ \  \___|      \ \  \ \  \|\  \   \ \  \/  / /
 \ \  \       __ \ \  \ \  \\\  \   \ \    / / 
  \ \  \____ |\  \\_\  \ \  \\\  \   \/  /  /  
   \ \_______\ \________\ \_______\__/  / /    
    \|_______|\|________|\|_______|\___/ /     
                                  \|___|/          VERSION
"##

/**
 * joy config
 */
public class JoyConfig {
    // the trust remote ip headers
    public JoyConfig(
        public let remoteIPHeaders!: Array<String> = [],

        // enable debug log
        public var enableDebugLog!: Bool = true,

        // whether case insensitive when add route handler
        public let caseInsensitive!: Bool = false,

        // whether escape the path when add route handler
        public let escapeAddedRoutes!: Bool = false,

        // set not found handler 
        public let notFoundHandler!: JoyRequestHandler = JoyNotFoundHandler(),

        // set method not allowed handler 
        public let methodNotAllowedHandler!: JoyRequestHandler = JoyMethodNotAllowedHandler()
    ) {}
}

/**
 * a wrapper for net.http.Server
 */
public class Joy {
    private static let _INSTANCES: ConcurrentHashMap<String, Joy> = ConcurrentHashMap()
    private var _server: ?Server = None
    private let _services: ServiceConainter = ServiceConainter()

    public let config: JoyConfig
    public let name: String
    public let router: JoyRouters

    private init(config: JoyConfig, name: String) {
        this.config = config
        this.name = name
        router = JoyRouteGroup(config, _services)
        LogTool.info(LOGO.replace("VERSION", VERSION))
    }

    /**
     * return the net.http.Server
     */
    public prop server: Server {
        get() {
            _server.getOrThrow()
        }
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
        return create()
    }

    /**
     * create Joy engine instance by default config
     *
     * @parame name: the instance name
     * @return the instance of Joy
     */
    public static func create(name!: String = "default"): Joy {
        create(JoyConfig(), name: name)
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
        _INSTANCES.add(name, joy)
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
     * run https server at address:port with certificate files
     *
     * @param addr: the listen address
     * @param port: the listen port
     * @param certFilePath: the certificate server file path
     * @param keyFilePath: the certificate server key file path
     * @param h2: run as http2
     */
    public func run(addr: String, port: UInt16, certFilePath: String, keyFilePath: String, h2!: Bool = false): Unit {
        var tlsConfig = loadTlsConfig(certFilePath, keyFilePath)
        if (h2) {
            tlsConfig.supportedAlpnProtocols = ["h2"]
        }
        run(ServerBuilder().addr(addr).port(port).tlsConfig(tlsConfig))
    }

    /**
     * run http(s) server by ServerBuilder
     *
     * @param serverBuidler: the server buidler
     */
    public func run(serverBuidler: ServerBuilder): Unit {
        let server = serverBuidler.distributor(router.distributor).logger(LogTool.logger).build()
        if (config.enableDebugLog) {
            LogTool.enableDebugLog()
        }
        _server = Some(server)
        LogTool.info("[Joy#run] run cjoy app ${name}, bind at ${server.addr}:${server.port}")
        LogTool.info("[Joy#run] route tree:\n${router.dump()}")
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
        _INSTANCES.remove(this.name)
    }

    /**
     * add a service to the joy instance
     *
     * @param name: the service unqiue name
     * @param service : the service instance object
     */
    public func addService(name: String, service: Any) {
        _services.addService(name, service)
    }

    private static func readPermFile(path: String): String {
        try (file = File(path, Read)) {
            return String.fromUtf8(readToEnd(file))
        }
        ""
    }

    private static func loadTlsConfig(certFilePath: String, keyFilePath: String): TlsServerConfig {
        let certText = readPermFile(certFilePath)
        let keyText = readPermFile(keyFilePath)

        let certificate = X509Certificate.decodeFromPem(certText)
        let privateKey = PrivateKey.decodeFromPem(keyText)

        TlsServerConfig(certificate, privateKey)
    }
}
