/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import std.io.*
import std.unittest.*
import std.unittest.testmacro.*
import stdx.net.http.*
import stdx.encoding.url.*
import cjoy.*
import cjoy.json.*

class TextEchoJoyWebSocketHandler <: JoyWebSocketHandler {
    var name = ""
    var isOpen = false
    var msgNum = 0
    var closeStatus: UInt16 = 0
    var isErr = false
    var merge = true

    public func mergeFrames(): Bool {
        merge
    }

    public func reset() {
        name = ""
        isOpen = false
        msgNum = 0
        closeStatus = 0
        isErr = false
        merge = true
    }

    public func onOpen(session: JoyWebSocketSession): Unit {
        name = session.getParam("name").getOrThrow()
        isOpen = true
    }

    public func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit {
        msgNum += 1
        session.send(message)
    }

    public func onClose(_: JoyWebSocketSession, closeStatus: UInt16): Unit {
        isOpen = false
        this.closeStatus = closeStatus
    }

    public func onError(_: JoyWebSocketSession, ex: Exception): Unit {
        isErr = true
        ex.printStackTrace()
    }
}

@Test
public class WebSocketTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()
    let _textWsHandler = TextEchoJoyWebSocketHandler()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.websocket("/ws/text/{name}", _textWsHandler)
            _instance = joy
            joy.run("127.0.0.1", 18881)
        }

        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _client.close()
        _instance?.shutdown()
    }

    @TestCase
    func testTextOneFrame() {
        _textWsHandler.reset()

        let url = URL.parse("ws://127.0.0.1:18881/ws/text/xiao")
        let (websocket, _) = WebSocket.upgradeFromClient(_client, url)
        sleep(Duration.millisecond * 200)
        @Assert(_textWsHandler.name, "xiao")

        for (_ in 0..10) {
            websocket.write(TextWebFrame, "hello".toArray())
        }
        sleep(Duration.second)
        @Assert(_textWsHandler.msgNum, 10)

        websocket.writeCloseFrame(status: JoyWebSocketCloseStatus.NORMAL)
        sleep(Duration.second)
        @Assert(_textWsHandler.closeStatus, JoyWebSocketCloseStatus.NORMAL)

        websocket.closeConn()
    }

    @TestCase
    func testTextMultiFramesMerge() {
        _textWsHandler.reset()

        let url = URL.parse("ws://127.0.0.1:18881/ws/text/xiao")
        let (websocket, _) = WebSocket.upgradeFromClient(_client, url)
        sleep(Duration.millisecond * 200)

        let msg = ("hello" * 100).toArray()
        let frameSize = 20
        for (_ in 0..10) {
            websocket.write(TextWebFrame, msg, frameSize: frameSize)
        }
        sleep(Duration.second)
        @Assert(_textWsHandler.msgNum, 10)

        websocket.writeCloseFrame(status: JoyWebSocketCloseStatus.NORMAL)
        websocket.closeConn()
    }

    @TestCase
    func testTextMultiFramesNotMerge() {
        _textWsHandler.reset()
        _textWsHandler.merge = false

        let url = URL.parse("ws://127.0.0.1:18881/ws/text/xiao")
        let (websocket, _) = WebSocket.upgradeFromClient(_client, url)
        sleep(Duration.millisecond * 200)

        let msg = ("hello" * 100).toArray()
        let frameSize = 20
        for (_ in 0..10) {
            websocket.write(TextWebFrame, msg, frameSize: frameSize)
        }
        sleep(Duration.second)
        @Assert(_textWsHandler.msgNum >= (msg.size / frameSize), true)

        websocket.writeCloseFrame(status: JoyWebSocketCloseStatus.NORMAL)
        websocket.closeConn()
    }
}
