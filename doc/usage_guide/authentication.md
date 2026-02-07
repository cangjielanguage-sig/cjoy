# 认证

认证是Web应用的关键环节，通过用户角色或权限控制资源访问。其本质是验证用户身份以授予受保护资源的访问权限，确保仅经认证的用户可执行操作或访问应用数据。

CJoy提供了多种实现认证机制。

---

## 概述

CJoy认证系统基于以下核心概念设计：

- **Basic认证**：简单的HTTP认证方案，用户凭据以Base64编码格式通过请求头传输
- **Token认证**：API Token验证，适用于机机接口，Token可从Header、Cookie、Query、Form或Path等位置获取
- **JWT认证**：JSON Web Token认证，支持HS256/HS384/HS512和RS256/RS384/RS512算法
- **OAuth2认证**：授权框架，允许用户通过授权服务器授予第三方应用程序访问权限

使用示例：
- Basic认证：[test/basic_auth_test](../../src/test/basic_auth_test.cj)
- Token认证：[examples/tokenauth](../../examples/src/tokenauth/main.cj)
- JWT认证：[examples/jwtauth](../../examples/src/jwtauth/main.cj)
- OAuth2认证：[test/oauth2_test](../../src/test/oauth2_test.cj)

---

## 一、Basic认证

基本认证是一种简单的HTTP认证方案，用户凭据（用户名和密码）以Base64编码格式通过请求头传输。

基本认证是验证API最简单的方式。它基于HTTP协议的认证机制，在标准的Authorization头中发送以"Basic "为前缀的Base64Encode(<用户名>:<密码>)。

### 1.1 预定义认证凭证

使用 HashMap 存储用户名和密码的映射关系：

```cangjie
let joy = Joy.default()

// 创建BasicAuth中间件对象，指定认证凭证
let basicAuth = BasicAuth(
    realm: "test",
    creds: HashMap<String, String>([("xiao", "xiao"), ("lanling", "lanling")])
)
joy.router.use(basicAuth)
```

### 1.2 自定义校验函数

实现 `BasicAuthValidationFunc` 函数，创建 BasicAuth 中间件对象时，指定 `validateFunc`，此函数将用户名和密码作为参数，如果有效则返回 true，否则返回 false。

```cangjie
let joy = Joy.default()

// 创建BasicAuth中间件对象，指定认证校验函数
let basicAuth = BasicAuth(
    realm: "test",
    creds: HashMap<String, String>(),
    validateFunc: {
        ctx: JoyContext, username: String, password: String =>
            username == "xiao" && password == "abcdef"
    }
)

joy.router.use(basicAuth)
```

### 1.3 过滤函数

使用 `filterFunc` 指定哪些请求不需要认证：

```cangjie
let basicAuth = BasicAuth(
    realm: "test",
    creds: HashMap<String, String>([("admin", "password")]),
    filterFunc: {
        ctx: JoyContext =>
            // 公开路径不需要认证
            ctx.path == "/public" || ctx.path == "/health"
    }
)
```

### 1.4 参数参数说明

BasicAuth 提供如下参数：

| 参数 | 类型 | 是否可选 | 说明 |
|------|------|----------|------|
| realm | String | 否 | 用于设置所属领域名称，显示在认证对话框中 |
| creds | HashMap<String, String> | 否 | 认证凭证，用户名到密码的映射 |
| validateFunc | BasicAuthValidationFunc | 是 | 用于指定校验函数，设置后将忽略 creds |
| filterFunc | BasicAuthFilterFunc | 是 | 用于指定过滤不需要认证的请求 |

#### BasicAuthValidationFunc

函数签名：`(ctx: JoyContext, username: String, password: String) -> Bool`

用于自定义用户名和密码的验证逻辑。返回 `true` 表示验证通过，`false` 表示验证失败。

#### BasicAuthFilterFunc

函数签名：`(ctx: JoyContext) -> Bool`

用于判断当前请求是否需要认证。返回 `true` 表示跳过认证（允许访问），返回 `false` 表示需要认证。

### 1.5 认证失败响应

当认证失败时，中间件会返回 401 Unauthorized 状态码，并添加以下响应头：

```
WWW-Authenticate: Basic realm=<realm>
```

---

## 二、Token认证

API Token验证通常用于机机接口，服务给某个应用颁发一次性Token。应用获取Token之后，在HTTP请求的Header、Cookie、Query、Form或Path等指定位置携带Token，服务端对此Token进行校验。

### 2.1 预定义认证凭证

使用预定义的 Token 列表进行验证：

```cangjie
let joy = Joy.default().router
// 指定预定义的Token列表
let tokenAuth = TokenAuth(["abc", "def", "ghi"])
joy.use(tokenAuth)
```

### 2.2 自定义校验函数

实现 `TokenAuthValidatorFunc` 函数，创建 TokenAuth 中间件对象时，指定 `validator`，此函数将 token 作为参数，如果有效则返回 true，否则返回 false。

```cangjie
let joy = Joy.default().router

// 创建TokenAuth中间件对象，指定认证校验函数
let tokenAuth = TokenAuth({
    ctx: JoyContext, token: String => token == "abcd"
})

joy.use(tokenAuth)
```

### 2.3 从不同位置获取 Token

通过 `lookupKey` 参数指定 Token 的获取位置：

```cangjie
// 从 Query 参数获取
let tokenAuth = TokenAuth(
    validator: {ctx, token => token == "secret"},
    lookupKey: "query:token"
)

// 从 Cookie 获取
let tokenAuth = TokenAuth(
    validator: {ctx, token => token == "secret"},
    lookupKey: "cookie:auth_token"
)

// 从 POST Form 获取
let tokenAuth = TokenAuth(
    validator: {ctx, token => token == "secret"},
    lookupKey: "form:token"
)

// 从 URL 参数获取
let tokenAuth = TokenAuth(
    validator: {ctx, token => token == "secret"},
    lookupKey: "param:token"
)
```

### 2.4 自定义认证 Schema

当使用 Header 获取 Token 时，可以自定义认证 Schema：

```cangjie
// 使用 "Token" 替代默认的 "Bearer"
let tokenAuth = TokenAuth(
    validator: {ctx, token => token == "secret"},
    lookupKey: "header:Authorization",
    authSchema: "Token"
)

// 请求头格式：Authorization: Token secret
```

### 2.5 成功和失败回调

```cangjie
let tokenAuth = TokenAuth(
    validator: {ctx, token => token == "secret"},
    successHandleFunc: {
        ctx: JoyContext =>
            // 认证成功后的处理逻辑
            @JoyLogInfo("Token认证成功: ${ctx.getClientIP()}")
    },
    errorHandleFunc: {
        ctx: JoyContext =>
            // 认证失败后的处理逻辑
            ctx.status(HttpStatusCode.STATUS_UNAUTHORIZED)
                .json(@ToJson({"code": 401, "message": "无效的Token"}))
    }
)
```

### 2.6 参数参数说明

TokenAuth 提供如下参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| validator | TokenAuthValidatorFunc | - | 用于指定校验函数 |
| tokens | Array<String> | - | 预定义的 Token 列表（与 validator 二选一） |
| lookupKey | String | "header:Authorization" | 用于设置 token 的获取源，格式为 <source>:<name> |
| authSchema | String | "Bearer" | 用于设置从 header 中获取 token 时的 Schema |
| successHandleFunc | JoyRequestHandlerFunc | None | 用于指定认证成功之后扩展逻辑函数 |
| errorHandleFunc | JoyRequestHandlerFunc | 默认返回 401 | 用于指定认证失败之后扩展逻辑函数 |
| filterHandleFunc | JoyRequestFilterFunc | None | 用于指定过滤不需要认证的请求 |

#### lookupKey

格式为 `<source>:<name>`，source 支持以下值：

| source | 说明 |
|---------|------|
| header | 从 HTTP 请求头获取 |
| query | 从 URL 查询参数获取 |
| form | 从 POST 表单获取 |
| param | 从 URL 路径参数获取 |
| cookie | 从 Cookie 获取 |

#### TokenAuthValidatorFunc

函数签名：`(ctx: JoyContext, token: String) -> Bool`

用于验证 Token 是否有效。返回 `true` 表示验证通过，`false` 表示验证失败。

---

## 三、JWT认证

JWT（JSON Web Token）是一种用于在网络应用中传输信息的开放标准（RFC 7519），通常用于用户身份验证和授权。它由三部分组成：头部（Header）、载荷（Payload）和签名（Signature）。

### 3.1 签名算法

CJoy内置了JWT的实现，支持如下签名算法：

- HS256, HS384, HS512（HMAC 算法）
- RS256, RS384, RS512（RSA 算法）

注：CJoy不支持None算法，因为无签名JWT可能在传输过程中被篡改。

### 3.2 密钥提供者

CJoy提供了两种密钥提供者接口：

**HmacSigningkey** - 用于 HMAC 算法（HS256/HS384/HS512）：

```cangjie
let keyProvider = HmacSigningkey("secret-key".toArray())
```

**RsaSigningkey** - 用于 RSA 算法（RS256/RS384/RS512）：

```cangjie
let privateKey = loadRSAPrivateKey("./testdata/rsa_private.pem")
let publicKey = loadRSAPublicKey("./testdata/rsa_public.pem")
let keyProvider = RsaSigningkey(privateKey, publicKey)
```

### 3.3 生成Token

HS256 示例：

```cangjie
let jwt = Jwt.create()
// 指定算法
jwt.alg("HS256")
// 设置扩展的头域
jwt.headers.header("h1", "v1")
jwt.claims
    .issuer("cjoy")
    .audience("aud")
    .issuedAt(DateTime.now())
    .expirationTime(DateTime.now().addDays(1))
    .notBefore(DateTime.now())
    .subject("sub")
    .claim("c1", "v1")

let key = "abcd".toArray()
// 签名，生成Token
let token = jwt.signWith(key)
```

RS256 示例：

```cangjie
let jwt = Jwt.create()
// 指定算法
jwt.alg("RS256")
// 设置扩展的头域
jwt.headers.header("h1", "v1")
jwt.claims
    .issuer("cjoy")
    .audience("aud")
    .issuedAt(DateTime.now())
    .expirationTime(DateTime.now().addDays(1))
    .notBefore(DateTime.now())
    .subject("sub")
    .claim("c1", "v1")
// 加载RSAPrivateKey
let priv = loadRSAPrivateKey("./testdata/rsa_private.pem")
// 签名，生成Token
let token = jwt.signWith(priv)
```

### 3.4 解析Token

HS256 示例：

```cangjie
let key = "abcd".toArray()
let jwt = Jwt.parse(token).verifyWith(key)

// parse函数还可以指定ParserConfig参数，用于检查指定的信息
let jwt2 = Jwt.parse(
    token,
    config: ParserConfig(
        expectedAud: ["aud"],
        expirationRequired: true,
        issueAtRequired: true
    )
).verifyWith(key)
```

RS256 示例：

```cangjie
let pub = loadRSAPublicKey("./testdata/rsa_public.pem")
let jwt = Jwt.parse(token).verifyWith(pub)
```

### 3.5 JWT中间件

#### 设置中间件

```cangjie
let jwtAuth = JwtAuth(
    realm: "test jwt",
    signingAlg: "HS256",
    keyProvider: HmacSigningkey("abcd".toArray()),
    authenticator: authenticator,
    authorizator: authorizator,
    setPayload: setJwtPayload,
    maxRefresh: Duration.hour,
    identityKey: "identity",
    sendCookie: true,
    cookieSecure: false,
    cookieHttpOnly: true,
    cookieDomain: ".test.com",
    cookieName: "jwt-cookie",
    sendAuthorization: true
)

// 注册登录接口
joy.router.post("/login", jwtAuth.loginHandler)

// 注册需要JWT认证的路由组
let auth = joy.router.group("/auth")
auth.use(jwtAuth)
auth.get("/refresh_token", jwtAuth.refreshTokenHandler)
auth.post("/logout", jwtAuth.logoutHandler)
```

#### 内置处理器

JWT中间件提供三个内置处理器：

| 处理器 | 说明 |
|--------|------|
| loginHandler | 用户登录，验证凭据后生成并返回 Token |
| refreshTokenHandler | 刷新 Token，延长有效期 |
| logoutHandler | 用户登出，清除 Token |

#### 获取JWT信息

在认证通过的路由中，使用 `getJwt` 函数获取 JWT Token：

```cangjie
import cjoy.middleware.getJwt

@Get[path = "/auth/biz", produce = "json"]
func someBizHandle(ctx: JoyContext): JsonSerializable {
    // 调用getJwt 获取JWT
    if (let Some(token) <- getJwt(ctx)) {
        @JoyLogInfo("JWT Token: ${token}")
    }

    // 从上下文获取身份信息（默认 key 为 "identity"）
    if (let Some(identity) <- ctx.getCtxParam<String>("identity")) {
        @JoyLogInfo("User: ${identity}")
    }

    @ToJson({"data": "success"})
}
```

#### 参数参数说明

JwtAuth 提供如下参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| realm | String | - | 用于设置所属领域名称 |
| signingAlg | String | - | 用于设置签名算法：HS256、HS384、HS512、RS256、RS384、RS512 |
| keyProvider | Jwtkey | - | 用于设置签名密钥，提供 HmacSigningkey 与 RsaSigningkey |
| authenticator | JoyRequestHandlerFunc | - | 用于设置登录时认证用户信息的函数 |
| authorizator | (ctx, identity) -> Bool | 允许所有 | 用于设置授权已认证的用户路由访问权限的函数 |
| setPayload | (ctx, jwt) -> Unit | 空 | 用于设置登陆成功后向 token 中添加自定义负载信息的函数 |
| unauthorized | (ctx, code, message) -> Unit | 返回JSON | 用于设置 jwt 验证流程失败的响应函数 |
| loginResponse | (ctx, code, token, expire) -> Unit | 返回JSON | 用于设置登录的响应函数 |
| logoutResponse | (ctx, code) -> Unit | 返回JSON | 用于设置登出的响应函数 |
| refreshResponse | (ctx, code, token, expire) -> Unit | 同loginResponse | 用于设置 token 有效时长刷新后的响应函数 |
| timeout | Duration | 30分钟 | 用于设置 token 过期时间 |
| maxRefresh | Duration | 0（不可刷新） | 用于设置最大 token 刷新时间，允许客户端在 TokenTime + MaxRefresh 内刷新 token |
| identityKey | String | "identity" | 用于设置检索身份的键 |
| identityHandler | (ctx) -> String | 自动获取 | 用于设置获取身份信息的函数，默认与 IdentityKey 配合使用 |
| tokenLookup | String | "header:Authorization" | 用于设置 token 的获取源，格式为 <source>:<name> |
| tokenHeadName | String | "Bearer" | 用于设置从 header 中获取 token 时的前缀 |
| sendCookie | Bool | false | 用于设置 token 将同时以 cookie 的形式返回 |
| cookieMaxAge | Duration | timeout值 | 用于设置 cookie 的有效期 |
| cookieSecure | Bool | false | 用于设置 cookie 仅通过 HTTPS 传输 |
| cookieHttpOnly | Bool | true | 用于设置 cookie 是否仅通过 HTTP 访问 |
| cookieDomain | String | "" | 用于设置 cookie 所属的域 |
| cookieName | String | "jwt" | 用于设置 cookie 的 name 值 |
| sendAuthorization | Bool | false | 用于设置为所有请求的响应头添加授权的 token 信息 |
| jwtParserConfig | ParserConfig | None | 用于设置JWT解析配置 |

#### authenticator

配合 `JwtAuth.loginHandler` 使用，登录时触发，用于认证用户的登录信息。

示例：

```cangjie
// 登录认证回调
func authenticator(ctx: JoyContext): Unit {
    // 读取Body
    let login: ?Login = ctx.bindJsonBody()
    if (let Some(l) <- login) {
        // 假定有两个用户admin与test
        if (l.username == "admin" && l.password == "admin" || l.username == "test" && l.password == "test") {
            let u = User(
                username: l.username,
                firstname: "cjoy",
                lastname: "cangjie"
            )
            // 认证通过， 设置上下文
            ctx.setCtxParam("user_info", u)
            return
        }
    }

    // 认证失败
    ctx.status(HttpStatusCode.STATUS_UNAUTHORIZED)
}
```

#### authorizator

用于设置已认证的用户路由访问权限的函数，如下函数通过验证用户名是否为 admin，从而判断是否有访问路由的权限。如果没有访问权限，则会触发 `unauthorized` 参数中声明的 jwt 流程验证失败的响应函数。

示例：

```cangjie
// 授权回调
func authorizator(ctx: JoyContext, identity: String): Bool {
    if (ctx.path == "/auth/logout") {
        return true
    }
    // 只有admin授权通过
    return identity == "admin"
}
```

#### setPayload

用于设置登录时为 token 添加自定义负载信息的函数。如果不传入这个参数，则 token 的 payload 部分默认存储 token 的过期时间和创建时间。

示例：

```cangjie
func setJwtPayload(ctx: JoyContext, jwt: Jwt): Unit {
    let user = ctx.getCtxParam<User>("user_info")
    // 从认证通过User取信息塞到JWT的claims中
    if (let Some(u) <- user) {
        // 需要与identityKey相同
        jwt.claims.claim("identity", u.username)
        jwt.claims.claim("name", "${u.firstname} ${u.lastname}")
    }
}
```

#### 自定义响应函数

可以自定义各种场景的响应格式：

```cangjie
// 自定义登录响应
func customLoginResponse(ctx: JoyContext, code: UInt16, token: String, expire: DateTime): Unit {
    ctx.status(code).json(@ToJson({
        "code": code,
        "message": "登录成功",
        "data": {
            "token": token,
            "expire": expire.format(DateTimeFormat.RFC3339),
            "tokenType": "Bearer"
        }
    }))
}

// 自定义认证失败响应
func customUnauthorized(ctx: JoyContext, code: UInt16, message: String): Unit {
    ctx.status(code).json(@ToJson({
        "code": code,
        "message": message,
        "error": "AUTH_FAILED"
    }))
}

// 自定义登出响应
func customLogoutResponse(ctx: JoyContext, code: UInt16): Unit {
    ctx.status(code).json(@ToJson({
        "code": code,
        "message": "登出成功"
    }))
}
```

---

## 四、OAuth2认证

OAuth2是一种授权框架，旨在允许用户通过授权服务器授予第三方应用程序对其资源的访问权限，而无需将用户凭据（用户名和密码）直接暴露给这些应用程序。OAuth2定义了一组角色、授权类型和协议流程，以实现安全的身份验证和授权机制。

### 4.1 核心概念

- **资源所有者（Resource Owner）**：拥有受保护资源的用户
- **客户端（Client）**：要访问受保护资源的应用程序
- **授权服务器（Authorization Server）**：负责验证用户身份并颁发访问令牌的服务器
- **资源服务器（Resource Server）**：存储受保护资源的服务器，并根据授权服务器颁发的访问令牌提供对这些资源的访问
- **访问令牌（Access Token）**：用于访问受保护资源的令牌，代表了授权的凭据
- **授权范围（Scope）**：指定了访问令牌可访问的资源范围
- **授权类型（Grant Type）**：定义了客户端获取访问令牌的方式

### 4.2 协议流程

```
     +--------+                               +---------------+
     |        |--(A)- Authorization Request ->|   Resource    |
     |        |                               |     Owner     |
     |        |<-(B)-- Authorization Grant ---|               |
     |        |                               +---------------+
     |        |
     |        |                               +---------------+
     |        |--(C)-- Authorization Grant -->| Authorization |
     | Client |                               |     Server    |
     |        |<-(D)----- Access Token -------|               |
     |        |                               +---------------+
     |        |
     |        |                               +---------------+
     |        |--(E)----- Access Token ------>|    Resource   |
     |        |                               |     Server    |
     |        |<-(F)--- Protected Resource ---|               |
     +--------+                               +---------------+
```

核心流程包括以下步骤：

- （A）用户打开客户端以后，客户端要求用户给予授权
- （B）用户同意给予客户端授权
- （C）客户端使用上一步获得的授权，向认证服务器申请令牌
- （D）认证服务器对客户端进行认证以后，确认无误，同意发放令牌
- （E）客户端使用令牌，向资源服务器申请获取资源
- （F）资源服务器确认令牌无误，同意向客户端开放资源

理解OAuth2，可以参见[理解OAuth 2.0](https://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)

### 4.3 关键设计

CJoy内置了OAuth2的实现，关键设计如下：

- **ClientStore**：客户端（Client）信息存储，默认提供内存存储 `MemoryClientStore`
- **TokenStore**：访问令牌（Access Token/Refresh Token/Authorization Code）信息存储，默认提供内存存储 `MemoryTokenStore`
- **TokenGenerate**：Access Token/Refresh Token 的生成器，默认提供基于安全随机HMAC的实现 `SecureRandTokenGenerate`
- **CodeGenerate**：Authorization Code 的生成器，默认提供基于安全随机HMAC的实现 `SecureRandCodeGenerate`
- **OAuth2Manager**：聚合上述接口实现的管理器
- **OAuth2Server**：提供 OAuth2 的认证外部接口，处理整体流程

支持如下身份验证模式：

- **授权码模式**：适用于后端应用，确保令牌安全存储
- **隐式模式**：适用于前端单页应用，直接颁发访问令牌
- **密码模式**：适用于高信任度的客户端应用
- **客户端模式**：适用于无用户参与的后端服务

### 4.4 使用示例

授权服务器服务端：

```cangjie
// 创建Client信息存储器
let clientStore = MemoryClientStore()

// 注册客户端信息
let cli = ClientInfo(
    id: clientId,
    secret: "",
    domain: "http://127.0.0.1:28882",
    isPublic: true
)
clientStore.add(cli)

// 创建OAuth2Manager与OAuth2Server
let manager = DefaultOAuth2Manager(clientStore: clientStore)
let server = OAuth2Server(manager)

// 设置用户授权回调
server.setUserAuthorizationHandleFunc({
    // 测试代码，直接返回clientId
    ctx: JoyContext => clientId
})
// 从提交表单中获取Client信息
server.setClientInfoHandleFunc(clientFormHandleFunc)

// 开启Http服务器
let joy = Joy.default()
// 注册认证授权处理器
joy.router.get("/authorize", server.authorizeRequestHandleFunc)
joy.router.post("/authorize", server.authorizeRequestHandleFunc)
// 注册获取Token处理器
joy.router.get("/token", server.tokenRequestHandleFunc)
joy.router.post("/token", server.tokenRequestHandleFunc)

joy.run("127.0.0.1", 18881)
```

资源服务器实现授权回调接口，并调用授权服务器的 `/token` 接口获取Token：

```cangjie
let joy = Joy.default()
let client = JoyHttpClientService("http://127.0.0.1:18881/")

let handler2 = {
    ctx: JoyContext =>
        let code = ctx.getForm("code").getOrThrow()
        let state = ctx.getForm("state").getOrThrow()
        if (state != "123") {
            @Fail("unrecognized state: ${state}")
            return
        }

        let form = Form()
        form.add("redirect_uri", "http://127.0.0.1:28882/oauth2_cb_2")
        form.add("code", code)
        form.add("grant_type", "authorization_code")
        form.add("client_id", clientId)
        form.add("code_verifier", _plainChallenge)

        // 调用授权服务器的 /token
        let rsp = client.postform(ctx, "/token", form)
        let token = rsp.json<TokenBody>().getOrThrow()
        // 获取accessToken，并存储accessToken
        // 后续Client拿accessToken访问受保护的资源时，对AccessToken进行检查
        validateAccessToken(ctx, token.accessToken)
}

// 注册授权处理器
joy.router.post("/oauth2_cb_2", handler2)
joy.router.get("/oauth2_cb_2", handler2)
```

Client向授权服务器 `/authorize` 发送请求：

```cangjie
let clientId: String = "abcdef"
let plainChallenge = "axxdafafdddaafdadadfdsafadfdafdada"

// 向授权服务器发送请求
// redirect_uri为资源服务器地址
let client = JoyHttpClientService("http://127.0.0.1:18881/")
let rsp = client.get(
    ctx,
    "/authorize",
    HashMap<String, ToString>([
        ("response_type", "code"),
        ("client_id", clientId),
        ("scope", "all"),
        ("state", "123"),
        ("redirect_uri", "http://127.0.0.1:28882/oauth2_cb_2"),
        ("code_challenge", plainChallenge)
    ])
)
```

### 4.5 自定义扩展

OAuth2模块面向接口编程，您可以实现如下接口，扩展自己的实现：

- **ClientStore**：默认实现 `MemoryClientStore`，建议扩展实现存储在数据库中
- **TokenStore**：默认实现 `MemoryTokenStore`，建议扩展实现存储在Redis或数据库中
- **TokenGenerate**：默认实现 `SecureRandTokenGenerate`，是基于安全随机HMAC的实现，可以扩展实现生成JWT
- **CodeGenerate**：默认实现 `SecureRandCodeGenerate`，是基于安全随机HMAC的实现

流程控制管理类 `OAuth2Server` 也提供一系列的 `setXXX` 方法，其函数原型定义在 `oauth2/handler.cj` 文件，您可以扩展自己的实现：

| 回调函数 | 说明 | 默认实现 |
|----------|------|----------|
| ClientInfoHandleFunc | 获取Client信息 | `clientFormHandleFunc` / `clientBasicHandleFunc` |
| ClientAuthorizedHandleFunc | 检查客户端是否允许使用此授权 | - |
| ClientScopeHandleFunc | 检查客户端是否允许使用Scope | - |
| UserAuthorizationHandleFunc | 从请求授权中获取UserId | - |
| PasswordAuthorizationHandleFunc | 根据用户名+密码获取UserId | - |
| RefreshingScopeHandleFunc | 检查Refresh Token的允许使用Scope | - |
| RefreshingValidationHandleFunc | 检查Refresh Token是否还有效 | - |
| ResponseErrorHandleFunc | 响应错误时回调 | `defaultResponseErrorHandleFunc` |
| InternalErrorHandleFunc | 发现内部错误时回调 | `defaultInternalErrorHandleFunc` |
| PreRedirectErrorHandleFunc | Redirect Error之前回调 | - |
| AuthorizeScopeHandleFunc | 对认证使用Scope进行设置 | - |
| AccessTokenExpHandleFunc | 对Access Token过期时间进行设置 | - |
| ExtensionFieldsHandleFunc | 生成响应时提取扩展字段回调 | - |
| ResponseTokenHandleFunc | 生成响应回调，设置是否覆盖默认实现 | - |
| RefreshTokenResolveHandleFunc | 获取Refresh Token | `refreshTokenFormResolveHandleFunc` / `refreshTokenCookieResolveHandleFunc` |
| AccessTokenResolveHandleFunc | 获取Access Token | `accessTokenDefaultResolveHandleFunc` / `accessTokenCookieResolveHandleFunc` |

---

## 五、注意事项

1. **Basic认证安全性**：Basic认证使用Base64编码，不是加密，建议配合HTTPS使用

2. **Token存储位置**：生产环境应避免在URL参数或Form中传递敏感Token

3. **JWT密钥管理**：RSA算法的私钥必须妥善保管，泄露会导致任何人可伪造Token

4. **JWT过期时间**：合理设置Token过期时间，平衡安全性和用户体验

5. **OAuth2回调**：确保redirect_uri与注册的domain匹配，防止授权劫持

6. **Session依赖**：CsrfProtect等中间件需要配合Session使用

7. **自定义错误响应**：建议自定义认证失败响应，统一返回格式

---
<< [返回](../../README.md#使用指导)
