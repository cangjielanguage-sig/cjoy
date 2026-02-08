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
 * Main entry function to start a CJoy application
 *
 * This function is responsible for:
 * 1. Loading configuration files (command-line arguments, properties, json)
 * 2. Initializing framework configuration
 * 3. Creating Joy engine instance
 * 4. Registering macro-generated middlewares and route handlers
 * 5. Building and starting HTTP server
 *
 * @param args Command-line arguments
 * @param cfgPath Configuration file root path, default is "./config"
 * @param beforeJoyStart Callback function before application starts, can be used for custom configuration
 * @param afterBind Callback function after server binds to port
 * @param onShutdown Callback function before server shuts down
 */
public func joyBoot(args: Array<String>, cfgPath!: String = "", beforeJoyStart!: ?JoyFunc = None,
    afterBind!: ?HttpServerFunc = None, onShutdown!: ?HttpServerFunc = None): Unit {
    let config = loadConfig(args, cfgPath)

    let properties = config.bind<JoyProperties>("joy") ?? JoyProperties()
    let name = if (properties.name.isEmpty()) {
        "default"
    } else {
        properties.name
    }

    let joyCfg = creatJoyConfig(properties)
    let joy = Joy.create(name: name)

    // 注册生成的handlers
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)

    beforeJoyStart?(joyCfg, joy)

    // 构建 ServerBuilder
    let serverBuidler = createServerBuidler(properties)
    if (let Some(fn) <- afterBind) {
        serverBuidler.afterBind(fn)
    }
    if (let Some(fn) <- onShutdown) {
        serverBuidler.onShutdown(fn)
    }
    joy.run(serverBuidler)
}

private func loadConfig(args: Array<String>, cfgPath: String): Config {
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

private func creatJoyConfig(properties: JoyProperties): JoyConfig {
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

private func createServerBuidler(properties: JoyProperties): ServerBuilder {
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
