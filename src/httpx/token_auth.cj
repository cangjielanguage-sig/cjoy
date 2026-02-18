/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.httpx

import cjoy.context.Context

/**
 * 基于令牌的认证 HTTP 客户端
 */
public class TokenAuthClient <: JoyHttpClient {
    public TokenAuthClient(let http: JoyHttpClient, let token!: String, let position!: String = "header:Authorization",
        let authSchema!: String = "Bearer") {
    }

    /**
     * 发送带基于令牌认证的 HTTP 请求
     *
     * @param ctx 请求上下文
     * @param request HTTP 请求
     * @return HTTP 响应
     */
    public func send(ctx: Context, request: JoyHttpRequest): JoyHttpResponse {
        createFunc(token, position, authSchema)(request)
        http.send(ctx, request)
    }

    /**
     * @throws IllegalArgumentException 如果位置格式无效
     */
    private func createFunc(token: String, position: String, authSchema: String): (request: JoyHttpRequest) -> Unit {
        let sn = position.split(":")
        if (sn.size != 2) {
            throw IllegalArgumentException("position format must be <source>:<name>")
        }
        {
            request: JoyHttpRequest => match (sn[0]) {
                // first support header
                case "header" =>
                    if (authSchema.isEmpty()) {
                        request.header(sn[1], token)
                    } else {
                        request.header(sn[1], "${authSchema} ${token}")
                    }
                case _ => ()
            }
        }
    }
}
