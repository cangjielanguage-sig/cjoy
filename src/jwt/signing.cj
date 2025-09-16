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

import std.collection.concurrent.ConcurrentHashMap

/**
 * the interface for singing algorithm
 */
public interface SigningMethod {
    /**
     * return the algorithm identifier for this method (example: 'HS256')
     */
    prop alg: String

    /**
     * signing the token using the key with the algorithm
     *
     * @param signing: the string will be sign
     * @param key: the key of algorithm, like Array<Byte> or RSAPrivateKey
     */
    func sign(signing: String, key: Any): Array<Byte>

    /**
     * verify the token using the key with the algorithm
     *
     * @param signing: the signing string
     * @param sig: the signed data for checking
     * @param key: the key of algorithm, like Array<Byte> or RSAPublicKey
     */
    func verify(signing: String, sig: Array<Byte>, key: Any): Unit
}

public class SigningMethods {
    public static let METHODS: ConcurrentHashMap<String, SigningMethod> = ConcurrentHashMap()

    public static func register(alg: String, method: SigningMethod): Unit {
        METHODS.add(alg, method)
    }

    public static func getMethod(alg: String): ?SigningMethod {
        METHODS.get(alg)
    }
}
