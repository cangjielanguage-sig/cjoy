/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.session

import std.fs.*

@Test
public class FileSessionStorageTestCaseSuit {
    @TestCase
    public func testFileStorageSave() {
        let storage = FileSessionStorage("./session")
        let session = storage.createSession("123")
        session.set("1", "value1")
        session.set("2", "value2")
        session.flush()
        @Assert(exists("./session/123/1"))
        @Assert(exists("./session/123/2"))
        
        session.invalidate()
        @Assert(!exists("./session/123/1"))
        @Assert(!exists("./session/123/2"))
        removeIfExists("./session", recursive: true)
    }

    @TestCase
    public func testFileStorageSave2() {
        let storage = FileSessionStorage("./session")
        let session = storage.createSession("123")
        session.set("1", "value1")
        session.set("2", "value2")
        session.flush()
        @Assert(exists("./session/123/1"))
        @Assert(exists("./session/123/2"))

        session.remove<String>("2")
        session.flush()
        @Assert(!exists("./session/123/2"))

        session.invalidate()
        @Assert(!exists("./session/123/1"))
        removeIfExists("./session", recursive: true)
    }

    @TestCase
    public func testFileStorageGet() {
        let storage = FileSessionStorage("./session")
        let session = storage.getOrCreate("", 8)
        session.set("1", "value1")
        session.flush()
        @Assert(storage.exists(session.id))

        // get session from storage
        let sess = storage.getOrCreate(session.id, 8)
        let value = sess.get<String>("1") ?? ""
        @Assert(value, "value1")

        // delete session
        session.invalidate()
        @Assert(session.isInvalidated)
        @Assert(!storage.exists(session.id))
        removeIfExists("./session", recursive: true)
    }

    @TestCase
    public func testFileStorageLoad() {
        let storage = FileSessionStorage("./session")
        let session = storage.createSession("123")
        session.set("1", "value1")
        session.flush()

        // not in memory, will load from disk
        let sess = storage.getOrCreate("123", 8)
        let value = sess.get<String>("1") ?? ""
        @Assert(value, "value1")
        removeIfExists("./session", recursive: true)
    }

     @TestCase
    public func testFileStorageClean() {
        let storage = FileSessionStorage("./session", maxLifetime: Duration.second)
        let session = storage.createSession("123")
        session.set("1", "value1")
        session.flush()

        sleep(Duration.second*1.5)
        storage.clean()
        @Assert(!storage.exists(session.id))
        removeIfExists("./session", recursive: true)
    }
}
