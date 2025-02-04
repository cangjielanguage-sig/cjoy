/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
public class RouteTestCaseSuit {
    @TestCase
    public func testGroup() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig())
        let ga = router.group("/a")
        @Assert(ga.basePath(), "/a")
        let gb = ga.group("/b")
        @Assert(gb.basePath(), "/a/b")
        let gc = gb.group("/c")
        @Assert(gc.basePath(), "/a/b/c")
    }

    @TestCase
    public func findGroupRoot() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig())
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "")
    }

    @TestCase
    public func findGroupLvl1() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig())
        router.group("/a")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a")
    }

    @TestCase
    public func findGroupLvl3() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig())
        router.group("/a")
        router.group("/a").group("/b").group("/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c")
    }

    @TestCase
    public func findGroupLvl3Indirect() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig())
        router.group("/a/b/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c")
    }

    @TestCase
    public func findGroupLvl1Match() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig())
        router.group("/a")
        router.group("/a").group("/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a")
    }

    @TestCase
    public func findGroupPathAllMatch() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig())
        router.group("/a")
        router.group("/a").group("/b").group("/c").group("/d")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c/d")
    }

    @TestCase
    public func findCreateGroups() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig())
        router.createGroups("/a/b/c/d")
        var r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c/d")
        r = router.findGroup("/a/b/c")
        @Assert(r.basePath(), "/a/b/c")
        r = router.findGroup("/a/b")
        @Assert(r.basePath(), "/a/b")
        r = router.findGroup("/a")
        @Assert(r.basePath(), "/a")
    }
}
