package cjoy

import net.http.{HttpResponseBuilder, HttpStatusCode}

public interface JoyRender {
    func render(builder: HttpResponseBuilder): Unit
}

public class JoyFuncRnder <: JoyRender {
    public JoyFuncRnder(let builder: (HttpResponseBuilder) -> Unit) {}

    public func render(builder: HttpResponseBuilder): Unit {
        this.builder(builder)
    }
}
