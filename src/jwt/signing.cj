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

import std.collection.concurrent.ConcurrentHashMap

/**
 * 签名算法的接口
 */
public interface SigningMethod {
    /**
     * 返回此方法的算法标识符（示例：'HS256'）
     */
    prop alg: String

    /**
     * 使用算法的密钥对令牌进行签名
     *
     * @param signing 将被签名的字符串
     * @param key 算法的密钥，如 Array<Byte> 或 RSAPrivateKey
     * @throws JwtException 如果签名失败
     */
    func sign(signing: String, key: Any): Array<Byte>

    /**
     * 使用算法的密钥验证令牌
     *
     * @param signing 签名字符串
     * @param sig 用于检查的签名数据
     * @param key 算法的密钥，如 Array<Byte> 或 RSAPublicKey
     * @throws JwtException 如果验证失败
     */
    func verify(signing: String, sig: Array<Byte>, key: Any): Unit
}

/**
 * 签名方法管理器，用于注册和获取签名方法实例
 */
public class SigningMethods {
    public static let METHODS: ConcurrentHashMap<String, SigningMethod> = ConcurrentHashMap()

    /**
     * 注册签名方法
     *
     * @param alg 算法标识符
     * @param method 签名方法
     */
    public static func register(alg: String, method: SigningMethod): Unit {
        METHODS.add(alg, method)
    }

    /**
     * 按算法获取签名方法
     *
     * @param alg 算法标识符
     * @return 签名方法，如果未找到则返回 None
     */
    public static func getMethod(alg: String): ?SigningMethod {
        METHODS.get(alg)
    }
}
