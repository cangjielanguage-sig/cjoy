/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import std.collection.ArrayList
import std.collection.HashMap
import std.convert.Parsable
import stdx.net.http.{HttpStatusCode}
import cjoy.framework.{JoyContext}
import cjoy.mcp.api.{PaginatedRequest, PaginatedResult}
import cjoy.log.macros.*
import cjoy.jsonrpc.api.{JSONRPCRequest, JSONRPCResponse, JSONRPCMessage, JSONRPCTool, JSONRPCError, JSONRPCConsts,
    JSONRPCException}

/**
 * 检查给定地址是否为回环地址
 *
 * @param address 要检查的地址
 * @return 如果是回环地址返回 true
 */
func isLoopbackAddress(address: String): Bool {
    let addr = address
    return addr.startsWith("127.0.0.1") || 
        addr.startsWith("localhost") || 
        addr.startsWith("[::1]") || 
        addr.contains("localhost:") || 
        addr.contains("127.0.0.1:") || 
        addr.contains("[::1]:")
}


/**
* 验证 localhost 连接的 DNS 重绑定保护
*
* @param ctx 请求的 JoyContext
* @param disableLocalhostProtection 禁用 localhost 保护
* @return 如果通过 DNS 重绑定保护或已禁用返回 true
*/
func validateLocalhostProtection(ctx: JoyContext, disableLocalhostProtection: Bool): Bool {
    if (disableLocalhostProtection) {
        return true
    }

    // Check if request is from loopback address
    let clientIP = ctx.getClientIP()
    let isLoopbackClient = isLoopbackAddress(clientIP)

    // Check if host header is loopback address
    let hostHeader = ctx.getHeader("Host") ?? ""
    let isLoopbackHost = isLoopbackAddress(hostHeader)

    // If server is listening on loopback but host header is not, reject the request
    if (isLoopbackClient && !isLoopbackHost) {
        let err = createErrorMsg("Forbidden: Invalid Host header for localhost connection")
        ctx.status(HttpStatusCode.STATUS_FORBIDDEN).json(err)
        return false
    }

    return true
}


/**
* 创建带有错误消息的 JSONRPCResponse
*
* @param msg 错误消息
* @param code 错误代码（默认：JSONRPCConsts.ERR_INVALID_REQUEST）
* @param data 额外的错误数据（可选）
* @return 包含错误信息的 JSONRPCResponse
*/
func createErrorMsg(msg: String, code!: Int = JSONRPCConsts.ERR_INVALID_REQUEST, data!: ?Any = None): JSONRPCResponse {
    @JoyLogError("[MCP] Error occurred")
    if (data.isSome()) {
        @JoyLogDebug("[MCP] Error data available")
    }
    let err = JSONRPCError(code: code, message: msg, data: data)
    JSONRPCResponse(id: "server-error", error: err)
}


/**
* 从请求上下文中获取用户ID
* 在实际应用中，这里应该从JWT token或其他认证方式中提取用户ID
*/
func getUserIDFromContext(ctx: JoyContext): String {
    // 从Authorization头中提取用户ID（简单示例）
    if (let Some(userId) <- ctx.getParam("userID")) {
        return userId
    }
    return ""
}

/**
 * 分页工具类
 *
 * 提供统一的分页逻辑，支持基于游标的分页方式，提高数据一致性
 */
public struct McpPaginationUtils {
    private let pageSize: Int

    /**
     * 创建分页工具实例
     */
    public init(pageSize!: Int = 10) {
        this.pageSize = pageSize
    }

    /**
     * 对集合进行分页
     */
    public func paginate<T>(collection: ArrayList<T>, request: PaginatedRequest): (ArrayList<T>, ?String) {
        let startIndex = parseCursor(request)
        let endIndex = startIndex + pageSize

        var result = ArrayList<T>()
        var nextCursor: ?String = None

        if (collection.size <= startIndex) {
            return (result, None)
        }

        let actualEndIndex = if (endIndex > collection.size) {
            collection.size
        } else {
            endIndex
        }

        for (i in startIndex..actualEndIndex) {
            result.add(collection[i])
        }

        if (actualEndIndex < collection.size) {
            nextCursor = "${actualEndIndex}"
        }

        return (result, nextCursor)
    }

    /**
     * 对 Map 进行分页
     */
    public func paginate<K, V>(collection: HashMap<K, V>, request: PaginatedRequest): (ArrayList<V>, ?String) where K<: Hashable & Comparable<K> {
        let startIndex = parseCursor(request)
        let endIndex = startIndex + pageSize

        var result = ArrayList<V>()
        var nextCursor: ?String = None
        var currentIndex = 0

        for ((_, value) in collection) {
            if (currentIndex >= startIndex && result.size < pageSize) {
                result.add(value)
            }
            currentIndex += 1
        }

        if (currentIndex > startIndex + pageSize) {
            nextCursor = "${startIndex + pageSize}"
        }

        return (result, nextCursor)
    }

    /**
     * 解析分页游标
     */
    private func parseCursor(request: PaginatedRequest): Int {
        return request.cursor.map { it: String =>Int.tryParse(it) ?? 0 } ?? 0
    }

    /**
     * 获取默认页面大小
     */
    public func getPageSize(): Int {
        return pageSize
    }
}

/**
 * 提供默认的分页工具实例
 */
public let paginationUtils = McpPaginationUtils()
