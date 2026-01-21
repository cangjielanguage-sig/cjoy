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
 * the sssion config
 */
public struct JoySessionConfig {
    public JoySessionConfig(
        // Cookie name to save session ID. Default is "sid".
        public let cookieName!: String = "sid",
        // Cookie path to store. Default is "/".
        public let cookiePath!: String = "/",
        // Use HTTPS only. Default is false.
        public let cookieSecure!: Bool = false,
        // http only. Default is false.
        public let cookieHttpOnly!: Bool = true,
        // Cookie life time. Default is 3600.
        public let cookieMaxAge!: Int = 3600,
        // Cookie domain name. Default is empty.
        public let cookieDomain!: String = "",
        // Session ID length. Default is 32.
        public let idLength!: Int = 32
    ) {}
}

/**
 * Get session from context
 */
public func getSession(ctx: JoyContext): ?JoySession {
    ctx.getCtxParam(SESSION_CTX_KEY)
}

/**
 * create Session middleware
 */
public class SessionManager <: JoyMiddlewareHandler {
    private let _config: JoySessionConfig
    private let _storage: JoySessionStorage
    private let _lock: Mutex = Mutex()
    private let _future: Future<Unit>

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
                        createNewSessoin(ctx)
                    } else {
                        s
                    }
                } else {
                    newCookie = true
                    createNewSessoin(ctx)
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

    private func createNewSessoin(ctx: JoyContext): JoySession {
        let sess = _storage.getOrCreate("", Int32(_config.idLength / 2))
        ctx.setCtxParam(SESSION_CTX_KEY, sess)
        sess
    }
}
