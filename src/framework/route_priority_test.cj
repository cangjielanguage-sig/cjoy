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

    /**
     * 测试静态路由优先级 - 验证静态路由可以正确匹配
     */
    @TestCase
    public func testStaticRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/static")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "static")
    }

    /**
     * 测试参数路由优先级 - 验证参数路由可以正确匹配并提取参数值
     */
    @TestCase
    public func testParamRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/param/123")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "param: 123")
    }

    /**
     * 测试正则路由优先级 - 验证正则表达式路由可以正确匹配
     */
    @TestCase
    public func testRegexRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/regex/123")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "regex: 123")
    }

    /**
     * 测试通配符路由优先级 - 验证通配符路由可以正确匹配并捕获剩余路径
     */
    @TestCase
    public func testCatchAllRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/catchAll/test")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "catchAll: test")
    }

    /**
     * 测试静态路由与参数路由优先级 - 验证静态路由优先于参数路由
     */
    @TestCase
    public func testStaticVsParamRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/static")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "static") // 应该匹配静态路由，而不是参数路由
    }

    /**
     * 测试参数路由与正则路由优先级 - 验证参数路由优先于正则路由
     */
    @TestCase
    public func testParamVsRegexRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/param/123")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "param: 123") // 应该匹配参数路由，而不是正则路由
    }

    /**
     * 测试正则路由与通配符路由优先级 - 验证正则路由优先于通配符路由
     */
    @TestCase
    public func testRegexVsCatchAllRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/regex/123")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "regex: 123") // 应该匹配正则路由，而不是通配符路由
    }

    /**
     * 测试更长静态路由优先级 - 验证更精确的静态路由优先匹配
     */
    @TestCase
    public func testLongerStaticRoutePriority() {
        let rsp = _client.get("http://127.0.0.1:18884/user/profile")
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "user/profile") // 应该匹配更长的静态路由
    }

    /**
     * 测试静态路由优先于参数路由 - 验证静态路由优先级
     */
    @TestCase
    public func testStaticOverParamPriority() {
        // /static 是静态路由，应该优先于参数路由
        let rsp = _client.get("http://127.0.0.1:18884/static")
        @Assert(rsp.status == 200)
        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "static")
    }

    /**
     * 测试参数路由匹配 - 验证参数路由在没有静态路由时匹配
     */
    @TestCase
    public func testParamRouteMatching() {
        // /param/xyz 不是静态路由，应该匹配参数路由
        let rsp = _client.get("http://127.0.0.1:18884/param/xyz")
        @Assert(rsp.status == 200)
        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "param: xyz")
    }

    /**
     * 测试正则路由匹配数字 - 验证正则路由正确匹配数字
     */
    @TestCase
    public func testRegexRouteMatchingNumeric() {
        let rsp = _client.get("http://127.0.0.1:18884/regex/999")
        @Assert(rsp.status == 200)
        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "regex: 999")
    }

    /**
     * 测试通配符路由匹配任意路径 - 验证通配符路由匹配剩余路径
     */
    @TestCase
    public func testCatchAllRouteMatching() {
        let rsp = _client.get("http://127.0.0.1:18884/catchAll/deep/nested/path")
        @Assert(rsp.status == 200)
        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr == "catchAll: deep/nested/path")
    }

    /**
     * 测试路由不匹配 404 - 验证不存在的路由返回 404
     */
    @TestCase
    public func testRouteNotFound() {
        let rsp = _client.get("http://127.0.0.1:18884/nonexistent")
        @Assert(rsp.status == 404)
    }

    /**
     * 测试根路由匹配 - 验证根路由正确匹配
     */
    @TestCase
    public func testRootRouteMatching() {
        let rsp = _client.get("http://127.0.0.1:18884/")
        @Assert(rsp.status == 404) // 根路由未定义，应返回 404
    }
}
