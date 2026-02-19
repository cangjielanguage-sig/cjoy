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
import stdx.log.LogLevel
import cjoy.*
import cjoy.config.*
import cjoy.log.macros.*

/**
 * 应用程序启动前的回调类型，在 Joy 实例创建后、服务器启动前调用
 *
 * @param cfg 框架配置对象
 * @param joy Joy 引擎实例
 */
public type JoyFunc = (cfg: JoyConfig, joy: Joy) -> Unit

/**
 * HTTP 服务器回调函数类型，在服务器绑定到端口后或服务器关闭时使用
 */
public type HttpServerFunc = () -> Unit

/**
 * 配置扩展回调函数类型，在配置文件加载后调用
 *
 * @param config 配置管理器实例
 * @param cfgRootPath 配置文件根目录路径
 */
public type ConfigExtendFunc = (config: Config, cfgRootPath: String) -> Unit

/**
 * CJoy 应用程序引导器。
 *
 * JoyBoot 负责：
 * 1. 加载配置文件（命令行参数、properties、json）
 * 2. 初始化框架配置
 * 3. 创建 Joy 引擎实例
 * 4. 注册宏生成的中间件和路由处理器
 * 5. 构建并启动 HTTP 服务器
 *
 * 示例用法：
 * ```
 * main(): Int64 {
 *     JoyBoot.of(args).run()
 *     return 0
 * }
 * ```
 *
 * 使用可选回调：
 * ```
 * JoyBoot.of(args)
 *     .cfgPath("./config")
 *     .beforeJoyStart { cfg, joy =>
 *         // 自定义初始化
 *     }
 *     .afterBind {
 *         // 服务器绑定后
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
     * 私有构造函数，使用 JoyBoot.of() 创建实例
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
     * 使用给定的命令行参数创建新的 JoyBoot 实例
     *
     * @param args 命令行参数
     * @return 新的 JoyBoot 实例
     */
    public static func of(args: Array<String>): JoyBoot {
        JoyBoot(args)
    }

    /**
     * 设置配置文件根路径
     *
     * @param path 配置文件根路径，默认为 "./config"
     * @return 此 JoyBoot 实例，用于方法链式调用
     */
    public func cfgPath(path: String): JoyBoot {
        this._cfgPath = path
        this
    }

    /**
     * 设置扩展配置的回调函数
     *
     * 在配置文件（properties、json）加载后、使用前调用。
     * 可用于添加自定义配置加载器或修改配置值。
     *
     * @param fn 接收 Config 实例和配置根路径的回调函数
     * @return 此 JoyBoot 实例，用于方法链式调用
     */
    public func extendConfig(fn: ConfigExtendFunc): JoyBoot {
        this._extendConfig = fn
        this
    }

    /**
     * 设置应用程序 Joy 启动前的回调函数
     *
     * 在 Joy 实例创建后、服务器启动前调用。
     * 可用于自定义配置和初始化。
     *
     * @param fn 接收 JoyConfig 和 Joy 实例的回调函数
     * @return 此 JoyBoot 实例，用于方法链式调用
     */
    public func beforeJoyStart(fn: JoyFunc): JoyBoot {
        this._beforeJoyStart = fn
        this
    }

    /**
     * 设置服务器绑定到端口后的回调函数
     *
     * @param fn 成功绑定端口后执行的回调函数
     * @return 此 JoyBoot 实例，用于方法链式调用
     */
    public func afterBind(fn: HttpServerFunc): JoyBoot {
        this._afterBind = fn
        this
    }

    /**
     * 设置服务器关闭前的回调函数
     *
     * @param fn 服务器关闭前执行的回调函数
     * @return 此 JoyBoot 实例，用于方法链式调用
     */
    public func onShutdown(fn: HttpServerFunc): JoyBoot {
        this._onShutdown = fn
        this
    }

    /**
     * 运行 CJoy 应用程序
     *
     * 此方法执行完整的引导过程并启动 HTTP 服务器。
     * 它会阻塞直到服务器停止。
     */
    public func run(): Unit {
        let config = loadConfig(_args, _cfgPath, _extendConfig)

        let properties = config.bind<JoyProperties>("joy") ?? JoyProperties()
        let name = if (properties.name.isEmpty()) {
            "default"
        } else {
            properties.name
        }

        // 配置日志级别
        configureLoggers(properties.loggers)

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

private func configureLoggers(loggers: Array<JoyLoggerProperties>): Unit {
    for (loggerCfg in loggers) {
        if (loggerCfg.name.isEmpty()) {
            continue
        }

        // 尝试获取 Logger 实例
        if (let Some(logger) <- JoyLoggerFactory.getLogger(loggerCfg.name)) {
            // 将字符串级别转换为 LogLevel
            let level = parseLogLevel(loggerCfg.level)
            logger.level = level
            @JoyLogInfo("Set logger '${loggerCfg.name}' level to '${level}'")
        } else {
            // 如果 Logger 实例尚未创建，先创建它
            let logger = JoyLoggerFactory.createLogger(loggerCfg.name)
            let level = parseLogLevel(loggerCfg.level)
            logger.level = level
            @JoyLogInfo("Create and set logger '${loggerCfg.name}' level to '${level}'")
        }
    }
}

private func parseLogLevel(levelStr: String): LogLevel {
    match (levelStr.toAsciiLower()) {
        case "off" => LogLevel.OFF
        case "fatal" => LogLevel.FATAL
        case "error" => LogLevel.ERROR
        case "warn" => LogLevel.WARN
        case "info" => LogLevel.INFO
        case "debug" => LogLevel.DEBUG
        case "trace" => LogLevel.TRACE
        case "all" => LogLevel.ALL
        case _ =>
            @JoyLogWarn("Unknown log level '${levelStr}', defaulting to INFO")
            LogLevel.INFO
    }
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
