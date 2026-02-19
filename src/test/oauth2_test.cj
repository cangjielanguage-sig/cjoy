/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import std.collection.*
import std.unittest.mock.*
import stdx.encoding.url.Form
import cjoy.framework.*
import cjoy.httpx.*
import cjoy.oauth2.*

@Test
public class OAuth2ServerTestCaseSuit {
    let _clientId: String = "abcdef"
    let _clientSecret: String = "12345678"
    let _plainChallenge = "ThisIsAFourtyThreeCharactersLongStringThing"
    let _s256Challenge = "s256tests256tests256tests256tests256tests256test"
    let _s256ChallengeHash = "To2Xqv01cm16bC9Sf7KRRS8CO2SFss_HSMQOr3sdCDE="

    let _manager: OAuth2Manager
    let _server: OAuth2Server
    let _clientStore: ClientStore

    var _serverJoy: ?Joy = None
    var _clientJoy: ?Joy = None
    let _client = JoyHttpClientService("http://127.0.0.1:18881/")

    public init() {
        _clientStore = MemoryClientStore()
        _manager = DefaultOAuth2Manager(clientStore: _clientStore)
        _server = OAuth2Server(_manager)
    }

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.get("/authorize", _server.authorizeRequestHandleFunc)
            router.post("/authorize", _server.authorizeRequestHandleFunc)
            router.get("/token", _server.tokenRequestHandleFunc)
            router.post("/token", _server.tokenRequestHandleFunc)
            _serverJoy = joy
            joy.run("127.0.0.1", 18881)
        }

        spawn {
            let joy = Joy.create(name: "client")
            let router = joy.router
            router.post("/oauth2", {ctx: JoyContext =>})
            router.get("/oauth2", {ctx: JoyContext =>})

            let handler1 = {
                ctx: JoyContext =>
                let code = ctx.getForm("code").getOrThrow()
                let state = ctx.getForm("state").getOrThrow()
                if (state != "123") {
                    @Fail("unrecognized state: ${state}")
                    return
                }

                let c = BasicAuthClient(_client, username: _clientId, password: _clientSecret)
                let form = Form()
                form.add("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_1")
                form.add("code", code)
                form.add("grant_type", "authorization_code")
                form.add("client_id", _clientId)
                let rsp = c.postform(ctx, "/token", form)
                let token = rsp.json<TokenBody>().getOrThrow()
                validateAccessToken(ctx, token.accessToken)
            }
            router.post("/oauth2_cb_1", handler1)
            router.get("/oauth2_cb_1", handler1)

            let handler2 = {
                ctx: JoyContext =>
                let code = ctx.getForm("code").getOrThrow()
                let state = ctx.getForm("state").getOrThrow()
                if (state != "123") {
                    @Fail("unrecognized state: ${state}")
                    return
                }

                let form = Form()
                form.add("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_2")
                form.add("code", code)
                form.add("grant_type", "authorization_code")
                form.add("client_id", _clientId)
                form.add("code_verifier", _plainChallenge)
                let rsp = _client.postform(ctx, "/token", form)
                let token = rsp.json<TokenBody>().getOrThrow()
                validateAccessToken(ctx, token.accessToken)
            }
            router.post("/oauth2_cb_2", handler2)
            router.get("/oauth2_cb_2", handler2)

            let handler3 = {
                ctx: JoyContext =>
                let code = ctx.getForm("code").getOrThrow()
                let state = ctx.getForm("state").getOrThrow()
                if (state != "123") {
                    @Fail("unrecognized state: ${state}")
                    return
                }

                let form = Form()
                form.add("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_3")
                form.add("code", code)
                form.add("grant_type", "authorization_code")
                form.add("client_id", _clientId)
                form.add("code_verifier", _s256Challenge)
                let rsp = _client.postform(ctx, "/token", form)
                let token = rsp.json<TokenBody>().getOrThrow()
                validateAccessToken(ctx, token.accessToken)
            }
            router.post("/oauth2_cb_3", handler3)
            router.get("/oauth2_cb_3", handler3)

            let handler4 = {
                ctx: JoyContext =>
                let code = ctx.getForm("code").getOrThrow()
                let state = ctx.getForm("state").getOrThrow()
                if (state != "123") {
                    @Fail("unrecognized state: ${state}")
                    return
                }

                let c = BasicAuthClient(_client, username: _clientId, password: _clientSecret)
                var form = Form()
                form.add("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_4")
                form.add("code", code)
                form.add("grant_type", "authorization_code")
                form.add("client_id", _clientId)
                var rsp = c.postform(ctx, "/token", form)
                var token = rsp.json<TokenBody>().getOrThrow()
                validateAccessToken(ctx, token.accessToken)

                // refresh_token
                form = Form()
                form.add("scope", "one")
                form.add("grant_type", "refresh_token")
                form.add("refresh_token", token.refreshToken)
                rsp = c.postform(ctx, "/token", form)
                token = rsp.json<TokenBody>().getOrThrow()
                validateAccessToken(ctx, token.accessToken)
            }
            router.post("/oauth2_cb_4", handler4)
            router.get("/oauth2_cb_4", handler4)

            _clientJoy = joy
            joy.run("127.0.0.1", 31888)
        }
        sleep(Duration.second * 3)
    }

    @AfterAll
    func tearDown() {
        _client.destroy()
        _serverJoy?.shutdown()
        _clientJoy?.shutdown()
    }

    /**
     * 测试授权码流程 - 验证 OAuth 2.0 的授权码授权流程
     */
    @TestCase
    public func testAuthorizeCode() {
        _server.setUserAuthorizationHandleFunc({
            ctx: JoyContext => _clientId
        })
        _server.setClientInfoHandleFunc(clientBasicHandleFunc)
        let cli = ClientInfo(id: _clientId, secret: _clientSecret, domain: "http://127.0.0.1:31888", isPublic: true)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "code"),
                            ("client_id", _clientId),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_1")
                        ]
                    )
                )
        )
        @Assert(rsp.status, 200)
    }

    /**
     * 测试授权码流程与 plain 挑战 - 验证带有 plain 挑战的授权码流程
     */
    @TestCase
    public func testAuthorizeCodeWithChallengePlain() {
        _server.setUserAuthorizationHandleFunc({
            ctx: JoyContext => _clientId
        })
        _server.setClientInfoHandleFunc(clientFormHandleFunc)

        let cli = ClientInfo(id: _clientId, secret: "", domain: "http://127.0.0.1:31888", isPublic: true)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "code"),
                            ("client_id", _clientId),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_2"),
                            ("code_challenge", _plainChallenge)
                        ]
                    )
                )
        )
        @Assert(rsp.status, 200)
    }

    /**
     * 测试授权码流程与 S256 挑战 - 验证带有 S256 挑战的授权码流程
     */
    @TestCase
    public func testAuthorizeCodeWithChallengeS256() {
        _server.setUserAuthorizationHandleFunc({
            ctx: JoyContext => _clientId
        })
        _server.setClientInfoHandleFunc(clientFormHandleFunc)

        let cli = ClientInfo(id: _clientId, secret: "", domain: "http://127.0.0.1:31888", isPublic: true)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "code"),
                            ("client_id", _clientId),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_3"),
                            ("code_challenge", _s256ChallengeHash),
                            ("code_challenge_method", "S256")
                        ]
                    )
                )
        )
        @Assert(rsp.status, 200)
    }

    private func validateAccessToken(ctx: JoyContext, accessToken: String): Unit {
        _manager.loadAccessToken(accessToken)
    }

    /**
     * 测试隐式授权流程 - 验证 OAuth 2.0 的隐式授权流程
     */
    @TestCase
    public func testImplicit() {
        _server.setUserAuthorizationHandleFunc({
            ctx: JoyContext => _clientId
        })
        _server.setClientInfoHandleFunc(clientFormHandleFunc)

        let cli = ClientInfo(id: _clientId, secret: "", domain: "http://127.0.0.1:31888", isPublic: false)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "token"),
                            ("client_id", _clientId),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2")
                        ]
                    )
                )
        )
        @Assert(rsp.status, 200)
    }

    /**
     * 测试密码凭证流程 - 验证 OAuth 2.0 的密码凭证授权流程
     */
    @TestCase
    public func testPasswordCredentials() {
        _server.setClientInfoHandleFunc(clientBasicHandleFunc)
        _server.setPasswordAuthorizationHandleFunc(
            {
                ctx: JoyContext, clientId: String, username: String, password: String => if (username == "admin" &&
                    password == "123456") {
                    _clientId
                } else {
                    "user not found"
                }
            })

        let cli = ClientInfo(id: _clientId, secret: _clientSecret, domain: "http://127.0.0.1:31888", isPublic: false)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let c = BasicAuthClient(_client, username: _clientId, password: _clientSecret)
        let form = Form()
        form.add("grant_type", "password")
        form.add("username", "admin")
        form.add("password", "123456")
        form.add("scope", "all")
        let rsp = c.postform(ctx, "/token", form)
        @Assert(rsp.status, 200)
        let token = rsp.json<TokenBody>().getOrThrow()
        validateAccessToken(ctx, token.accessToken)
    }

    /**
     * 测试客户端凭证流程 - 验证 OAuth 2.0 的客户端凭证授权流程
     */
    @TestCase
    public func TestClientCredentials() {
        _server.setClientInfoHandleFunc(clientFormHandleFunc)
        _server.setAllowGetAccessRequest(true)
        _server.setAuthorizeScopeHandleFunc({
            ctx: JoyContext => ""
        })
        _server.setClientScopeHandleFunc({
            request: TokenGenerateRequest => true
        })

        let cli = ClientInfo(id: _clientId, secret: _clientSecret, domain: "http://127.0.0.1:31888", isPublic: false)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let form = Form()
        form.add("grant_type", "client_credentials")
        form.add("client_id", _clientId)
        form.add("client_secret", _clientSecret)
        form.add("scope", "all")
        let rsp = _client.postform(ctx, "/token", form)
        @Assert(rsp.status, 200)
        let token = rsp.json<TokenBody>().getOrThrow()
        validateAccessToken(ctx, token.accessToken)
    }

    /**
     * 测试刷新令牌流程 - 验证 OAuth 2.0 的刷新令牌流程
     */
    @TestCase
    public func testRefreshing() {
        _server.setUserAuthorizationHandleFunc({
            ctx: JoyContext => _clientId
        })
        _server.setClientInfoHandleFunc(clientBasicHandleFunc)
        let cli = ClientInfo(id: _clientId, secret: _clientSecret, domain: "http://127.0.0.1:31888", isPublic: true)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "code"),
                            ("client_id", _clientId),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_4")
                        ]
                    )
                )
        )
        @Assert(rsp.status, 200)
    }

    /**
     * 测试无效的请求方法 - 验证服务器对无效HTTP方法的响应
     */
    @TestCase
    public func testInvalidRequestMethod() {
        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .put()  // 使用无效的PUT方法
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "code"),
                            ("client_id", _clientId),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_1")
                        ]
                    )
                )
        )
        @Assert(rsp.status, 404)  // 预期返回404错误
    }

    /**
     * 测试缺少必要参数的请求 - 验证服务器对缺少client_id参数的响应
     */
    @TestCase
    public func testMissingClientId() {
        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "code"),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_1")
                        ]
                    )
                )
        )
        @Assert(rsp.status, 400)  // 预期返回400错误
    }

    /**
     * 测试无效的响应类型 - 验证服务器对不支持的响应类型的响应
     */
    @TestCase
    public func testInvalidResponseType() {
        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "invalid"),  // 无效的响应类型
                            ("client_id", _clientId),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_1")
                        ]
                    )
                )
        )
        @Assert(rsp.status, 401)  // 预期返回401错误
    }

    /**
     * 测试无效的客户端ID - 验证服务器对不存在的客户端ID的响应
     */
    @TestCase
    public func testInvalidClientId() {
        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "code"),
                            ("client_id", "invalid-client-id"),  // 不存在的客户端ID
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://127.0.0.1:31888/oauth2_cb_1")
                        ]
                    )
                )
        )
        @Assert(rsp.status, 401)  // 预期返回401错误
    }

    /**
     * 测试无效的重定向URI - 验证服务器对不匹配域名的重定向URI的响应
     */
    @TestCase
    @Skip
    public func testInvalidRedirectUri() {
        _server.setUserAuthorizationHandleFunc({
            ctx: JoyContext => _clientId
        })
        let cli = ClientInfo(id: _clientId, secret: _clientSecret, domain: "http://127.0.0.1:31888", isPublic: true)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let rsp = _client.send(
            ctx,
            JoyHttpRequest
                .of("/authorize")
                .get()
                .queries(
                    HashMap<String, ToString>(
                        [
                            ("response_type", "code"),
                            ("client_id", _clientId),
                            ("scope", "all"),
                            ("state", "123"),
                            ("redirect_uri", "http://invalid-domain.com/oauth2_cb_1")  // 不匹配的域名
                        ]
                    )
                )
        )
        @Assert(rsp.status, 400)  // 预期返回400错误
    }

    /**
     * 测试密码授权失败 - 验证服务器对无效用户名密码的响应
     */
    @TestCase
    @Skip
    public func testPasswordGrantFailure() {
        _server.setClientInfoHandleFunc(clientBasicHandleFunc)
        _server.setPasswordAuthorizationHandleFunc(
            {
                ctx: JoyContext, clientId: String, username: String, password: String => if (username == "admin" &&
                    password == "123456") {
                    _clientId
                } else {
                    "user not found"
                }
            })

        let cli = ClientInfo(id: _clientId, secret: _clientSecret, domain: "http://127.0.0.1:31888", isPublic: false)
        _clientStore.add(cli)

        let ctx = mock<JoyContext>()
        let c = BasicAuthClient(_client, username: _clientId, password: _clientSecret)
        let form = Form()
        form.add("grant_type", "password")
        form.add("username", "invaliduser")  // 无效的用户名
        form.add("password", "invalidpassword")  // 无效的密码
        form.add("scope", "all")
        let rsp = c.postform(ctx, "/token", form)
        @Assert(rsp.status, 401)  // 预期返回401错误
    }
}
