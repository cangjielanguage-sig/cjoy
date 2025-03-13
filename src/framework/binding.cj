/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import encoding.url.Form
import net.http.HttpHeaders

/**
* the interface of binding
*/
public interface JoyBindable<T> {
    /**
    *
    * bind http request query, postform or header params to object
    * 
    * @param request: the http request
    * @return the object
    */
    static func bind(source: BindSource): T
}

public interface BindSource {
    func getOne(name: String): ?String
    func getAll(name: String): Collection<String>
}

extend Form <: BindSource {
    public func getOne(name: String): ?String {
        this.get(name)
    }
}

extend HttpHeaders <: BindSource {
    public func getOne(name: String): ?String {
        this.getFirst(name)
    }
    public func getAll(name: String): Collection<String> {
        this.get(name)
    }
}