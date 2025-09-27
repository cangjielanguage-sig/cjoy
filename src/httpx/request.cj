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

import std.io.{ByteBuffer}
import stdx.encoding.json.stream.{JsonSerializable, JsonWriter}
import stdx.net.http.{HttpRequestBuilder}
import cjoy.framework.{JoyHttpConsts}

/*
 * the http json request
 */
public class JsonRequest<T> where T <: JsonSerializable {
    public JsonRequest(let reqBody: T) {
    }

    public func write(buidler: HttpRequestBuilder): Unit {
        match (reqBody) {
            case x: String => buidler
                .header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8)
                .body(x)
            case _ =>
                let buffer = ByteBuffer()
                let writer = JsonWriter(buffer)
                writer.writeValue(reqBody)
                writer.flush()
                buidler.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8).body(buffer)
        }
    }
}

