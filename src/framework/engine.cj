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
 * CJoy Web 服务器的配置选项
 */
public class JoyConfig {
    /**
     * 使用默认值或指定值创建 JoyConfig 实例
     *
     * @param remoteIPHeaders 用于检查真实客户端 IP 的头部名称列表（例如 "X-Forwarded-For"）
     * @param enableDebugLog 启用调试日志（已弃用，请使用 JoyLoggerFactory）
     * @param caseInsensitive 路由匹配是否区分大小写
     * @param escapeAddedRoutes 是否对路由模式中的特殊字符进行转义
     * @param notFoundHandler 404 Not Found 响应的处理器
     * @param methodNotAllowedHandler 405 Method Not Allowed 响应的处理器
     * @param maxRequestBodySize 最大请求体大小，单位为字节（默认：32MB）
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
 * net.http.Server 的包装类
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
     * 返回 net.http.Server 实例
     */
    public prop server: Server {
        get() {
            _server.getOrThrow()
        }
    }

    /**
     * 返回默认的 Joy 引擎实例
     *
     * @return 默认的 Joy 引擎实例
     */
    public static func default(): Joy {
        // ~_~，糟糕的 SDK API，map 中没有 computeIfAbsent 函数
        // 函数不是原子的
        if (_INSTANCES.contains("default")) {
            return _INSTANCES.get("default").getOrThrow()
        }
        return create()
    }

    /**
     * 使用默认配置创建 Joy 引擎实例
     *
     * @param name 实例名称（默认："default"）
     * @return 新的 Joy 引擎实例
     */
    public static func create(name!: String = "default"): Joy {
        create(JoyConfig(), name: name)
    }

    /**
     * 使用自定义配置创建 Joy 引擎实例
     *
     * @param config 全局配置
     * @param name 实例名称（默认："default"）
     * @return 新的 Joy 引擎实例
     * @throws IllegalArgumentException 如果已存在相同名称的实例
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
     * 在指定地址和端口运行 HTTP 服务器
     *
     * @param addr 监听地址
     * @param port 监听端口
     */
    public func run(addr: String, port: UInt16): Unit {
        run(ServerBuilder().addr(addr).port(port))
    }

    /**
     * 使用证书文件在指定地址和端口运行 HTTPS 服务器
     *
     * @param addr 监听地址
     * @param port 监听端口
     * @param certFilePath 证书服务器文件路径
     * @param keyFilePath 证书服务器密钥文件路径
     * @param password 证书服务器密钥密码（可选）
     * @param h2 是否以 HTTP/2 模式运行（默认：false）
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
     * 使用 ServerBuilder 运行 HTTP(S) 服务器
     *
     * @param serverBuilder 配置了选项的服务器构建器
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
     * 关闭服务器
     *
     * @param gracefully 是否优雅地关闭（默认：true）
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
     * 向 Joy 实例添加服务
     *
     * @param name 服务唯一名称
     * @param service 服务实例对象
     * @return 当前 Joy 实例，用于方法链式调用
     */
    public func addService(name: String, service: Any): Joy {
        _services.addService(name, service)
        this
    }

    /**
     * 从服务容器中按名称获取服务
     *
     * @param name 服务名称
     * @return 服务实例，如果未找到则返回 None
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
