/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import stdx.net.http.{HttpResponseBuilder, HttpStatusCode}

/**
* the interface of render
*/
public interface JoyRender {
    func render(builder: HttpResponseBuilder): Unit
}

public class JoyFuncRender <: JoyRender {
    public JoyFuncRender(let builder: (HttpResponseBuilder) -> Unit) {}

    public func render(builder: HttpResponseBuilder): Unit {
        this.builder(builder)
    }
}
