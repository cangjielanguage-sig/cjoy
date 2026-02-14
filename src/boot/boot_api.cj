/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.boot

import std.fs.{Path, exists}
import std.fs.{File, OpenMode}
import std.io.{readToEnd}
import stdx.net.tls.{TlsServerConfig, CertificateVerifyMode, TlsClientIdentificationMode, TlsVersion}
import stdx.net.http.{ServerBuilder, ServicePoolConfig}
import stdx.crypto.x509.{X509Certificate, PrivateKey}
import cjoy.*
import cjoy.config.*
import cjoy.log.macros.*

/**
 * Callback type before application starts, called after Joy instance is created and before server starts
 *
 * @param cfg Framework configuration object
 * @param joy Joy engine instance
 */
public type JoyFunc = (cfg: JoyConfig, joy: Joy) -> Unit

/**
 * HTTP server callback function type, used after server binds to port or when server shuts down
 */
public type HttpServerFunc = () -> Unit

/**
 * Config extension callback function type, called after config files are loaded
 *
 * @param config Configuration manager instance
 * @param cfgRootPath Configuration file root directory path
 */
public type ConfigExtendFunc = (config: Config, cfgRootPath: String) -> Unit

/**
 * CJoy application bootstrapper.
 *
 * JoyBoot is responsible for:
 * 1. Loading configuration files (command-line arguments, properties, json)
 * 2. Initializing framework configuration
 * 3. Creating Joy engine instance
 * 4. Registering macro-generated middlewares and route handlers
 * 5. Building and starting HTTP server
 *
 * Example usage:
 * ```
 * main(): Int64 {
 *     JoyBoot.of(args).run()
 *     return 0
 * }
 * ```
 *
 * With optional callbacks:
 * ```
 * JoyBoot.of(args)
 *     .cfgPath("./config")
 *     .beforeJoyStart { cfg, joy =>
 *         // Custom initialization
 *     }
 *     .afterBind {
 *         // After server binds
 *     }
 *     .run()
 * ```
 */
public class JoyBoot {
    private var _args: Array<String>
    private var _cfgPath: String
    private var _extendConfig: ?ConfigExtendFunc
    private var _beforeJoyStart: ?JoyFunc
    private var _afterBind: ?HttpServerFunc
    private var _onShutdown: ?HttpServerFunc

    /**
     * Private constructor, use JoyBoot.of() to create instance
     */
    private init(args: Array<String>) {
        this._args = args
        this._cfgPath = ""
        this._extendConfig = None
        this._beforeJoyStart = None
        this._afterBind = None
        this._onShutdown = None
    }

    /**
     * Creates a new JoyBoot instance with the given command-line arguments
     *
     * @param args Command-line arguments
     * @return New JoyBoot instance
     */
    public static func of(args: Array<String>): JoyBoot {
        JoyBoot(args)
    }

    /**
     * Sets the configuration file root path
     *
     * @param path Configuration file root path, default is "./config"
     * @return This JoyBoot instance for method chaining
     */
    public func cfgPath(path: String): JoyBoot {
        this._cfgPath = path
        this
    }

    /**
     * Sets the callback function to extend configuration
     *
     * Called after config files (properties, json) are loaded but before
     * they are used. Can be used to add custom config loaders or
     * modify configuration values.
     *
     * @param fn Callback function that receives Config instance and config root path
     * @return This JoyBoot instance for method chaining
     */
    public func extendConfig(fn: ConfigExtendFunc): JoyBoot {
        this._extendConfig = fn
        this
    }

    /**
     * Sets the callback function before application Joy starts
     *
     * Called after Joy instance is created and before server starts.
     * Can be used for custom configuration and initialization.
     *
     * @param fn Callback function that receives JoyConfig and Joy instance
     * @return This JoyBoot instance for method chaining
     */
    public func beforeJoyStart(fn: JoyFunc): JoyBoot {
        this._beforeJoyStart = fn
        this
    }

    /**
     * Sets the callback function after server binds to port
     *
     * @param fn Callback function executed after successful port binding
     * @return This JoyBoot instance for method chaining
     */
    public func afterBind(fn: HttpServerFunc): JoyBoot {
        this._afterBind = fn
        this
    }

    /**
     * Sets the callback function before server shuts down
     *
     * @param fn Callback function executed before server shutdown
     * @return This JoyBoot instance for method chaining
     */
    public func onShutdown(fn: HttpServerFunc): JoyBoot {
        this._onShutdown = fn
        this
    }

    /**
     * Runs the CJoy application
     *
     * This method executes the full bootstrap process and starts the HTTP server.
     * It will block until the server is stopped.
     */
    public func run(): Unit {
        let config = loadConfig(_args, _cfgPath, _extendConfig)

        let properties = config.bind<JoyProperties>("joy") ?? JoyProperties()
        let name = if (properties.name.isEmpty()) {
            "default"
        } else {
            properties.name
        }

        let joyCfg = createJoyConfig(properties)
        let joy = Joy.create(name: name)

        // 注册生成的handlers
        JoyMiddlewares.registerTo(joy)
        JoyHandlers.registerTo(joy)

        _beforeJoyStart?(joyCfg, joy)

        // 构建 ServerBuilder
        let serverBuilder = createServerBuilder(properties)
        if (let Some(fn) <- _afterBind) {
            serverBuilder.afterBind(fn)
        }
        if (let Some(fn) <- _onShutdown) {
            serverBuilder.onShutdown(fn)
        }
        joy.run(serverBuilder)
    }
}

private func loadConfig(args: Array<String>, cfgPath: String, extendConfig: ?ConfigExtendFunc): Config {
    // 配置根目录
    let cfgRootPath = if (cfgPath.isEmpty()) {
        "./config"
    } else {
        cfgPath
    }

    // 配置加载
    let config = ConfigManager.INSTANCE;
    // 命令行参数
    let argLoader = ArgConfigLoader(args)
    config.addLoader(argLoader)
    let profile = config.getValue("joy.profile", "")
    @JoyLogInfo("joy config profile=${profile}")

    // Properties & Json
    loadPropertiesConfig(config, cfgRootPath, profile)
    loadJsonConfig(config, cfgRootPath, profile)

    extendConfig?(config, cfgRootPath)

    config
}

private func loadPropertiesConfig(config: Config, cfgRootPath: String, profile: String): Unit {
    let fileName = if (profile.isEmpty()) {
        "joy.properties"
    } else {
        "joy-${profile}.properties"
    }

    let filePath = Path(cfgRootPath).join(fileName)
    let filePath2 = Path(cfgRootPath).join("config").join(fileName)
    if (exists(filePath2)) {
        @JoyLogInfo("find properties config file ${filePath2}")
        config.addLoader(PropertiesConfigLoader(filePath2.toString(), priorityNum: 1))
    }
    if (exists(filePath)) {
        @JoyLogInfo("find properties config file ${filePath}")
        config.addLoader(PropertiesConfigLoader(filePath.toString(), priorityNum: 2))
    }
}

private func loadJsonConfig(config: Config, cfgRootPath: String, profile: String): Unit {
    let fileName = if (profile.isEmpty()) {
        "joy.json"
    } else {
        "joy-${profile}.json"
    }

    let filePath = Path(cfgRootPath).join(fileName)
    let filePath2 = Path(cfgRootPath).join("config").join(fileName)
    if (exists(filePath2)) {
        @JoyLogInfo("find json config file ${filePath2}")
        config.addLoader(JsonConfigLoader(filePath2.toString(), priorityNum: 5))
    }
    if (exists(filePath)) {
        @JoyLogInfo("find json config file ${filePath}")
        config.addLoader(JsonConfigLoader(filePath.toString(), priorityNum: 6))
    }
}

private func createJoyConfig(properties: JoyProperties): JoyConfig {
    @JoyLogInfo("server.http.caseInsensitive=${properties.server.http.caseInsensitive}")
    @JoyLogInfo("server.http.escapeAddedRoutes=${properties.server.http.escapeAddedRoutes}")
    @JoyLogInfo("server.http.remoteIpHeaders=${properties.server.http.remoteIpHeaders}")
    @JoyLogInfo("server.http.maxRequestBodySize=${properties.server.http.maxRequestBodySize}")
    let caseInsensitive = properties.server.http.caseInsensitive
    let escapeAddedRoutes = properties.server.http.escapeAddedRoutes
    let remoteIpHeaders = properties.server.http.remoteIpHeaders.split(",")
    let maxRequestBodySize = properties.server.http.maxRequestBodySize
    JoyConfig(remoteIPHeaders: remoteIpHeaders, caseInsensitive: caseInsensitive, escapeAddedRoutes: escapeAddedRoutes,
        maxRequestBodySize: maxRequestBodySize)
}

private func createServerBuilder(properties: JoyProperties): ServerBuilder {
    if (properties.server.http.h2.enabled) {
        properties.server.tls.enabled = true
        if (properties.server.tls.keyFile.isEmpty()) {
            throw IllegalArgumentException("http2 should enable tls set keyFile")
        }
        if (properties.server.tls.certFile.isEmpty()) {
            throw IllegalArgumentException("http2 should enable tls set certFile")
        }
    }

    // http
    @JoyLogInfo("server.http.maxRequestBodySize=${properties.server.http.maxRequestBodySize}")
    @JoyLogInfo("server.http.maxRequestHeaderSize=${properties.server.http.maxRequestHeaderSize}")
    @JoyLogInfo("server.http.readHeaderTimeout=${properties.server.http.readHeaderTimeout}ms")
    @JoyLogInfo("server.http.readTimeout=${properties.server.http.readTimeout}ms")
    @JoyLogInfo("server.http.writeTimeout=${properties.server.http.writeTimeout}ms")
    let sb = ServerBuilder()
        .addr(properties.server.address)
        .port(properties.server.port)
        .maxRequestBodySize(properties.server.http.maxRequestBodySize)
        .maxRequestHeaderSize(properties.server.http.maxRequestHeaderSize)
        .readHeaderTimeout(Duration.millisecond * properties.server.http.readHeaderTimeout)
        .readTimeout(Duration.millisecond * properties.server.http.readTimeout)
        .writeTimeout(Duration.millisecond * properties.server.http.writeTimeout)

    // tls
    @JoyLogInfo("server.tls.enabled=${properties.server.tls.enabled}")
    if (properties.server.tls.enabled) {
        var tlsConfig = loadTlsConfig(properties.server.tls)
        if (properties.server.http.h2.enabled) {
            tlsConfig.supportedAlpnProtocols = ["h2"]
        }
        sb.tlsConfig(tlsConfig)
        loadHttp2Config(sb, properties.server.http.h2)
    }

    // pool
    loadServicePoolConfig(sb, properties.server.pool)
    sb
}

private func loadHttp2Config(sb: ServerBuilder, h2Cfg: JoyServerHttp2Properties): Unit {
    @JoyLogInfo("server.http.h2.enabled=${h2Cfg.enabled}")
    if (!h2Cfg.enabled) {
        return
    }
    @JoyLogInfo("server.http.h2.maxHeaderListSize=${h2Cfg.maxHeaderListSize}")
    @JoyLogInfo("server.http.h2.maxFrameSize=${h2Cfg.maxFrameSize}")
    @JoyLogInfo("server.http.h2.maxConcurrentStreams=${h2Cfg.maxConcurrentStreams}")
    @JoyLogInfo("server.http.h2.initialWindowSize=${h2Cfg.initialWindowSize}")
    @JoyLogInfo("server.http.h2.headerTableSize=${h2Cfg.headerTableSize}")
    @JoyLogInfo("server.http.h2.enableConnectProtocol=${h2Cfg.enableConnectProtocol}")
    sb
        .maxHeaderListSize(h2Cfg.maxHeaderListSize)
        .maxFrameSize(h2Cfg.maxFrameSize)
        .maxConcurrentStreams(h2Cfg.maxConcurrentStreams)
        .initialWindowSize(h2Cfg.initialWindowSize)
        .headerTableSize(h2Cfg.headerTableSize)
        .enableConnectProtocol(h2Cfg.enableConnectProtocol)
}

private func loadServicePoolConfig(sb: ServerBuilder, poolCfg: JoyServerPoolProperties): Unit {
    @JoyLogInfo("server.pool.capacity=${poolCfg.capacity}")
    @JoyLogInfo("server.pool.queueCapacity=${poolCfg.queueCapacity}")
    @JoyLogInfo("server.pool.preheat=${poolCfg.preheat}")
    let cfg = ServicePoolConfig(capacity: poolCfg.capacity, queueCapacity: poolCfg.queueCapacity,
        preheat: poolCfg.preheat)
    sb.servicePoolConfig(cfg)
}

private func readPermFile(path: String): String {
    try (file = File(path, Read)) {
        return String.fromUtf8(readToEnd(file))
    }
    ""
}

private func loadTlsConfig(tlsCfg: JoyServerTlsProperties): TlsServerConfig {
    @JoyLogInfo("server.tls.certFile=${tlsCfg.certFile}")
    let certText = readPermFile(tlsCfg.certFile)
    @JoyLogInfo("server.tls.keyFile=${tlsCfg.keyFile}")
    let keyText = readPermFile(tlsCfg.keyFile)
    let password: ?String = if (tlsCfg.keyPassword.isEmpty()) {
        None
    } else {
        tlsCfg.keyPassword
    }

    let certificate = X509Certificate.decodeFromPem(certText)
    let privateKey = PrivateKey.decodeFromPem(keyText, password: password)

    var tlsServerCfg = TlsServerConfig(certificate, privateKey)
    @JoyLogInfo("server.tls.trustAll=${tlsCfg.trustAll}")
    if (tlsCfg.trustAll) {
        @JoyLogWarn("tls trust all is not security")
        tlsServerCfg.verifyMode = CertificateVerifyMode.TrustAll
    }

    @JoyLogInfo("server.tls.clientAuth=${tlsCfg.clientAuth}")
    if (tlsCfg.clientAuth) {
        tlsServerCfg.clientIdentityRequired = TlsClientIdentificationMode.Required
    }

    @JoyLogInfo("server.tls.ciphers=${tlsCfg.ciphers}")
    let ciphers = tlsCfg.ciphers.split(",")
    @JoyLogInfo("server.tls.version=${tlsCfg.version}")
    match (tlsCfg.version) {
        case "1.2" =>
            tlsServerCfg.minVersion = TlsVersion.V1_2
            if (ciphers.size > 0) {
                tlsServerCfg.cipherSuitesV1_2 = ciphers
            }

        case "1.3" =>
            tlsServerCfg.minVersion = TlsVersion.V1_3
            if (ciphers.size > 0) {
                tlsServerCfg.cipherSuitesV1_3 = ciphers
            }
        case _ => ()
    }

    tlsServerCfg
}
