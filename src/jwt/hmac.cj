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
     * sign string with HMAC key
     *
     * @param signing: string to be signed
     * @param key: HMAC key
     * @return: signed data
     * @throws JwtException if sign failed
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
     * verify signature with HMAC key
     *
     * @param signing: signed string
     * @param sig: signature to verify
     * @param key: HMAC key
     * @throws JwtException if verify failed
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
