/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

import std.sync.Mutex
import std.time.DateTime
import stdx.net.http.Cookie
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext}
import cjoy.session.*

private const SESSION_CTX_KEY: String = "__session__"

/**
 * 会话配置
 */
public struct JoySessionConfig {
    /**
     * 创建会话配置
     *
     * @param cookieName 用于保存会话 ID 的 Cookie 名称，默认为 "sid"
     * @param cookiePath Cookie 路径，默认为 "/"
     * @param cookieSecure 是否仅使用 HTTPS，默认为 false
     * @param cookieHttpOnly 是否仅 HTTP 访问，默认为 false
     * @param cookieMaxAge Cookie 生命周期（秒），默认为 3600
     * @param cookieDomain Cookie 域名，默认为空
     * @param idLength 会话 ID 长度，默认为 32
     */
    public JoySessionConfig(
        // 用于保存会话 ID 的 Cookie 名称。默认为 "sid"。
        public let cookieName!: String = "sid",
        // 存储的 Cookie 路径。默认为 "/"。
        public let cookiePath!: String = "/",
        // 仅使用 HTTPS。默认为 false。
        public let cookieSecure!: Bool = false,
        // 仅 http。默认为 false。
        public let cookieHttpOnly!: Bool = true,
        // Cookie 生命周期。默认为 3600。
        public let cookieMaxAge!: Int = 3600,
        // Cookie 域名。默认为空。
        public let cookieDomain!: String = "",
        // 会话 ID 长度。默认为 32。
        public let idLength!: Int = 32
    ) {}
}

/**
 * 从上下文中获取会话
 */
public func getSession(ctx: JoyContext): ?JoySession {
    ctx.getCtxParam(SESSION_CTX_KEY)
}

/**
 * 创建会话中间件
 *
 * @param storage 会话存储实现
 * @param config 会话配置
 */
public class SessionManager <: JoyMiddlewareHandler {
    private let _config: JoySessionConfig
    private let _storage: JoySessionStorage
    private let _lock: Mutex = Mutex()
    private let _future: Future<Unit>

    /**
     * 创建会话管理器
     *
     * @param storage 会话存储实现
     * @param config 会话配置选项
     */
    public init(storage: JoySessionStorage, config!: JoySessionConfig = JoySessionConfig()) {
        _storage = storage
        _config = config
        // to clean expire session 
        _future = spawn {
            while (!Thread.currentThread.hasPendingCancellation) {
                sleep(5 * Duration.second)
                storage.clean()
            }
        }
    }

    /**
     * 销毁会话管理器，停止后台清理任务
     */
    public func destroy(): Unit {
        _future.cancel()
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let sid = ctx.getCookie(_config.cookieName)
        var newCookie = false
        let session = if (let Some(id) <- sid) {
            let sess = _storage.getOrCreate(id, Int32(_config.idLength / 2))
            ctx.setCtxParam(SESSION_CTX_KEY, sess)
            if (sess.id != id) {
                newCookie = true
            }
            sess
        } else {
            synchronized(_lock) {
                let existed = ctx.getCtxParam<JoySession>(SESSION_CTX_KEY)
                if (let Some(s) <- existed) {
                    if (!_storage.exists(s.id)) {
                        s.invalidate()
                        // overrides session which created by last SessionManager
                        newCookie = true
                        createNewSession(ctx)
                    } else {
                        s
                    }
                } else {
                    newCookie = true
                    createNewSession(ctx)
                }
            }
        }

        try {
            chain.next(ctx)
        } finally {
            // set-cookie
            var maxAge = _config.cookieMaxAge
            if (session.isInvalidated) {
                newCookie = true
                maxAge = -1 // delete the cookie 
            } else {
                session.flush()
            }

            if (newCookie) {
                let c = if (maxAge == -1) {
                    Cookie(_config.cookieName, "", expires: DateTime.UnixEpoch, domain: _config.cookieDomain,
                        path: _config.cookiePath, secure: _config.cookieSecure, httpOnly: _config.cookieHttpOnly)
                } else {
                    Cookie(_config.cookieName, session.id, maxAge: maxAge, domain: _config.cookieDomain,
                        path: _config.cookiePath, secure: _config.cookieSecure, httpOnly: _config.cookieHttpOnly)
                }

                ctx.cookie(c)
            }
        }
    }

    private func createNewSession(ctx: JoyContext): JoySession {
        let sess = _storage.getOrCreate("", Int32(_config.idLength / 2))
        ctx.setCtxParam(SESSION_CTX_KEY, sess)
        sess
    }
}
