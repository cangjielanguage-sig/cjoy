/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.jwt

import std.crypto.digest.digest
import stdx.crypto.digest.{HashType, HMAC}

class SigningMethodHmac <: SigningMethod {
    private let _alg: String
    private let _hashType: HashType

    init(alg: String, hashType: HashType) {
        _alg = alg
        _hashType = hashType
    }

    public prop alg: String {
        get() {
            _alg
        }
    }

    /**
     * 使用 HMAC 密钥签名字符串
     *
     * @param signing 要签名的字符串
     * @param key HMAC 密钥
     * @return 签名后的数据
     * @throws JwtException 如果签名失败
     */
    public func sign(signing: String, key: Any): Array<Byte> {
        if (key is Array<Byte>) {
            let hmac = HMAC((key as Array<Byte>).getOrThrow(), _hashType)
            digest(hmac, signing.toArray())
        } else {
            throw JwtException("key is of invalid type, HMAC verify expects []byte")
        }
    }

    /**
     * 使用 HMAC 密钥验证签名
     *
     * @param signing 已签名的字符串
     * @param sig 要验证的签名
     * @param key HMAC 密钥
     * @throws JwtException 如果验证失败
     */
    public func verify(signing: String, sig: Array<Byte>, key: Any): Unit {
        if (key is Array<Byte>) {
            let signed = sign(signing, (key as Array<Byte>).getOrThrow())
            if (signed != sig) {
                throw JwtException("signature is invalid")
            }
        } else {
            throw JwtException("key is of invalid type, HMAC verify expects []byte")
        }
    }
}

let _: Unit = SigningMethods.register("HS256", SigningMethodHmac("HS256", HashType.SHA256))

let _: Unit = SigningMethods.register("HS384", SigningMethodHmac("HS384", HashType.SHA384))

let _: Unit = SigningMethods.register("HS512", SigningMethodHmac("HS512", HashType.SHA512))
