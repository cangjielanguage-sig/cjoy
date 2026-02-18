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

import std.time.DateTime
import std.io.ByteBuffer
import std.crypto.digest.digest
import stdx.crypto.digest.{HashType, HMAC}
import stdx.crypto.crypto.SecureRandom
import cjoy.utils.{rawBase64URLEncode}

/**
 * TokenGenerate 接口用于生成访问和刷新令牌
 */
public interface TokenGenerate {
    /**
     * 生成访问和刷新令牌
     *
     * @param data 令牌生成的基础数据
     * @param isGenRefresh 是否生成刷新令牌
     * @return (访问令牌, 刷新令牌) 的元组
     */
    func generate(data: GenerateBasic, isGenRefresh: Bool): (String, String)
}

/**
 * 使用安全随机数的访问和刷新令牌生成器
 */
public class SecureRandTokenGenerate <: TokenGenerate {
    /**
     * 使用安全随机数生成访问和刷新令牌
     *
     * @param data 生成的基础数据
     * @param isGenRefresh 是否生成刷新令牌
     * @return (访问令牌, 刷新令牌) 的元组
     */
    public func generate(data: GenerateBasic, isGenRefresh: Bool): (String, String) {
        let buffer = ByteBuffer()
        buffer.write(data.client.id.toArray())
        buffer.write(data.userId.toArray())
        buffer.write(data.createAt.toUnixTimeStamp().toMilliseconds().toString().toArray())

        let sr = SecureRandom()
        let key = sr.nextBytes(8)

        let hmac = HMAC(key, HashType.MD5)
        let accessBs = digest(hmac, buffer.bytes())
        let access = rawBase64URLEncode(accessBs)

        let refresh = if (isGenRefresh) {
            let hmac2 = HMAC(key, HashType.SHA1)
            let bs = digest(hmac2, buffer.bytes())
            rawBase64URLEncode(bs)
        } else {
            ""
        }

        (access, refresh)
    }
}
