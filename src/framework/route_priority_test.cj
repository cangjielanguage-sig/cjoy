package cjoy.framework

import std.unittest.testmacro.*
import stdx.net.http.*
import std.io.readToEnd
import std.io.BufferedInputStream
import std.io.StringReader
import std.io.InputStream

@Test
public class RoutePriorityTestCaseSuit {
    var _instance: ?Joy = None
    var _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.create(name: "testRoutePriorityEngine")
            let router = joy.router

            // 添加不同类型的路由，测试优先级
            router.get("/static", { ctx =>
                ctx.string("static")
            })

            router.get("/param/{id}", { ctx =>
                ctx.string("param: ${ctx.getParam("id").getOrThrow()}")
            })

            router.get("/regex/{id:[0-9]+}", { ctx =>
                ctx.string("regex: ${ctx.getParam("id").getOrThrow()}")
            })

            router.get("/catchAll/*", { ctx =>
                ctx.string("catchAll: ${ctx.getParam("*").getOrThrow()}")
            })

            // 测试静态路由之间的优先级
            router.get("/user", { ctx =>
                ctx.string("user")
            })

            router.get("/user/profile", { ctx =>
                ctx.string("user/profile")
            })

            _instance = joy
            joy.run("127.0.0.1", 18884)
        }
        // 等待服务器启动
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _instance?.shutdown()
        _client.close()
    }

    @AfterEach
    func tearDownEach() {
        _client.close()
        _client = ClientBuilder().build()
    }

    // 辅助函数：将 InputStream 转换为字符串
    private func streamToString(stream: InputStream): String {
        let reader = StringReader(BufferedInputStream(stream))
        reader.readToEnd()
    }

    @TestCase
    public func testStaticRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/static")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "static")
    }

    @TestCase
    public func testParamRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/param/123")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "param: 123")
    }

    @TestCase
    public func testRegexRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/regex/123")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "regex: 123")
    }

    @TestCase
    public func testCatchAllRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/catchAll/test")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "catchAll: test")
    }

    @TestCase
    public func testStaticVsParamRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/static")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "static") // 应该匹配静态路由，而不是参数路由
    }

    @TestCase
    public func testParamVsRegexRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/param/123")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "param: 123") // 应该匹配参数路由，而不是正则路由
    }

    @TestCase
    public func testRegexVsCatchAllRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/regex/123")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "regex: 123") // 应该匹配正则路由，而不是通配符路由
    }

    @TestCase
    public func testLongerStaticRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/user/profile")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "user/profile") // 应该匹配更长的静态路由
    }
}
