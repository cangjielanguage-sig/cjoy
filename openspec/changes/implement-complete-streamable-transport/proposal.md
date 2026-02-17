# 实现完整的 Streamable Transport 服务端能力

## Why

当前 CJoy MCP 模块中的 `McpStreamableServerTransport` 类存在功能不完整的问题，特别是 `relayEvents` 方法尚未实现，这会影响到 Streamable Transport 的事件中继功能。为了提供完整的 MCP (Model Context Protocol) 服务端能力，需要完善 Streamable Transport 的实现。

## What Changes

- 实现 `relayEvents` 方法，完成事件中继功能
- 检查并完善 `McpStreamableServerTransport` 类的其他潜在问题
- 确保 Streamable Transport 与 SSE Transport 功能一致性
- 添加相关测试用例，验证 Streamable Transport 的完整功能

## Capabilities

### New Capabilities
- `streamable-transport`: 完整的 Streamable Transport 服务端能力，包括事件中继功能

### Modified Capabilities
- `mcp-server`: 完善 McpServer 类中 Streamable Transport 的注册和管理功能

## Impact

- 受影响文件: `src/mcp/server/server_streamable_transport.cj`
- API 变更: 无
- 依赖变更: 无
- 系统影响: 提升 MCP 服务端的可靠性和功能完整性

## 回滚计划

如果变更引入了问题，可以通过以下方式回滚：

1. 恢复 `src/mcp/server/server_streamable_transport.cj` 文件到变更前的状态
2. 运行 `cjpm test` 验证回滚后的功能
3. 重新部署应用程序

回滚过程简单且风险较低，因为变更主要集中在单个文件的功能完善上。
