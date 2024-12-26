/*
* Copyright (c) lanlingx 2024-2024. All rights resvered.
*/

package cjoy

import net.http.{HttpResponseBuilder, HttpStatusCode}

public interface JoyRender {
    func render(builder: HttpResponseBuilder): Unit
}

public class JoyFuncRender <: JoyRender {
    public JoyFuncRender(let builder: (HttpResponseBuilder) -> Unit) {}

    public func render(builder: HttpResponseBuilder): Unit {
        this.builder(builder)
    }
}
