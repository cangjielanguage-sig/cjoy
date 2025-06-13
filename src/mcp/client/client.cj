/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

protected package cjoy.mcp.client

import std.sync.AtomicBool
import cjoy.mcp.schema.*
import cjoy.mcp.common.*
import cjoy.utils.TimeoutCache
import cjoy.log.LogTool

public func createMcpSseClient(url: String, features!: McpClientFeatures = McpClientFeatures()): McpClient {
    let transport = McpSseClientTransport(url)
    DefaultMcpClient(features, transport)
}

public class McpClientFeatures {
    public var protocolVesions: Array<String> = [McpConsts.LASTEST_PROTOCOL_VERSION]
    public var requestTimeout = Duration.second * 30
    public var clientInfo: Implementation = Implementation(name: "cjoy", version: "1.0")
    public var clientCapabilities: ClientCapabilities = ClientCapabilities()
}

public class DefaultMcpClient <: McpClient {
    private let _features: McpClientFeatures
    private let _session: McpClientSession
    private let _initialized: AtomicBool = AtomicBool(false)
    private var _serverCapabilities: ?ServerCapabilities = None
    private var _serverInfo: ?Implementation = None
    private var _serverInstructions: ?String = None
    private var _isClosed: Bool = false

    init(features: McpClientFeatures, transport: McpClientTransport) {
        _features = features
        _session = DefaultMcpClientSession(transport, features.requestTimeout)
        addNotificationConsumers(_session)
        transport.whenReConnect({
            => doInitialize()
        })
    }

    public prop serverCapabilities: ?ServerCapabilities {
        get() {
            _serverCapabilities
        }
    }

    public prop serverInfo: ?Implementation {
        get() {
            _serverInfo
        }
    }

    private func addNotificationConsumers(session: McpSession) {
        session.addNotificationConsumer(McpConsts.METHOD_NOTIFICATION_TOOLS_LIST_CHANGED, {
            consumer =>
        })
    }

    private func checkInitialized() {
        if (!_initialized.load()) {
            throw McpException(JSONRPCError(code: McpConsts.ERR_INTERNAL_ERROR, message: "server is not initialized"))
        }
    }

    private func checkToolCapbilities() {
        if (_serverCapabilities.isSome() && _serverCapabilities.getOrThrow().tools.isNone()) {
            throw McpException(
                JSONRPCError(code: McpConsts.ERR_INTERNAL_ERROR, message: "server not provide tool capbilities"))
        }
    }

    public func ping(): Unit {
        checkInitialized()
        let _: String = _session.sendRequest(McpConsts.METHOD_PING, "")
    }

    public func initialize(): InitializeResult {
        _session.connect()
        doInitialize()
    }

    private func doInitialize(): InitializeResult {
        let request = InitializeRequest(capabilities: _features.clientCapabilities, clientInfo: _features.clientInfo)
        let result: InitializeResult = _session.sendRequest(McpConsts.METHOD_INITIALIZE, request)
        _serverCapabilities = result.capabilities
        _serverInfo = result.serverInfo
        _serverInstructions = result.instructions
        LogTool.info(
            "[MCP]initialize server response with protocol:${result.protocolVersion}, capabilities:${_serverCapabilities}, info:${_serverInfo}, instructions:${_serverInstructions}"
        )

        if (!_features.protocolVesions.contains(result.protocolVersion)) {
            let msg = "[MCP]unsupported protocal version[${result.protocolVersion}] from server"
            LogTool.info(msg)
            throw McpException(JSONRPCError(code: McpConsts.ERR_INVALID_PARAMS, message: msg))
        }

        _session.sendNotification(McpConsts.METHOD_NOTIFICATION_INITIALIZED)
        _initialized.store(true)
        LogTool.info("[MCP]client initialized")
        result
    }

    public func listTools(cursor: ?String): ListToolsResult {
        checkInitialized()
        checkToolCapbilities()
        let result: ListToolsResult = _session.sendRequest(McpConsts.METHOD_TOOLS_LIST, PaginatedRequest(cursor: cursor)
        )
        LogTool.info("[MCP]list tool result:${result}")
        result
    }

    public func callTool(request: CallToolRequest): CallToolResult {
        checkInitialized()
        checkToolCapbilities()
        LogTool.info("[MCP]call tool request:${request}")
        let result: CallToolResult = _session.sendRequest(McpConsts.METHOD_TOOLS_CALL, request)
        LogTool.info("[MCP]call tool result:${result}")
        result
    }

    public func close() {
        if (_isClosed) {
            return
        }
        _session.close()
        _isClosed = true
    }

    public func isClosed(): Bool {
        _isClosed
    }
}
