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

import stdx.net.http.{HttpStatusCode}
import cjoy.context.Context

/**
 * 服务器错误时自动重试的 HTTP 客户端
 */
public class RetryClient <: JoyHttpClient {
    public RetryClient(let http: JoyHttpClient, let maxRetries!: Int = 3) {
    }

    /**
     * 发送 HTTP 请求，服务器错误时自动重试
     *
     * @param ctx 请求上下文
     * @param request HTTP 请求
     * @return HTTP 响应
     */
    public func send(ctx: Context, request: JoyHttpRequest): JoyHttpResponse {
        var lastEx: ?Exception = None
        for (_ in 0..maxRetries) {
            try {
                let resp = http.send(ctx, request)
                if (resp.status != HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR) {
                    return resp
                }
            } catch (ex: Exception) {
                lastEx = ex
                continue
            }
        }

        if (let Some(e) <- lastEx) {
            throw e
        } else {
            throw Exception("invoke http service return InternalServerError reach max retries ${maxRetries}")
        }
    }
}
