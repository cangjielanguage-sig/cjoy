# Streamable Transport 规范

## ADDED Requirements

### Requirement: 事件中继功能

Streamable Transport SHALL 支持事件中继功能，允许客户端通过 `Last-Event-ID` 头获取最后一个事件之后的所有未发送事件。

#### Scenario: 成功的事件中继

- **WHEN** 客户端发送包含 `Last-Event-ID` 头的请求
- **THEN** 服务器应返回该事件之后的所有未发送事件
- **AND** 每个事件应包含 `id` 字段，用于标识事件
- **AND** 事件应按发送顺序返回

#### Scenario: 无效的 Last-Event-ID

- **WHEN** 客户端发送包含无效 `Last-Event-ID` 头的请求
- **THEN** 服务器应返回 404 Not Found 错误
- **AND** 响应应包含错误信息

#### Scenario: 没有未发送事件

- **WHEN** 客户端发送包含 `Last-Event-ID` 头的请求，但该事件之后没有未发送事件
- **THEN** 服务器应保持连接打开，等待新事件
- **OR** 服务器可以返回一个空响应，具体取决于实现

### Requirement: 事件存储和检索

Streamable Transport SHALL 提供事件存储和检索功能，以便在需要时能够中继事件。

#### Scenario: 存储事件

- **WHEN** 服务器生成一个新事件
- **THEN** 事件应被存储在服务器端
- **AND** 事件应包含唯一的 ID
- **AND** 事件应包含时间戳，用于过期管理

#### Scenario: 检索事件

- **WHEN** 服务器收到包含 `Last-Event-ID` 头的请求
- **THEN** 服务器应能够检索该 ID 之后的所有未发送事件
- **AND** 事件应按发送顺序返回

#### Scenario: 事件过期

- **WHEN** 事件的存储时间超过了配置的过期时间
- **THEN** 事件应被自动清理
- **AND** 服务器不应再返回已过期的事件

### Requirement: 错误处理

Streamable Transport SHALL 提供良好的错误处理机制，以便在发生错误时能够提供适当的反馈。

#### Scenario: 无效的请求

- **WHEN** 客户端发送无效的请求
- **THEN** 服务器应返回适当的错误响应
- **AND** 响应应包含错误信息
- **AND** 响应应包含适当的 HTTP 状态码

#### Scenario: 服务器内部错误

- **WHEN** 服务器在处理请求时发生内部错误
- **THEN** 服务器应返回 500 Internal Server Error 响应
- **AND** 响应应包含错误信息
- **AND** 服务器应记录详细的错误日志

### Requirement: 性能优化

Streamable Transport SHALL 对事件存储和检索进行性能优化，以确保在高负载情况下的可靠性。

#### Scenario: 事件存储性能

- **WHEN** 服务器在短时间内生成大量事件
- **THEN** 事件应能够被快速存储
- **AND** 服务器的响应时间不应受到显著影响

#### Scenario: 事件检索性能

- **WHEN** 客户端请求大量未发送事件
- **THEN** 服务器应能够快速检索和发送这些事件
- **AND** 响应时间不应超过可接受的范围

## MODIFIED Requirements

### Requirement: McpStreamableServerTransport 类

Streamable Transport SHALL 实现完整的事件中继功能，包括 `relayEvents` 方法的实现。

#### Scenario: 完整的 Streamable Transport 实现

- **WHEN** `McpStreamableServerTransport` 类被实例化
- **THEN** 所有方法应正常工作
- **AND** `relayEvents` 方法应能够正确地中继事件
- **AND** 事件存储和检索功能应正常工作

#### Scenario: 与 SSE Transport 功能一致性

- **WHEN** Streamable Transport 和 SSE Transport 被同时使用
- **THEN** 两者应提供类似的功能
- **AND** 事件处理方式应一致
- **AND** 错误处理方式应一致
