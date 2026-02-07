# WebSocket

CJoy 提供完整的WebSocket支持，简化WebSocket连接管理、消息处理和会话维护。

## 概述

CJoy WebSocket系统基于以下核心概念设计：

- **协议支持**：完整的RFC 6455 WebSocket协议实现
- **连接管理**：自动处理握手、连接建立和清理
- **消息类型**：支持文本(Text)和二进制(Binary)消息
- **帧控制**：支持消息分帧和合并策略
- **安全控制**：支持Origin白名单和SubProtocol协商
- **会话管理**：提供连接会话信息和参数访问
- **异常处理**：完整的连接异常和消息异常处理

### 核心接口定义
- `JoyWebSocketHandler`：WebSocket处理器接口，参见 [websocket/handler.cj](../../src/websocket)
- `JoyWebSocketSession`：WebSocket会话包装，参见 [websocket/session.cj](../../src/websocket)
- `JoyWebSocketMessage`：消息包装类，参见 [websocket/message.cj](../../src/websocket)

### 协议特性支持

| 特性 | 支持状态 | 说明 |
|------|----------|------|
| RFC 6455 | ✅ | 完整WebSocket协议支持 |
| 握手协商 | ✅ | SubProtocol和Origin协商 |
| 消息分帧 | ✅ | 自动处理消息分帧 |
| 心跳检测 | ✅ | Ping/Pong心跳支持 |
| 连接关闭 | ✅ | 优雅关闭连接 |
| 异常恢复 | ✅ | 连接异常处理和恢复 |

---

## 一、基础使用

### 1.1 WebSocket路由注册

```cangjie
import cjoy.*
import cjoy.websocket.*

// 注册WebSocket路由
router.websocket("/ws/chat/{roomId}", ChatWebSocketHandler())

// 支持路由参数
router.websocket("/ws/echo/{userId}", EchoWebSocketHandler())

// 支持中间件
router.websocket("/ws/secure", SecureWebSocketHandler())
    .use(authMiddleware)
    .use(rateLimitMiddleware)
```

### 1.2 简单Echo服务器

```cangjie
class EchoWebSocketHandler <: JoyWebSocketHandler {
    public func supportedSubProtocols(): Array<String> {
        ["echo", "chat"]  // 支持的子协议
    }
    
    public func supportedOrigins(): Array<String> {
        ["http://localhost:18881", "https://example.com"]  // 允许的Origin
    }
    
    public func mergeFrames(): Bool {
        true  // 合并分帧消息为一个完整消息
    }
    
    public func onOpen(session: JoyWebSocketSession): Unit {
        let clientInfo = getClientInfo(session)
        println("新的WebSocket连接: ${clientInfo}")
        
        // 发送欢迎消息
        session.send("欢迎连接到Echo服务器！")
    }
    
    public func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit {
        match (message) {
            case JoyWebSocketMessage.Text(text) => {
                println("收到文本消息: ${text}")
                // 原样返回
                session.send(text)
            }
            case JoyWebSocketMessage.Binary(data) => {
                println("收到二进制消息，大小: ${data.size}")
                // 原样返回二进制数据
                session.send(data)
            }
        }
    }
    
    public func onClose(session: JoyWebSocketSession, code: UInt16, reason: String): Unit {
        println("WebSocket连接关闭: code=${code}, reason=${reason}")
    }
    
    public func onError(session: JoyWebSocketSession, error: Exception): Unit {
        println("WebSocket错误: ${error.message}")
    }
    
    private func getClientInfo(session: JoyWebSocketSession): String {
        let userId = session.getPathParam("userId") ?? "anonymous"
        let userAgent = session.getHeader("User-Agent") ?? "unknown"
        return "用户=${userId}, UserAgent=${userAgent}"
    }
}
```

### 1.3 会话信息获取

```cangjie
class SessionInfoWebSocketHandler <: JoyWebSocketHandler {
    public func onOpen(session: JoyWebSocketSession): Unit {
        // 获取路径参数
        let roomId = session.getPathParam("roomId")
        let userId = session.getQueryParam("userId")
        
        // 获取查询参数
        let token = session.getQueryParam("token")
        
        // 获取HTTP头
        let userAgent = session.getHeader("User-Agent")
        let origin = session.getHeader("Origin")
        
        // 获取客户端IP
        let clientIP = session.remoteAddr
        
        // 获取子协议
        let protocol = session.subProtocol
        
        println("连接信息:")
        println("  房间ID: ${roomId}")
        println("  用户ID: ${userId}")
        println("  Token: ${token}")
        println("  User-Agent: ${userAgent}")
        println("  Origin: ${origin}")
        println("  客户端IP: ${clientIP}")
        println("  子协议: ${protocol}")
    }
    
    public func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit {
        // 使用连接信息处理消息
        let roomId = session.getPathParam("roomId")
        if (message is JoyWebSocketMessage.Text) {
            broadcastToRoom(roomId, message.text)
        }
    }
}
```

### 1.4 消息发送

```cangjie
class MessageHandler <: JoyWebSocketHandler {
    private var session: ?JoyWebSocketSession = None
    
    public func onOpen(session: JoyWebSocketSession): Unit {
        self.session = Some(session)
        
        // 发送不同类型的消息
        sendWelcomeMessage(session)
        sendUserList(session)
        sendServerTime(session)
    }
    
    private func sendWelcomeMessage(session: JoyWebSocketSession): Unit {
        let welcome = @ToJson({
            "type": "welcome",
            "message": "欢迎来到聊天室",
            "timestamp": DateTime.now().toUnixTimeStamp().toSeconds()
        })
        session.send(welcome)
    }
    
    private func sendUserList(session: JoyWebSocketSession): Unit {
        let users = ["user1", "user2", "user3"]
        let userList = @ToJson({
            "type": "user_list",
            "users": users
        })
        session.send(userList)
    }
    
    private func sendServerTime(session: JoyWebSocketSession): Unit {
        let timeInfo = @ToJson({
            "type": "server_time",
            "time": DateTime.now().toString(),
            "timestamp": DateTime.now().toUnixTimeStamp().toSeconds()
        })
        session.send(timeInfo)
    }
    
    public func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit {
        // 处理收到的消息...
    }
}
```

## 二、高级功能

### 2.1 心跳机制

```cangjie
class HeartbeatWebSocketHandler <: JoyWebSocketHandler {
    private var heartbeatInterval: ?Timer = None
    
    public func onOpen(session: JoyWebSocketSession): Unit {
        println("WebSocket连接建立，启动心跳")
        
        // 启动心跳定时器
        heartbeatInterval = Some(Timer.schedule(Duration.second * 30, {
            sendHeartbeat(session)
        }))
    }
    
    private func sendHeartbeat(session: JoyWebSocketSession): Unit {
        // 发送Ping帧
        session.ping("heartbeat_${DateTime.now().toUnixTimeStamp().toSeconds()}")
    }
    
    public func onPong(session: JoyWebSocketSession, data: Array<Byte>): Unit {
        let pongData = String.fromUtf8(data)
        println("收到Pong响应: ${pongData}")
    }
    
    public func onClose(session: JoyWebSocketSession, code: UInt16, reason: String): Unit {
        println("WebSocket连接关闭，停止心跳")
        if (let Some(timer) <- heartbeatInterval) {
            timer.stop()
        }
        heartbeatInterval = None
    }
}
```

### 2.2 消息广播

```cangjie
class BroadcastWebSocketHandler <: JoyWebSocketHandler {
    // 使用全局连接列表
    private static let connections = ConcurrentHashMap<String, JoyWebSocketSession>()
    
    public func onOpen(session: JoyWebSocketSession): Unit {
        let connectionId = generateConnectionId()
        connections.add(connectionId, session)
        
        // 通知其他客户端有新连接
        let joinMessage = @ToJson({
            "type": "join",
            "connectionId": connectionId,
            "timestamp": DateTime.now().toUnixTimeStamp().toSeconds()
        })
        broadcastToOthers(joinMessage, connectionId)
    }
    
    public func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit {
        let msgData = message.asText()
        if (let Some(jsonMsg) <- parseJsonMessage(msgData)) {
            let chatMessage = @ToJson({
                "type": "chat",
                "connectionId": getConnectionId(session),
                "message": jsonMsg.get("message") ?? "",
                "timestamp": DateTime.now().toUnixTimeStamp().toSeconds()
            })
            broadcast(chatMessage)
        }
    }
    
    private func broadcast(message: JsonSerializable): Unit {
        connections.forEach {_, sess =>
            sess.send(message)
        }
    }
    
    private func broadcastToOthers(message: JsonSerializable, excludeId: String): Unit {
        connections.forEach {id, sess =>
            if (id != excludeId) {
                sess.send(message)
            }
        }
    }
}
```

### 2.3 二进制数据处理

```cangjie
class BinaryWebSocketHandler <: JoyWebSocketHandler {
    public func mergeFrames(): Bool {
        false  // 不合并帧，手动处理分帧
    }
    
    public func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit {
        match (message.msgType) {
            case WsText => {
                handleTextMessage(message.asText())
            }
            case WsBinary => {
                handleBinaryMessage(message.asBinary())
            }
        }
    }
    
    private func handleTextMessage(text: String): Unit {
        println("文本消息: ${text}")
    }
    
    private func handleBinaryMessage(data: Array<Byte>): Unit {
        // 检查二进制消息类型
        if (data.size >= 4) {
            let messageType = String.fromUtf8(data[..4])
            
            match (messageType) {
                case "IMG " => handleImageMessage(data[4..])
                case "AUD " => handleAudioMessage(data[4..])
                case "FILE" => handleFileMessage(data[4..])
                case _ => println("未知二进制消息类型: ${messageType}")
            }
        }
    }
    
    private func handleImageMessage(imageData: Array<Byte>): Unit {
        println("收到图片，大小: ${imageData.size} bytes")
        // 处理图片数据...
    }
    
    private func handleAudioMessage(audioData: Array<Byte>): Unit {
        println("收到音频，大小: ${audioData.size} bytes")
        // 处理音频数据...
    }
    
    private func handleFileMessage(fileData: Array<Byte>): Unit {
        println("收到文件，大小: ${fileData.size} bytes")
        // 处理文件数据...
    }
}
```

## 三、安全与性能

### 3.1 安全控制

```cangjie
class SecureWebSocketHandler <: JoyWebSocketHandler {
    public func supportedOrigins(): Array<String> {
        // 限制允许的域名
        [
            "https://yourdomain.com",
            "https://app.yourdomain.com",
            "http://localhost:3000"  // 开发环境
        ]
    }
    
    public func supportedSubProtocols(): Array<String> {
        // 支持的子协议
        ["secure-chat", "auth-token"]
    }
    
    public func onOpen(session: JoyWebSocketSession): Unit {
        // 验证Origin
        let origin = session.getHeader("Origin")
        let allowedOrigins = supportedOrigins()
        
        if (!allowedOrigins.contains(origin ?? "")) {
            println("不允许的Origin: ${origin}")
            session.close(1003, "Origin not allowed")
            return
        }
        
        // 验证子协议
        let protocol = session.subProtocol
        let supportedProtocols = supportedSubProtocols()
        
        if (!supportedProtocols.contains(protocol)) {
            println("不支持的子协议: ${protocol}")
            session.close(1003, "Protocol not supported")
            return
        }
        
        // 验证Token（如果有）
        let token = session.getQueryParam("token")
        if (!isValidToken(token)) {
            println("无效的Token: ${token}")
            session.close(4001, "Invalid token")
            return
        }
        
        println("安全验证通过")
        // 继续正常处理...
    }
    
    private func isValidToken(token: ?String): Bool {
        match (token) {
            case Some(t) => t.startsWith("valid_") && t.size > 10
            case _ => false
        }
    }
}
```

### 3.2 性能优化

```cangjie
class OptimizedWebSocketHandler <: JoyWebSocketHandler {
    private let messageBuffer = StringBuilder()
    private let maxBufferSize = 1024
    private var lastFlushTime = DateTime.now()
    
    public func mergeFrames(): Bool {
        true  // 合并小消息，减少网络调用
    }
    
    public func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit {
        match (message.msgType) {
            case WsText => {
                let text = message.asText()
                
                // 消息缓冲优化
                messageBuffer.append(text)
                messageBuffer.append("\n")
                
                // 批量发送或定时刷新
                let shouldFlush = messageBuffer.size >= maxBufferSize || 
                               (lastFlushTime.elapsedMilliseconds() > 100)
                
                if (shouldFlush) {
                    session.send(messageBuffer.toString())
                    messageBuffer.clear()
                    lastFlushTime = DateTime.now()
                }
            }
            case _ => {}
        }
    }
    
    public func onClose(session: JoyWebSocketSession, code: UInt16, reason: String): Unit {
        // 发送剩余缓冲区内容
        if (messageBuffer.size > 0) {
            session.send(messageBuffer.toString())
            messageBuffer.clear()
        }
        
        println("连接关闭: code=${code}, reason=${reason}")
    }
}
```

## 四、注意事项

### 4.1 线程安全

| 约束 | 说明 | 解决方案 |
|------|------|----------|
| **同线程处理** | WebSocket消息处理必须在同一线程中 | 不要在onMessage中创建新线程 |
| **并发访问** | 多个连接同时访问共享数据需要同步 | 使用ConcurrentHashMap或Mutex |
| **消息顺序** | 分帧消息需要按顺序处理 | 设置mergeFrames=true或手动排序 |

### 4.2 资源管理

| 注意事项 | 说明 | 最佳实践 |
|----------|------|----------|
| **连接清理** | 确保连接关闭时清理资源 | 在onClose中释放所有资源 |
| **定时器管理** | 心跳定时器需要正确停止 | 使用try-with-resource或显式停止 |
| **内存泄漏** | 避免在回调中持有大对象引用 | 及时释放不再使用的对象 |
| **异常处理** | 网络异常需要妥善处理 | 捕获并记录异常，避免连接崩溃 |

### 4.3 协议兼容

| 特性 | 支持状态 | 说明 |
|------|----------|------|
| RFC 6455 | ✅ | 完整协议支持 |
| 子协议协商 | ✅ | 客户端可选择支持的协议 |
| Origin验证 | ✅ | 跨域安全支持 |
| 心跳支持 | ✅ | Ping/Pong机制 |
| 分帧支持 | ✅ | 自动处理分帧消息 |

### 4.4 常见问题解决

**Q: WebSocket连接建立失败？**
A: 检查Origin白名单、协议版本、防火墙设置

**Q: 消息发送失败？**
A: 确认连接状态、消息格式正确、缓冲区大小合适

**Q: 大文件传输性能差？**
A: 使用分块传输、减少内存占用、优化网络调用

**Q: 并发连接过多？**
A: 实现连接数限制、负载均衡、资源监控

---
 << [返回](../../README.md#使用指导)
