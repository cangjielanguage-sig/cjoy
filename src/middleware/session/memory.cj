/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware.session

/**
* the memory session
*/
class MemorySession <: AbstractSession {
    public init(sid: String) {
        super(sid)
    }
}

/**
 * create memory session storage
 */
public class MemorySessionStorage <: AbstractSessionStorage {
    /*
     * @param maxLifetime: max life time in seconds. Default is 3600.
     */
    public init(maxLifetime!: Int = 3600) {
        super( maxLifetime)
    }

    protected func createSession(sid: String): AbstractSession {
        MemorySession(sid)
    }
}
