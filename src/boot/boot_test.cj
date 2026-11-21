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

import std.unittest.testmacro.*
import stdx.log.LogLevel
import stdx.net.tls.common.TlsVersion
import cjoy.config.*

@Test
public class JoyBootTestCaseSuit {
    /**
     * 测试日志级别解析 - 验证大小写不敏感及未知级别回退到 INFO
     */
    @TestCase
    public func testParseLogLevel(): Unit {
        @Assert(parseLogLevel("debug"), LogLevel.DEBUG)
        @Assert(parseLogLevel("WARN"), LogLevel.WARN)
        @Assert(parseLogLevel("unknown"), LogLevel.INFO)
    }

    /**
     * 测试远端 IP 头配置 - 验证空值不产生空头名且值会被 trim
     */
    @TestCase
    public func testRemoteIpHeaders(): Unit {
        let empty = JoyProperties()
        @Assert(createJoyConfig(empty).remoteIPHeaders.isEmpty(), true)

        let props = JoyProperties()
        props.server.http.remoteIpHeaders = "X-Forwarded-For, X-Real-IP"
        let headers = createJoyConfig(props).remoteIPHeaders
        @Assert(headers.size, 2)
        @Assert(headers[0], "X-Forwarded-For")
        @Assert(headers[1], "X-Real-IP")
    }

    /**
     * 测试 camelCase 字段绑定 - 验证配置键转成连字符后仍能绑定到对象字段
     */
    @TestCase
    public func testCamelCaseBind(): Unit {
        let manager = ConfigManager.INSTANCE
        manager.addLoader(ArgConfigLoader([
            "-Djoy.server.http.caseInsensitive=true",
            "-Djoy.server.http.maxRequestBodySize=64"
        ]))
        let props = manager.bind<JoyProperties>("joy").getOrThrow()
        @Assert(props.server.http.caseInsensitive, true)
        @Assert(props.server.http.maxRequestBodySize, 64)
    }

    /**
     * 测试 TLS 密码套件配置 - 验证空配置不会产生空密码套件
     */
    @TestCase
    public func testTlsCipherSuites(): Unit {
        let tls = JoyServerTlsProperties()
        tls.certFile = "./testdata/server_cert.pem"
        tls.keyFile = "./testdata/server_key.pem"
        tls.version = "1.2"

        let emptyCfg = loadTlsConfig(tls)
        @Assert(emptyCfg.supportedCipherSuites.get(TlsVersion.V1_2).isNone(), true)

        tls.ciphers = "A, B"
        let cfg = loadTlsConfig(tls)
        @Assert(cfg.supportedCipherSuites.get(TlsVersion.V1_2).getOrThrow(), ["A", "B"])
    }
}
