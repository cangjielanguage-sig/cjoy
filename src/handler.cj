package cjoy

public interface JoyRequestHandler {
    func handle(ctx: JoyContext): Unit
}

public class JoyFuncHandler <: JoyRequestHandler {
    public JoyFuncHandler(let handler: (JoyContext) -> Unit) {}

    public func handle(ctx: JoyContext): Unit {
        this.handler(ctx)
    }
}