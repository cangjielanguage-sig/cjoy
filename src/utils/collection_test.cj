/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.unittest.testmacro.*
import std.collection.{ArrayList, HashMap}

@Test
public class CollectionTestCaseSuit {
    /**
     * 测试列表转换器功能 - 验证将 ArrayList<Any> 转换为 ListToString
     */
    @TestCase
    public func testConverterList() {
        let list = ArrayList<Any>()
        list.add(1)
        list.add("2")
        list.add(3.5)

        let converted = converterList<Any, ToString>(list)
        @Assert(converted.size, 3)
        @Assert(converted.get(0).toString(), "Some(1)")
        @Assert(converted.get(1).toString(), "Some(2)")
        @Assert(converted.get(2).toString(), "Some(3.500000)")
    }

    /**
     * 测试映射转换器功能 - 验证将 HashMap<String, Any> 转换为 MapToString
     */
    @TestCase
    public func testConverterMap() {
        let map = HashMap<String, Any>()
        map.add("key1", 1)
        map.add("key2", "value2")
        map.add("key3", 3.5)

        let converted = converterMap<Any, ToString>(map)
        @Assert(converted.size, 3)
        @Assert(converted.getString("key1").getOrThrow(), "1")
        @Assert(converted.getString("key2").getOrThrow(), "value2")
        @Assert(converted.getString("key3").getOrThrow(), "3.500000")
    }

    /**
     * 测试 MapListGetFunc 在映射上的功能 - 验证 MapToString 类型的各种 get 方法
     */
    @TestCase
    public func testMapListGetFuncMap() {
        let map = HashMap<String, ToString>()
        map.add("string", "test")
        map.add("int", 123)
        map.add("float", 3.14)
        map.add("bool", true)

        @Assert(map.getString("string").getOrThrow(), "test")
        @Assert(map.getInt("int").getOrThrow(), 123)
        @Assert(map.getFloat("float").getOrThrow(), 3.14)
        @Assert(map.getBool("bool").getOrThrow(), true)
    }

    /**
     * 测试 MapListGetFunc 在列表上的功能 - 验证 ListToString 类型的各种 get 方法
     */
    @TestCase
    public func testMapListGetFuncList() {
        let list = ArrayList<ToString>()
        list.add("test")
        list.add(123)
        list.add(3.14)
        list.add(true)

        @Assert(list.getString(0).getOrThrow(), "test")
        @Assert(list.getInt(1).getOrThrow(), 123)
        @Assert(list.getFloat(2).getOrThrow(), 3.14)
        @Assert(list.getBool(3).getOrThrow(), true)
    }

    /**
     * 测试超时缓存基本功能 - 验证添加、获取和删除操作
     */
    @TestCase
    public func testTimeoutCacheBasic() {
        let cache = TimeoutCache<String, Int>(Duration.minute, {k, v => ()})

        cache.add("key1", 100)
        @Assert(cache.get("key1").getOrThrow(), 100)

        cache.add("key1", 200)
        @Assert(cache.get("key1").getOrThrow(), 200)

        cache.remove("key1")
        @Assert(cache.get("key1").isNone(), true)

        cache.close()
    }

    /**
     * 测试超时缓存过期功能 - 验证缓存项在超时后会被自动删除
     */
    @TestCase
    public func testTimeoutCacheExpiration() {
        let cache = TimeoutCache<String, Int>(Duration.millisecond *500, {k, v => ()})

        cache.add("key1", 100)
        @Assert(cache.get("key1").getOrThrow(), 100)

        // 等待过期
        sleep(Duration.millisecond*1500)

        @Assert(cache.get("key1").isNone(), true)

        cache.close()
    }

    /**
     * 测试超时缓存并发访问 - 验证在高并发场景下的稳定性
     */
    @TestCase
    public func testTimeoutCacheConcurrent() {
        let cache = TimeoutCache<String, Int>(Duration.minute, {k, v => ()})

        // 并发添加和获取
        let futures = ArrayList<Future<Unit>>()
        for (i in 0..100) {
            let key = "key" + i.toString()
            let future = spawn {
                cache.add(key, i)
                let value = cache.get(key)
                @Assert(value.isSome(), true)
                @Assert(value.getOrThrow(), i)
            }
            futures.add(future)
        }

        for (future in futures) {
            future.get()
        }

        cache.close()
    }
}
