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
 * Main configuration class for CJoy application, used to load and store application configuration
 *
 * This class supports configuration file binding through `@Bind` annotation, containing basic application information and server configuration.
 */
@Bind
@Derive[ToString]
public class JoyProperties {
    /** Application name, default value is "default" */
    public var name: String = "default"

    /** Server configuration */
    public var server: JoyServerProperties = JoyServerProperties()
}

/**
 * Server configuration class, containing server address, port, TLS, HTTP and thread pool configuration
 */
@Bind
@Derive[ToString]
public class JoyServerProperties {
    /** Server listen address, default value is "127.0.0.1" */
    public var address: String = "127.0.0.1"

    /** Server listen port, default value is 18880 */
    public var port: UInt16 = 18880

    /** TLS configuration */
    public var tls: JoyServerTlsProperties = JoyServerTlsProperties()

    /** HTTP configuration */
    public var http: JoyServerHttpProperties = JoyServerHttpProperties()

    /** Thread pool configuration */
    public var pool: JoyServerPoolProperties = JoyServerPoolProperties()
}

/**
 * TLS configuration class, used to configure HTTPS and TLS related parameters
 */
@Bind
@Derive[ToString]
public class JoyServerTlsProperties {
    /** Whether to enable TLS (HTTPS), default value is false */
    public var enabled: Bool = false

    /** TLS version, supports "1.2" or "1.3", default value is empty */
    public var version: String = "" // 1.2, 1.3

    /** Cipher suite list, comma-separated, default value is empty */
    public var ciphers: String = "" // RSA_PKCS1_SHA256, RSA_PKCS1_SHA384 etc..

    /** Whether to enable client authentication, default value is false */
    public var clientAuth: Bool = false

    /** Private key password, default value is empty */
    public var keyPassword: String = ""

    /** Private key file path, default value is empty */
    public var keyFile: String = ""

    /** Certificate file path, default value is empty */
    public var certFile: String = ""

    /** Trust certificate file path, default value is empty */
    public var trustFile: String = ""

    /** Whether to trust all client certificates, default value is false */
    public var trustAll: Bool = false
}

/**
 * HTTP server configuration class, containing HTTP protocol related parameters
 */
@Bind
@Derive[ToString]
public class JoyServerHttpProperties {
    /** Read request header timeout (milliseconds), default value is 0 */
    public var readHeaderTimeout: Int64 = 0

    /** Read request body timeout (milliseconds), default value is 0 */
    public var readTimeout: Int64 = 0

    /** Write response timeout (milliseconds), default value is 0 */
    public var writeTimeout: Int64 = 0

    /** Whether route matching is case-insensitive, default value is false */
    public var caseInsensitive: Bool = false

    /** Whether to escape added routes, default value is false */
    public var escapeAddedRoutes: Bool = false

    /** Request header list for getting real client IP, comma-separated, default value is empty */
    public var remoteIpHeaders: String = ""

    /** Maximum request body size (bytes), default value is 32MB */
    public var maxRequestBodySize: Int64 = 32 * 1024 * 1024

    /** Maximum request header size (bytes), default value is 0 */
    public var maxRequestHeaderSize: Int64 = 0

    /** HTTP/2 configuration */
    public var h2: JoyServerHttp2Properties = JoyServerHttp2Properties()
}

/**
 * HTTP/2 server configuration class, containing HTTP/2 protocol related parameters
 */
@Bind
@Derive[ToString]
public class JoyServerHttp2Properties {
    /** Whether to enable HTTP/2 protocol, default value is false */
    public var enabled: Bool = false

    /** Whether to enable connect protocol, default value is false */
    public var enableConnectProtocol: Bool = false

    /** Header table size, default value is 4096 */
    public var headerTableSize: UInt32 = 4096

    /** Initial window size, default value is 0 */
    public var initialWindowSize: UInt32 = 0

    /** Maximum concurrent streams, default value is 100 */
    public var maxConcurrentStreams: UInt32 = 100

    /** Maximum frame size, default value is 16384 */
    public var maxFrameSize: UInt32 = 16384

    /** Maximum header list size, default value is UInt32.Max */
    public var maxHeaderListSize: UInt32 = UInt32.Max
}

/**
 * Server thread pool configuration class, containing thread pool capacity, queue size and preheat parameters
 */
@Bind
@Derive[ToString]
public class JoyServerPoolProperties {
    /** Thread pool capacity, default value is 10000 */
    public var capacity: Int64 = 10 ** 4

    /** Task queue capacity, default value is 10000 */
    public var queueCapacity: Int64 = 10 ** 4

    /** Preheat thread count, default value is 0 */
    public var preheat: Int64 = 0
}
