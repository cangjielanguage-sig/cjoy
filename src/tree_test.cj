/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
public class NodeTestCaseSuit {
    private var tree: Node<Int64> = Node<Int64>("/", STATIC)

    private func addPath(path: String) {
        let node = tree.addPath(path[1..path.size], ArrayList<String>(), false)
        node.setHandler("GET", 1, false)
    }

    private func testPath(path: String, expectPath: String, expectedParams: HashMap<String, String>) {
        let (node, handler, params) = tree.search("GET", path[1..path.size])
        if (expectPath != "" && node.isNone()) {
            @Fail("not match for ${path}, expected ${expectPath}")
            return
        } else if (expectPath == "" && node.isSome()) {
            eprintln("node and subtree was\n ${node.getOrThrow().dumpTree("", "")}")
            @Fail("expected no match for ${path} but got with params ${expectedParams}")
            return
        }

        if (node.isNone()) {
            return
        }

        let h = node.getOrThrow()._leafHandlers.get("GET")
        if (h.isNone()) {
            eprintln("node and subtree was\n ${node.getOrThrow().dumpTree("", "")}")
            @Fail("path ${path} returned node without handler")
            return
        }

        if (handler.isNone()) {
            eprintln("node and subtree was\n ${node.getOrThrow().dumpTree("", "")}")
            @Fail("Path ${path} returned valid node but foundHandler was false")
            return
        }

        if (expectedParams.isEmpty()) {
            if (!params.isEmpty()) {
                eprintln("node and subtree was\n ${node.getOrThrow().dumpTree("", "")}")
                @Fail("Path ${path} expected no parameters, saw ${params}")
            }
        } else {
            if (expectedParams.size != params.size) {
                @Fail("Got ${params.size} params back but node specifies ${expectedParams.size}")
            }

            let xparams = HashMap<String, String>()
            let leafParamNames = node.getOrThrow()._leafParamNames
            for (i in 0..params.size) {
                xparams.put(leafParamNames[params.size - i - 1], params[i])
            }

            for ((k, v) in expectedParams) {
                let e = xparams.get(k)
                if (e.isNone()) {
                    @Fail("Path ${path} matched without key ${k}")
                } else if (e.getOrThrow() != v) {
                    @Fail("Path ${path} expected param ${k} to be ${v}, saw ${e.getOrThrow()}")
                }
                xparams.remove(k)
            }
            for ((k, v) in xparams) {
                @Fail("Path ${path} returned unexpected param ${k}=${v}")
            }
        }
    }

    @TestCase
    public func testTree() {
        addPath("/")
        addPath("/i")
        addPath("/i/:aaa")
        addPath("/images")
        addPath("/images/abc.jpg")
        addPath("/images/:imgname")
        addPath("/images/\\*path")
        addPath("/images/\\*patch")
        addPath("/images/*path")
        addPath("/ima")
        addPath("/ima:par")
        addPath("/images1")
        addPath("/images2")
        addPath("/apples")
        addPath("/app/les")
        addPath("/apples1")
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

        testPath("/users/abc/updatePassword", "/users/:id/updatePassword", HashMap<String, String>([("id", "abc")]))
        testPath("/users/all/something", "/users/:pk/:related",
            HashMap<String, String>([("pk", "all"), ("related", "something")]))

        testPath("/aaa/abc", "/:something/abc", HashMap<String, String>([("something", "aaa")]))
        testPath("/aaa/def", "/:something/def", HashMap<String, String>([("something", "aaa")]))

        testPath("/", "/", HashMap<String, String>())
        testPath("/i", "/i", HashMap<String, String>())

        testPath("/images", "/images", HashMap<String, String>())
        testPath("/images/abc.jpg", "/images/abc.jpg", HashMap<String, String>())
        testPath("/images/something", "/images/:imgname", HashMap<String, String>([("imgname", "something")]))
        testPath("/images/long/path", "/images/*path", HashMap<String, String>([("path", "long/path")]))
        testPath("/images/even/longer/path", "/images/*path", HashMap<String, String>([("path", "even/longer/path")]))

        testPath("/ima", "/ima", HashMap<String, String>())
        testPath("/apples", "/apples", HashMap<String, String>())
        testPath("/app/les", "/app/les", HashMap<String, String>())

        testPath("/paper", "/:page", HashMap<String, String>([("page", "paper")]))
        testPath("/abc", "/:page", HashMap<String, String>([("page", "abc")]))
        testPath("/abc/100", "/:page/:index", HashMap<String, String>([("page", "abc"), ("index", "100")]))

        testPath("/post/a/page/2", "/post/:post/page/:page", HashMap<String, String>([("post", "a"), ("page", "2")]))
        testPath("/date/2014/5", "/date/:year/:month", HashMap<String, String>([("year", "2014"), ("month", "5")]))
        testPath("/date/2014/month", "/date/:year/month", HashMap<String, String>([("year", "2014")]))
        testPath("/date/2014/5/abc", "/date/:year/:month/abc", HashMap<String, String>([("year", "2014"), ("month", "5")]
        ))
        testPath("/date/2014/5/def", "/date/:year/:month/:post",
            HashMap<String, String>([("year", "2014"), ("month", "5"), ("post", "def")]))
        testPath("/date/2014/5/def/hij", "/date/:year/:month/*post",
            HashMap<String, String>([("year", "2014"), ("month", "5"), ("post", "def/hij")]))
        testPath("/date/2014/5/def/hij/", "/date/:year/:month/*post",
            HashMap<String, String>([("year", "2014"), ("month", "5"), ("post", "def/hij/")]))

        testPath("/images/*path", "/images/\\*path", HashMap<String, String>())
        testPath("/images/*patch", "/images/\\*patch", HashMap<String, String>())
        testPath("/date/:year/:month", "/date/\\:year/\\:month", HashMap<String, String>())

        testPath("/apples/ab*cde/lala/baba/dada", "/apples/ab*cde/:fg/*hi",
            HashMap<String, String>([("fg", "lala"), ("hi", "baba/dada")]))
        testPath("/apples/ab\\*cde/lala/baba/dada", "/apples/ab\\*cde/:fg/*hi",
            HashMap<String, String>([("fg", "lala"), ("hi", "baba/dada")]))

        testPath("/apples/ab:cde/:fg/*hi", "/apples/ab:cde/:fg/*hi",
            HashMap<String, String>([("fg", ":fg"), ("hi", "*hi")]))
        testPath("/apples/ab*cde/:fg/*hi", "/apples/ab*cde/:fg/*hi",
            HashMap<String, String>([("fg", ":fg"), ("hi", "*hi")]))
        testPath("/apples/ab*cde/one/two/three", "/apples/ab*cde/:fg/*hi",
            HashMap<String, String>([("fg", "one"), ("hi", "two/three")]))
        testPath("/apples/ab*dde", "/apples/ab*dde", HashMap<String, String>())

        testPath("/ima/bcd/fgh", "", HashMap<String, String>())
        //testPath("/date/2014//month", "", HashMap<String, String>())
        testPath("/date/2014/05/", "", HashMap<String, String>())
        //testPath("/post//abc/page/2", "", HashMap<String, String>())
        //testPath("/post/abc//page/2", "", HashMap<String, String>())
        //testPath("/post/abc/page//2", "", HashMap<String, String>())
        //testPath("//post/abc/page/2", "", HashMap<String, String>())
        //testPath("//post//abc//page//2", "", HashMap<String, String>())
    }
}
