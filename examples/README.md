# 样例

## 基础能力
- [simple](src/simple/main.cj)：基本的API使用
- [logger](src/logger/main.cj)：日志输出
- [rest](src/rest/main.cj): Restful风格
- [macros](src/macros/main.cj): 使用宏实现Handler注册与参数展开
- [multi packages](src/multipkgs/main.cj): 使用宏实现Handler在不同的package下
- [combination](src/combination/main.cj): 组合使用Json，Bind，Validation，Handler宏

## 协议
- [chuncked](src/chuncked/main.cj): chuncked响应
- [sse](src/sse/main.cj): Server-Sent Event
- [tls](src/tls/main.cj): HTTPS
- [fileserver](src/fileserver/main.cj): 文件服务器
- [websocket](src/websocket/main.cj): WebSocket
- [multipart](src/multipart/main.cj): MultiPart，文件上传
- [mcpserver](src/mcpserver/main.cj): MCP Server
- [mcpclient](src/mcpclient/main.cj): MCP Client

## 中间件
- [session](src/session/main.cj): Session
- [reqeust id](src/requestid/main.cj): 获取或生成请求ID
- [no cache](src/nocache/main.cj): 禁用缓存
- [token auth](src/tokenauth/main.cj): 基于Token认证
- [CRSF](src/crsf/main.cj): 防跨站请求伪造攻击
- [JWT auth](src/jwtauth/main.cj): 基于JWT认证