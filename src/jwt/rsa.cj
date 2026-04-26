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

import std.crypto.digest.Digest
import std.fs.{File, OpenMode}
import std.io.{readToEnd}
import std.crypto.digest.digest
import stdx.crypto.digest.{SHA256, SHA384, SHA512}
import stdx.crypto.keys.{RSAPrivateKey, RSAPublicKey, PadOption, PSSOption}

/**
 * 从文件加载 RSA 私钥
 */
public func loadRSAPrivateKey(path: String): RSAPrivateKey {
    RSAPrivateKey.decodeFromPem(readPermFile(path))
}

/**
 * 使用密码从文件加载 RSA 私钥
 */
public func loadRSAPrivateKey(path: String, password!: ?String): RSAPrivateKey {
    RSAPrivateKey.decodeFromPem(readPermFile(path), password: password)
}

/**
 * 从文件加载 RSA 公钥
 */
public func loadRSAPublicKey(path: String): RSAPublicKey {
    RSAPublicKey.decodeFromPem(readPermFile(path))
}

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

    /**
     * 使用 RSA 私钥签名字符串
     *
     * @param signing 要签名的字符串
     * @param key RSA 私钥
     * @return 签名后的数据
     * @throws JwtException 如果签名失败
     */
    public func sign(signing: String, key: Any): Array<Byte> {
        match (key) {
            case pk: RSAPrivateKey => try {
                let md = digest(_hash, signing.toArray())
                pk.sign(_hash, md, padType: _pad)
            } catch (ex: Exception) {
                throw JwtException("crypto failed, ${ex.message}")
            }
            case _ => throw JwtException("key is of invalid type, RSA verify expects RSAPrivateKey")
        }
    }

    /**
     * 使用 RSA 公钥验证签名
     *
     * @param signing 已签名的字符串
     * @param sig 要验证的签名
     * @param key RSA 公钥
     * @throws JwtException 如果验证失败
     */
    public func verify(signing: String, sig: Array<Byte>, key: Any): Unit {
        match (key) {
            case pk: RSAPublicKey => try {
                let md = digest(_hash, signing.toArray())
                if (!pk.verify(_hash, md, sig, padType: _pad)) {
                    throw JwtException("signature is invalid")
                }
            } catch (ex: Exception) {
                throw JwtException("verify failed, ${ex.message}")
            }
            case _ => throw JwtException("key is of invalid type, RSA verify expects RSAPublicKey")
        }
    }
}

private func readPermFile(path: String): String {
    try (file = File(path, Read)) {
        return String.fromUtf8(readToEnd(file))
    }
    ""
}

const PSS_LEN: Int32 = 16

let _: Unit = SigningMethods.register("RS256", SigningMethodRsa("RS256", SHA256(), PadOption.PKCS1))

let _: Unit = SigningMethods.register("RS384", SigningMethodRsa("RS384", SHA384(), PadOption.PKCS1))

let _: Unit = SigningMethods.register("RS512", SigningMethodRsa("RS512", SHA512(), PadOption.PKCS1))

let _: Unit = SigningMethods.register("PS256", SigningMethodRsa("PS256", SHA256(), PadOption.PSS(PSSOption(PSS_LEN))))

let _: Unit = SigningMethods.register("PS384", SigningMethodRsa("PS384", SHA384(), PadOption.PSS(PSSOption(PSS_LEN))))

let _: Unit = SigningMethods.register("PS512", SigningMethodRsa("PS512", SHA512(), PadOption.PSS(PSSOption(PSS_LEN))))
