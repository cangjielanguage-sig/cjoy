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

import stdx.encoding.base64.toBase64String
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}

public class BasicAuthClient <: JoyHttpClient {
    public BasicAuthClient(let http: JoyHttpClient, let username!: String, let password!: String) {
    }

    public func send(ctx: Context, request: JoyHttpRequest): JoyHttpResponse {
        let authValue = "Basic " + toBase64String((username + ":" + password).toArray())
        request.header(JoyHttpConsts.HEADER_AUTHORIZATION, authValue)
        http.send(ctx, request)
    }
}
