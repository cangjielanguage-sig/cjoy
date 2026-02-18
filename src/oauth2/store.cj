/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.oauth2

import std.collection.concurrent.ConcurrentHashMap
import std.time.DateTime

/**
 * TokenStore 接口用于存储令牌信息
 */
public interface TokenStore {
    /**
     * 创建并存储新的令牌信息
     *
     * @param tokenInfo 要存储的令牌信息
     */
    func create(tokenInfo: TokenInfo): Unit

    /**
     * 根据授权码删除令牌信息
     *
     * @param code 授权码
     */
    func removeByCode(code: String): Unit

    /**
     * 根据访问令牌删除令牌信息
     *
     * @param access 访问令牌
     */
    func removeByAccess(access: String): Unit

    /**
     * 根据刷新令牌删除令牌信息
     *
     * @param refresh 刷新令牌
     */
    func removeByRefresh(refresh: String): Unit

    /**
     * 根据授权码获取令牌信息
     *
     * @param code 授权码
     * @return 令牌信息，如果未找到则返回 None
     */
    func getByCode(code: String): ?TokenInfo

    /**
     * 根据访问令牌获取令牌信息
     *
     * @param access 访问令牌
     * @return 令牌信息，如果未找到则返回 None
     */
    func getByAccess(access: String): ?TokenInfo

    /**
     * 根据刷新令牌获取令牌信息
     *
     * @param refresh 刷新令牌
     * @return 令牌信息，如果未找到则返回 None
     */
    func getByRefresh(refresh: String): ?TokenInfo
}

/**
 * ClientStore 接口用于存储客户端信息
 */
public interface ClientStore {
    /**
     * 根据客户端 ID 获取客户端信息
     *
     * @param id 客户端 ID
     * @return 客户端信息，如果未找到则返回 None
     */
    func getById(id: String): ?ClientInfo

    /**
     * 将客户端信息添加到存储中
     *
     * @param clientInfo 要添加的客户端信息
     */
    func add(clientInfo: ClientInfo): Unit
}

/**
 * 基于内存的客户端存储实现
 */
public class MemoryClientStore <: ClientStore {
    private let _data: ConcurrentHashMap<String, ClientInfo> = ConcurrentHashMap()

    /**
     * 根据 ID 获取客户端信息
     *
     * @param id 客户端 ID
     * @return 客户端信息，如果未找到则返回 None
     */
    public func getById(id: String): ?ClientInfo {
        _data.get(id)
    }

    /**
     * 向存储中添加客户端信息
     *
     * @param clientInfo 要添加的客户端信息
     */
    public func add(clientInfo: ClientInfo): Unit {
        _data.add(clientInfo.id, clientInfo)
    }
}

class TokenStoreItem {
    TokenStoreItem(let _info: TokenInfo, let _type: String) {
    }
}

/**
 * 带有自动清理功能的基于内存的令牌存储实现
 */
public class MemoryTokenStore <: TokenStore {
    private let _data: ConcurrentHashMap<String, TokenStoreItem>
    private let _future: Future<Unit>

    /**
     * 初始化内存令牌存储
     */
    public init() {
        let data = ConcurrentHashMap<String, TokenStoreItem>()
        _data = data
        _future = spawn {
            while (!Thread.currentThread.hasPendingCancellation) {
                sleep(5 * Duration.second)
                cleanExpired(data)
            }
        }
    }

    /**
     * 销毁令牌存储并停止清理任务
     */
    public func destroy(): Unit {
        _future.cancel()
    }

    private static func cleanExpired(data: ConcurrentHashMap<String, TokenStoreItem>): Unit {
        let iter = data.iterator()
        let now = DateTime.now()
        while (let Some(it) <- iter.next()) {
            let d = it[1]
            match (d._type) {
                case "code" =>
                    if (d._info.codeExpiredIn > 0 && d._info.codeCreateAt.addSeconds(d._info.codeExpiredIn) <= now) {
                        data.remove(d._info.code)
                    }
                case "access" =>
                    if (d._info.accessExpiredIn > 0 && d._info.accessCreateAt.addSeconds(d._info.accessExpiredIn) <= now) {
                        data.remove(d._info.access)
                    }
                case "refresh" =>
                    if (d._info.refreshExpiredIn > 0 && d._info.refreshCreateAt.addSeconds(d._info.refreshExpiredIn) <=
                        now) {
                        data.remove(d._info.refresh)
                    }
                case _ => ()
            }
        }
    }

    /**
     * 创建并存储令牌信息
     *
     * @param tokenInfo 要存储的令牌信息
     */
    public func create(tokenInfo: TokenInfo): Unit {
        if (tokenInfo.code != "") {
            _data.add(tokenInfo.code, TokenStoreItem(tokenInfo, "code"))
        }

        if (tokenInfo.access != "") {
            if (tokenInfo.refresh != "" && tokenInfo.codeExpiredIn > 0) {
                let rexp = tokenInfo.refreshCreateAt.addSeconds(tokenInfo.refreshExpiredIn) - DateTime.now()
                if (tokenInfo.accessExpiredIn > rexp.toSeconds()) {
                    tokenInfo.accessExpiredIn = rexp.toSeconds()
                }
            }
            _data.add(tokenInfo.access, TokenStoreItem(tokenInfo, "access"))
        }

        if (tokenInfo.refresh != "") {
            _data.add(tokenInfo.refresh, TokenStoreItem(tokenInfo, "refresh"))
        }
    }

    /**
     * 根据授权码删除令牌
     *
     * @param code 授权码
     */
    public func removeByCode(code: String): Unit {
        _data.remove(code)
    }

    /**
     * 根据访问令牌删除令牌
     *
     * @param access 访问令牌
     */
    public func removeByAccess(access: String): Unit {
        _data.remove(access)
    }

    /**
     * 根据刷新令牌删除令牌
     *
     * @param refresh 刷新令牌
     */
    public func removeByRefresh(refresh: String): Unit {
        _data.remove(refresh)
    }

    /**
     * 根据授权码获取令牌信息
     *
     * @param code 授权码
     * @return 令牌信息，如果未找到则返回 None
     */
    public func getByCode(code: String): ?TokenInfo {
        _data.get(code).map {it: TokenStoreItem => it._info}
    }

    /**
     * 根据访问令牌获取令牌信息
     *
     * @param access 访问令牌
     * @return 令牌信息，如果未找到则返回 None
     */
    public func getByAccess(access: String): ?TokenInfo {
        _data.get(access).map {it: TokenStoreItem => it._info}
    }

    /**
     * 根据刷新令牌获取令牌信息
     *
     * @param refresh 刷新令牌
     * @return 令牌信息，如果未找到则返回 None
     */
    public func getByRefresh(refresh: String): ?TokenInfo {
        _data.get(refresh).map {it: TokenStoreItem => it._info}
    }
}
