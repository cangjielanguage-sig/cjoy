/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.httpx

import std.collection.{Map}
import stdx.net.http.{HttpHeaders}
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}

public class TokenAuthClient <: JoyHttpClient {
    public TokenAuthClient(let http: JoyHttpClient, let token!: String, let position!: String = "header:Authorization",
        let authSchema!: String = "Bearer") {
    }

    public func exachange(ctx: Context, method: String, path: String, params: Map<String, ToString>,
        headers: HttpHeaders, body: Any): JoyHttpResponse {
        createFunc(token, position, authSchema)(path, headers)
        http.exachange(ctx, method, path, params, headers, body)
    }

    private func createFunc(token: String, position: String, authSchema: String): (path: String, headers: HttpHeaders) -> Unit {
        let sn = position.split(":")
        if (sn.size != 2) {
            throw IllegalArgumentException("position format must be <source>:<name>")
        }
        {
            path: String, headers: HttpHeaders => match (sn[0]) {
                // first support header
                case "header" =>
                    if (authSchema.isEmpty()) {
                        headers.add(sn[1], token)
                    } else {
                        headers.add(sn[1], "${authSchema} ${token}")
                    }
                case _ => ()
            }
        }
    }
}
