/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.jwt

import std.crypto.digest.Digest
import stdx.crypto.digest.{SHA256, SHA384, SHA512}
import stdx.crypto.keys.{RSAPrivateKey, RSAPublicKey, PadOption, PSSOption}

class SigningMethodRsa <: SigningMethod {
    private let _alg: String
    private let _hash: Digest
    private let _pad: PadOption

    init(alg: String, hash: Digest, pad: PadOption) {
        _alg = alg
        _hash = hash
        _pad = pad
    }

    public prop alg: String {
        get() {
            _alg
        }
    }

    public func sign(signing: String, key: Any): Array<Byte> {
        match (key) {
            case pk: RSAPrivateKey => pk.sign(_hash, signing.toArray(), padType: _pad)
            case _ => throw JwtException("key is of invalid type, RSA verify expects RSAPrivateKey")
        }
    }

    public func verify(signing: String, sig: Array<Byte>, key: Any): Unit {
        match (key) {
            case pk: RSAPublicKey =>
                if (!pk.verify(_hash, signing.toArray(), sig, padType: _pad)) {
                    throw JwtException("signature is invalid")
                }
            case _ => throw JwtException("key is of invalid type, RSA verify expects RSAPublicKey")
        }
    }
}

let _: Unit = SigningMethods.register("RS256", SigningMethodRsa("RS256", SHA256(), PadOption.PKCS1))

let _: Unit = SigningMethods.register("RS384", SigningMethodRsa("RS384", SHA384(), PadOption.PKCS1))

let _: Unit = SigningMethods.register("RS512", SigningMethodRsa("RS512", SHA512(), PadOption.PKCS1))

let _: Unit = SigningMethods.register("PS256", SigningMethodRsa("PS256", SHA256(), PadOption.PSS(PSSOption(16))))

let _: Unit = SigningMethods.register("PS384", SigningMethodRsa("PS384", SHA384(), PadOption.PSS(PSSOption(16))))

let _: Unit = SigningMethods.register("PS512", SigningMethodRsa("PS512", SHA512(), PadOption.PSS(PSSOption(16))))
