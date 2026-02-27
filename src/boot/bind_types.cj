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

import std.deriving.Derive
import cjoy.bind.*
import cjoy.bind.macros.*

/**
 * CJoy 应用的主配置类，用于加载和存储应用配置
 *
 * 此类通过 `@Bind` 注解支持配置文件绑定，包含基本应用信息和服务器配置。
 */
@Bind
@Derive[ToString]
public class JoyProperties {
    /** 应用名称，默认值为 "default" */
    public var name: String = "default"

    /** 服务器配置 */
    public var server: JoyServerProperties = JoyServerProperties()

    /** CJLog 配置文件路径 */
    public var cjlog: JoyCjlogProperties = JoyCjlogProperties()

    /** 日志记录器配置 */
    public var loggers: Array<JoyLoggerProperties> = []
}

/**
 * CJLog 配置类，用于配置 CJLog 日志框架
 */
@Bind
@Derive[ToString]
public class JoyCjlogProperties {
    /** CJLog 配置文件路径，若不为空则启动时加载该配置 */
    public var path: String = ""
}

/**
 * 日志记录器配置类，用于配置指定名称的日志记录器的日志级别
 */
@Bind
@Derive[ToString]
public class JoyLoggerProperties {
    /** 日志记录器名称 */
    public var name: String = ""

    /** 日志级别 (e.g., debug, info, warn, error) */
    public var level: String = "info"
}

/**
 * 服务器配置类，包含服务器地址、端口、TLS、HTTP 和线程池配置
 */
@Bind
@Derive[ToString]
public class JoyServerProperties {
    /** 服务器监听地址，默认值为 "127.0.0.1" */
    public var address: String = "127.0.0.1"

    /** 服务器监听端口，默认值为 18880 */
    public var port: UInt16 = 18880

    /** TLS 配置 */
    public var tls: JoyServerTlsProperties = JoyServerTlsProperties()

    /** HTTP 配置 */
    public var http: JoyServerHttpProperties = JoyServerHttpProperties()

    /** 线程池配置 */
    public var pool: JoyServerPoolProperties = JoyServerPoolProperties()
}

/**
 * TLS 配置类，用于配置 HTTPS 和 TLS 相关参数
 */
@Bind
@Derive[ToString]
public class JoyServerTlsProperties {
    /** 是否启用 TLS (HTTPS)，默认值为 false */
    public var enabled: Bool = false

    /** TLS 版本，支持 "1.2" 或 "1.3"，默认值为空 */
    public var version: String = "" // 1.2, 1.3

    /** 密码套件列表，逗号分隔，默认值为空 */
    public var ciphers: String = "" // RSA_PKCS1_SHA256, RSA_PKCS1_SHA384 等..

    /** 是否启用客户端认证，默认值为 false */
    public var clientAuth: Bool = false

    /** 私钥密码，默认值为空 */
    public var keyPassword: String = ""

    /** 私钥文件路径，默认值为空 */
    public var keyFile: String = ""

    /** 证书文件路径，默认值为空 */
    public var certFile: String = ""

    /** 信任证书文件路径，默认值为空 */
    public var trustFile: String = ""

    /** 是否信任所有客户端证书，默认值为 false */
    public var trustAll: Bool = false
}

/**
 * HTTP 服务器配置类，包含 HTTP 协议相关参数
 */
@Bind
@Derive[ToString]
public class JoyServerHttpProperties {
    /** 读取请求头超时时间（毫秒），默认值为 0 */
    public var readHeaderTimeout: Int64 = 0

    /** 读取请求体超时时间（毫秒），默认值为 0 */
    public var readTimeout: Int64 = 0

    /** 写入响应超时时间（毫秒），默认值为 0 */
    public var writeTimeout: Int64 = 0

    /** 路由匹配是否不区分大小写，默认值为 false */
    public var caseInsensitive: Bool = false

    /** 是否转义添加的路由，默认值为 false */
    public var escapeAddedRoutes: Bool = false

    /** 用于获取真实客户端 IP 的请求头列表，逗号分隔，默认值为空 */
    public var remoteIpHeaders: String = ""

    /** 最大请求体大小（字节），默认值为 32MB */
    public var maxRequestBodySize: Int64 = 32 * 1024 * 1024

    /** 最大请求头大小（字节），默认值为 0 */
    public var maxRequestHeaderSize: Int64 = 0

    /** HTTP/2 配置 */
    public var h2: JoyServerHttp2Properties = JoyServerHttp2Properties()
}

/**
 * HTTP/2 服务器配置类，包含 HTTP/2 协议相关参数
 */
@Bind
@Derive[ToString]
public class JoyServerHttp2Properties {
    /** 是否启用 HTTP/2 协议，默认值为 false */
    public var enabled: Bool = false

    /** 是否启用连接协议，默认值为 false */
    public var enableConnectProtocol: Bool = false

    /** 头部表大小，默认值为 4096 */
    public var headerTableSize: UInt32 = 4096

    /** 初始窗口大小，默认值为 0 */
    public var initialWindowSize: UInt32 = 0

    /** 最大并发流数，默认值为 100 */
    public var maxConcurrentStreams: UInt32 = 100

    /** 最大帧大小，默认值为 16384 */
    public var maxFrameSize: UInt32 = 16384

    /** 最大头部列表大小，默认值为 UInt32.Max */
    public var maxHeaderListSize: UInt32 = UInt32.Max
}

/**
 * 服务器线程池配置类，包含线程池容量、队列大小和预热参数
 */
@Bind
@Derive[ToString]
public class JoyServerPoolProperties {
    /** 线程池容量，默认值为 10000 */
    public var capacity: Int64 = 10 ** 4

    /** 任务队列容量，默认值为 10000 */
    public var queueCapacity: Int64 = 10 ** 4

    /** 预热线程数，默认值为 0 */
    public var preheat: Int64 = 0
}
