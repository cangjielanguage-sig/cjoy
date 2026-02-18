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

import std.io.ByteBuffer
import std.crypto.digest.digest
import stdx.crypto.digest.{HashType, HMAC}
import stdx.crypto.crypto.SecureRandom
import cjoy.utils.{rawBase64URLEncode}

/**
 * 授权码生成接口
 */
public interface CodeGenerate {
    /**
     * 生成授权码
     *
     * @param data 生成授权码的基础数据
     * @return 生成的授权码
     */
    func generate(data: GenerateBasic): String
}

/**
 * 使用安全随机数的授权码生成器
 */
public class SecureRandCodeGenerate <: CodeGenerate {
    /**
     * 使用安全随机数生成授权码
     *
     * @param data 生成授权码的基础数据
     * @return 生成的授权码
     */
    public func generate(data: GenerateBasic): String {
        let buffer = ByteBuffer()
        buffer.write(data.client.id.toArray())
        buffer.write(data.userId.toArray())

        let sr = SecureRandom()
        let key = sr.nextBytes(8)

        let hmac = HMAC(key, HashType.MD5)
        let accessBs = digest(hmac, buffer.bytes())
        rawBase64URLEncode(accessBs)
    }
}
