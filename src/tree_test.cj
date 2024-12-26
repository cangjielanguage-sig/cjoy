/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */
 
package cjoy

import std.collection.ArrayList
import std.unittest.*
import std.unittest.testmacro.*

@Test
public class NodeTestCaseSuit {
    private var tree: Node<Int64>  = Node<Int64>("/", STATIC)

    private func addPath(path: String) {
        let node = tree.addPath(path[1..path.size], ArrayList<String>(), false)
        node.setHandler("GET", 1, false)
    }

    @TestCase
    public func testTree() {
        addPath("/")
        addPath("/i")
        addPath("/i/:aaa")
        addPath("/i/images")
        addPath("/i/images/abc.jpg")
        addPath("/i/images/:imgname")
        addPath("/i/images/\\*path")
        addPath("/i/images/\\*patch")
        addPath("/i/images/*path")
        addPath("/i/ima")
        addPath("/i/ima:par")
        addPath("/i/images1")
        addPath("/i/images2")
        addPath("/i/apples")
        addPath("/i/app/les")
        addPath("/i/apples1")
        addPath("/appeasement")
        addPath("/appealing")
        addPath("/date/\\:year/\\:month")
        addPath("/date/:year/:month")
        addPath("/date/:year/month")
        addPath("/date/:year/:month/abc")
        addPath("/date/:year/:month/:post")
        addPath("/date/:year/:month/*post")
        addPath("/:page")
        addPath("/:page/:index")
        addPath("/post/:post/page/:page")
        addPath("/plaster")
        addPath("/users/:pk/:related")
        addPath("/users/:id/updatePassword")
        addPath("/:something/abc")
        addPath("/:something/def")
        addPath("/apples/ab:cde/:fg/*hi")
        addPath("/apples/ab*cde/:fg/*hi")
        addPath("/apples/ab\\*cde/:fg/*hi")
        addPath("/apples/ab*dde")
    }
}