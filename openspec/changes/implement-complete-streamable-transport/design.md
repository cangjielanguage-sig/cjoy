# 实现完整的 Streamable Transport 服务端能力

## Context

CJoy 是一个基于仓颉语言的 Web 框架，提供了 MCP (Model Context Protocol) 服务端支持。当前 MCP 模块中的 Streamable Transport 实现存在功能不完整的问题，特别是 `relayEvents` 方法尚未实现，这会影响到 Streamable Transport 的事件中继功能。

### 当前状态

- 存在 `McpStreamableServerTransport` 类，但 `relayEvents` 方法是一个空实现
- SSE Transport 已经实现了完整的事件处理和中继功能
- Streamable Transport 应该提供与 SSE Transport 类似的功能，但使用不同的传输机制

### 架构约束

- 必须遵循 MCP 协议规范
- 必须与 CJoy 的现有架构集成
- 必须保持与 SSE Transport 功能一致性

## Goals / Non-Goals

**Goals:**
- 实现完整的 `relayEvents` 方法，支持事件中继功能
- 确保 Streamable Transport 与 SSE Transport 功能一致性
- 添加相关测试用例，验证 Streamable Transport 的完整功能
- 优化 Streamable Transport 的性能和可靠性

**Non-Goals:**
- 不修改 MCP 协议规范
- 不重构整个 MCP 模块架构
- 不添加新的传输协议

## Decisions

### Decision 1: 事件中继机制设计

**选择:** 采用与 SSE Transport 类似的事件中继机制

**理由:**
- SSE Transport 已经实现了完整的事件中继功能
- 保持一致性可以减少维护成本
- 可以复用现有的事件处理逻辑

**实现细节:**
- 从 `Last-Event-ID` 中获取最后一个事件的 ID
- 查找该事件之后的所有未发送事件
- 将这些事件发送到客户端

### Decision 2: 事件存储和检索

**选择:** 使用内存存储事件，并提供事件检索功能

**理由:**
- 简单直接，适合当前需求
- 避免引入额外的依赖
- 可以满足大多数场景的需求

**实现细节:**
- 在 `McpServerSession` 中添加事件存储功能
- 为每个事件分配唯一的 ID
- 提供根据事件 ID 检索事件的方法

### Decision 3: 错误处理

**选择:** 采用与 SSE Transport 相同的错误处理策略

**理由:**
- 保持一致性，便于维护
- 提供良好的错误反馈

**实现细节:**
- 对无效的 `Last-Event-ID` 返回适当的错误响应
- 处理事件检索过程中的异常
- 记录详细的错误日志

## Risks / Trade-offs

### 风险 1: 内存消耗

**风险:** 存储大量事件可能导致内存消耗过高

**缓解:**
- 实现事件过期机制，自动清理旧事件
- 限制存储事件的最大数量
- 提供配置选项，允许用户调整事件存储策略

### 风险 2: 性能影响

**风险:** 事件存储和检索可能会影响性能

**缓解:**
- 使用高效的数据结构存储事件
- 优化事件检索算法
- 考虑使用异步处理事件存储

### 风险 3: 事件丢失

**风险:** 在服务器重启或崩溃时，未发送的事件可能会丢失

**缓解:**
- 考虑添加事件持久化机制（可选）
- 提供事件重传机制
- 优化服务器的可靠性

## Migration Plan

1. 实现 `relayEvents` 方法
2. 添加事件存储和检索功能
3. 优化错误处理和日志记录
4. 添加测试用例
5. 运行测试验证功能
6. 部署变更

## Open Questions

- 是否需要实现事件持久化机制？
- 事件存储的默认过期时间应该是多少？
- 是否需要提供配置选项来调整事件存储策略？
