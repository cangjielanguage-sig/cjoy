/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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
 * the inteface to store the token information
 */
public interface TokenStore {
    /**
     *  create and store the new token information
     */
    func create(tokenInfo: TokenInfo): Unit

    /**
     * delete the authorization code
     */
    func removeByCode(code: String): Unit

    /**
     *  use the access token to delete the token information
     */
    func removeByAccess(access: String): Unit

    /**
     * use the refresh token to delete the token information
     */
    func removeByRefresh(refresh: String): Unit

    /**
     * use the authorization code for token information data
     */
    func getByCode(code: String): ?TokenInfo

    /**
     * use the access token for token information data
     */
    func getByAccess(access: String): ?TokenInfo

    /**
     * use the refresh token for token information data
     */
    func getByRefresh(refresh: String): ?TokenInfo
}

/**
 * the inteface to store the client information
 */
public interface ClientStore {
    /**
     * according to the id for the client information
     */
    func getById(id: String): ?ClientInfo

    func add(clientInfo: ClientInfo): Unit
}

public class MemoryClientStore <: ClientStore {
    private let _data: ConcurrentHashMap<String, ClientInfo> = ConcurrentHashMap()

    public func getById(id: String): ?ClientInfo {
        _data.get(id)
    }

    public func add(clientInfo: ClientInfo): Unit {
        _data.add(clientInfo.id, clientInfo)
    }
}

class TokenStoreItem {
    TokenStoreItem(let _info: TokenInfo, let _type: String) {
    }
}

public class MemoryTokenStore <: TokenStore {
    private let _data: ConcurrentHashMap<String, TokenStoreItem>
    private let _future: Future<Unit>

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

    public func removeByCode(code: String): Unit {
        _data.remove(code)
    }

    public func removeByAccess(access: String): Unit {
        _data.remove(access)
    }

    public func removeByRefresh(refresh: String): Unit {
        _data.remove(refresh)
    }

    public func getByCode(code: String): ?TokenInfo {
        _data.get(code).map {it: TokenStoreItem => it._info}
    }

    public func getByAccess(access: String): ?TokenInfo {
        _data.get(access).map {it: TokenStoreItem => it._info}
    }

    public func getByRefresh(refresh: String): ?TokenInfo {
        _data.get(refresh).map {it: TokenStoreItem => it._info}
    }
}
