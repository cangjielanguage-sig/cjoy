/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.websocket

import cjoy.*

class TextEchoJoyWebSocketHandler <: JoyWebSocketHandler {
    public func onOpen(session: JoyWebSocketSession): Unit {
        let name = session.getParam("name").getOrThrow()
        print("websocket open, url path param, name=${name}")
    }

    public func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit {
        session.send(message)
    }

    public func onClose(_: JoyWebSocketSession, closeStatus: UInt16): Unit {
        print("websocket close, closeStatus=${closeStatus}")
    }

    public func onError(_: JoyWebSocketSession, ex: Exception): Unit {
        ex.printStackTrace()
    }
}

main(): Int64 {
    // 创建joy实例
    let joy = Joy.default()
    // 注册路由
    joy.router.websocket("/ws/chat/{name}", TextEchoJoyWebSocketHandler())
    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}
