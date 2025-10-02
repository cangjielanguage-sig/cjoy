# 认证

认证是Web应用的关键环节，通过用户角色或权限控制资源访问。其本质是验证用户身份以授予受保护资源的访问权限，确保仅经认证的用户可执行操作或访问应用数据。

CJoy提供了多种实现认证机制。

## Basic认证

基本认证是一种简单的HTTP认证方案，用户凭据（用户名和密码）以Base64编码格式通过请求头传输。

基本认证是验证API最简单的方式。它基于HTTP协议的认证机制，在标准的Authorization头中发送以"Basic "为前缀的Base64Encode(<用户名>:<密码>)。

CJoy提供了两种实现Basic认证的方式： 

使用示例：[test/basic_auth_test](../../src/test/basic_auth_test.cj) 。

### 预定义认证凭证

```
let joy = Joy.default()
let router = joy.router

// 创建BasicAuth中间件对象，指定认证任证
let basicAuth = BasicAuth("test", HashMap<String, String>([("xiao", "xiao"), ("lanling", "lanling")]))
router.use(basicAuth)
```

### 自定义校对函数

实现BasicAuthValidationFunc函数，创建BasicAuth中间件对象时，指定valiateFunc，此函数将用户名和密码作为参数，如果有效则返回true，否则返回false。

```
let joy = Joy.default()
let router = joy.router

// 创建BasicAuth中间件对象，指定认证校对函数
let basicAuth =  BasicAuth("test", HashMap<String, String>(), valiateFunc: {
    ctx: JoyContext, username: String, password: String => username == "xiao" && password == "abcdef"
})

router.use(basicAuth)
```

### 参数说明

BasicAuth提供如下参数，非必选参数提供默认实现，用户可以实现对应函数扩展自已的逻辑。

|参数|是否可选|说明|
|---|---|---|
|realm|否|用于设置所属领域名称|
|creads|否|认证凭证|
|filterFunc|是|用于指定过滤函数|
|valiateFunc|是|用于指定校验函数|

#### filterFunc

可选参数，用于用户指定过滤不需要认证的请求。

## Token认证

API Token验证通常用于用于机机接口，服务给某个应用颁发一次性Token。应用获取Token之后，在HTTP请求的Header（默认值：Authorization）、Cookie或URL Path等指定认证的Token，服务端对此Token进行校验。

CJoy提供了两种实现Token认证的方式： 

使用示例：[examples/tokenauth](../../examples/src/tokenauth/main.cj) 。

### 预定义认证凭证

```
let joy = Joy.default()
let router = joy.router
// 指定预定义的Token列表
let tokenAuth = TokenAuth(["abc"])
router.use(tokenAuth)
```

### 自定义校对函数

实现TokenAuthValidatorFunc函数，创建TokenAuth中间件对象时，指定validator，此函数将token作为参数，如果有效则返回true，否则返回false。

```
let joy = Joy.default()
let router = joy.router

// 创建TokenAuth中间件对象，指定认证校对函数
let tokenAuth =  TokenAuth({
    ctx: JoyContext, token: String => token == "abcd"
})

router.use(tokenAuth)
```

### 参数说明

TokenAuth提供如下参数，非必选参数提供默认实现，用户可以实现对应函数扩展自已的逻辑。

|参数|是否可选|说明|
|---|---|---|
|validator|否|用于指定校验函数|
|lookupKey|是|用于设置 token 的获取源，可以选择 header、query、cookie、param、form，默认为 header:Authorization|
|authSchema|否|用于设置从 header 中获取 token 时的Schema，默认为 Bearer|
|successHandleFunc|否|用于指定认证成功之后扩展逻辑函数|
|errorHandleFunc|否|用于指定认证失败之后扩展逻辑函数|
|filterHandleFunc|否|用于指定过滤函数|

#### lookupKey

可选参数，keyLookup 用于指定从哪里提取Token的位置，格式为 <source>:<token_name>，默认值为`header:Authorization` 。

source 支持如下：
 
 - cookie
 - header
 - param
 - query
 - form
  
#### authSchema

可选参数，认证的Schema，当lookupKey为header时指定且有效，默认值为`Bearer` 。

假定Token为abcd，则要求请求在头哉指定为：`Authorization: Bearer abcd`

#### successHandleFunc

可选参数，当认证成功之后回调，用于扩展校验 token 通过的自定义处理逻辑。

#### errorHandleFucn

可选参数，当认证失败之后回调，用于扩展校验 token 未通过的自定义处理逻辑。

默认实现会打印日志。

#### filterHandleFunc

可选参数，用于用户指定过滤不需要认证的请求。

## JWT认证

JWT（JSON Web Token）是一种用于在网络应用中传输信息的开放标准（RFC 7519），通常用于用户身份验证和授权。它由三部分组成：头部（Header）、载荷（Payload）和签名（Signature）。

### JWT框架

#### 签名算法

CJoy内置了JWT的实现，支持如下签名算法：

 - HS256， HS384， HS512
 - RS256， RS384， RS512
 - PS256， PS384， PS512

注：CJoy不是供None算法，应该签名为None时，JWT可以在传输过程中被篡改。

#### 生成Token

HS256 示例：

```
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
```
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

#### 解释Token

HS256 示例：
```
let key = "abcd".toArray()
let jwt = Jwt.pasrse(token).verifyWith(key)
// parse函数还可以指定ParserConfig参数，用于检查指定的信息，具体配置项请参见ParserConfig定义
let jwt2 = Jwt.pasrse(token, config: ParserConfig(expectedAud:["aud"])).verifyWith(key)
```

RS256 示例：

```
let pub = loadRSAPublicKey("./testdata/rsa_public.pem")
let jwt = Jwt.pasrse(token).verifyWith(pub)
```

### JWT中间件

使用示例：[examples/jwtauth](../../examples/src/jwtauth/main.cj) 。

设置中间件：

```
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

joy.router.post("/login", jwtAuth.loginHandler)

let auth = joy.router.group("/auth")
auth.use(jwtAuth)
auth.get("/refresh_token", jwtAuth.refreshTokenHandler)
auth.post("/logout", jwtAuth.logoutHandler)
```

JWT中间件会内置三个主要Handler，实现用户登录获取Token，刷新Token，以及登出。

在其它的接口获取JWT：

```
@Get[path = "/auth/biz", produce = "json"]
func someBizHandle(): JsonSerializable {
    // 此函数已会检查JWT是否通过
    // 调用getJwt 获取JWT
    let token = getJwt(ctx)
    @ToJson({"data": "abcd"})
}
```

#### 参数说明

JwtAuth提供一系列的命名参数，非必选参数提供默认实现，用户可以实现对应函数扩展自已的逻辑。

|参数|是否可选|说明|
|---|---|---|
|realm|否|用于设置所属领域名称|
|signingAlg|否|用于设置签名算法，HS256、HS384、HS512、RS256、RS384等|
|keyProvider|否|用于设置签名密钥，框架提供HmacSigningkey与RsaSigningkey类简化|
|authenticator|否|用于设置登录时认证用户信息的函数|
|authorizator|是|用于设置授权已认证的用户路由访问权限的函数，默认全授权|
|setPayload|是|用于设置登陆成功后为向 token 中添加自定义负载信息的函数|
|unauthorized|是|用于设置 jwt 验证流程失败的响应函数|
|loginResponse|是|用于设置登录的响应函数|
|logoutResponse|是|用于设置登出的响应函数|
|refreshResponse|是|用于设置 token 有效时长刷新后的响应函数|
|timeout|是|用于设置 token 过期时间，默认为30min|
|maxRefresh|是|用于设置最大 token 刷新时间，允许客户端在 TokenTime + MaxRefresh 内刷新 token 的有效时间，追加一个 Timeout 的时长，默认为无限|
|identityKey|是|用于用于设置检索身份的键，默认为 identity|
|identityHandler|是|用于设置获取身份信息的函数，默认与 IdentityKey 配合使用|
|tokenLookup|是|用于设置 token 的获取源，可以选择 header、query、cookie、param、form，默认为 header:Authorization|
|tokenHeadName|是|用于设置从 header 中获取 token 时的前缀，默认为 Bearer|
|sendCookie|是|用于设置 token 将同时以 cookie 的形式返回，下列 cookie 相关配置生效的前提是该值为 true，默认为 false|
|cookieMaxAge|是|用于设置 cookie 的有效期，默认为30min|
|cookieSecure|是|用于设置允许不通过 HTTPS 传递 cookie 信息，默认为 false|
|cookieHttpOnly|是|用于设置允许客户端访问 cookie 以进行开发，默认为 false|
|cookieDomain|是|用于设置 cookie 所属的域，默认为空|
|cookieName|是|用于设置 cookie 的 name 值，默认为jwt|
|sendAuthorization|是|用于设置为所有请求的响应头添加授权的 token 信息，默认为 false|
|jwtParserConfig|是|用于设置JWT解释配置，默认为None|

#### authenticator

配合 JwtAuth.loginHandler 使用，登录时触发，用于认证用户的登录信息。

示例：

```
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

用于设置已认证的用户路由访问权限的函数，如下函数通过验证用户名是否为 admin，从而判断是否有访问路由的权限。如果没有访问权限，则会触发 Unauthorized 参数中声明的 jwt 流程验证失败的响应函数。

示例：

```
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

用于设置登录时为 token 添加自定义负载信息的函数，如果不传入这个参数，则 token 的 payload 部分默认存储 token 的过期时间和创建时间，如下则额外存储了用户名信息。

示例:

```
func setJwtPayload(ctx: JoyContext, jwt: Jwt): Unit {
    let user = ctx.getCtxParam<User>("user_info")
    // 从认证通过User取信息塞到JWT的claims中
    if (let Some(u) <- user) {
        // 需要与identityKey相同
        jwt.claims.claim("identity", u.username)
    }
}
```

## OAuth2认证

OAuth2是一种授权框架，旨在允许用户通过授权服务器授予第三方应用程序对其资源的访问权限，而无需将用户凭据（用户名和密码）直接暴露给这些应用程序。OAuth2定义了一组角色、授权类型和协议流程，以实现安全的身份验证和授权机制。

核心概念：

 - 资源所有者（Resource Owner）：拥有受保护资源的用户。
 - 客户端（Client）：要访问受保护资源的应用程序。
 - 授权服务器（Authorization Server）：负责验证用户身份并颁发访问令牌的服务器。
 - 资源服务器（Resource Server）：存储受保护资源的服务器，并根据授权服务器颁发的访问令牌提供对这些资源的访问。
 - 访问令牌（Access Token）：用于访问受保护资源的令牌，代表了授权的凭据。
 - 授权范围（Scope）：指定了访问令牌可访问的资源范围。
 - 授权类型（Grant Type）：定义了客户端获取访问令牌的方式，如授权码授权、密码授权、客户端凭证授权等。

协议流程：

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

- （A）用户打开客户端以后，客户端要求用户给予授权。
- （B）用户同意给予客户端授权。
- （C）客户端使用上一步获得的授权，向认证服务器申请令牌。
- （D）认证服务器对客户端进行认证以后，确认无误，同意发放令牌。
- （E）客户端使用令牌，向资源服务器申请获取资源。
- （F）资源服务器确认令牌无误，同意向客户端开放资源。

理解OAuth2，可以参见[理解OAuth 2.0](https://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)

### OAuth2框架

### 关键设计

CJoy内置了JWT的实现，关键设计如下：

- ClientStore：客户端（Client）信息存储，默认提供内存存储
- TokenStore：访问令牌（Access Token/Refresh Token/ Authorization Code）信息存储，默认提供内存存储
- AccessGenerate：Access Token/Refresh Token的生成器，默认提供基于安全随机HMAC的实现
- AuthorizeGenerate：Authorization Code的生成器，默认提供基于安全随机HMAC的实现
- OAuth2Manager：聚合上述接口实现的管理器
- OAuth2Server： 提供OAuth2的认证外部接口，处理整体流程。

支持如下身份验证模式：

 - 授权码模式：适用于后端应用，确保令牌安全存储。
 - 隐式模式：适用于前端单页应用，直接颁发访问令牌。
 - 密码模式：适用于高信任度的客户端应用。
 - 客户端模式：适用于无用户参与的后端服务。

### 使用示例：

使用示例：[test/oauth2_test](../../src/test/oauth2_test.cj) 。

授权服务器服务端：

```
// 创建信息存储器
let clientStore = MemoryClientStore()

// 注册客户端信息
let cli = ClientInfo(id: clientId, secret: "", domain: "http://127.0.0.1:28882", isPublic: true)
clientStore.add(cli)

// 创建管理器，与OAuth2Server
let manager = DefaultOAuth2Manager(clientStore: clientStore)
let server = OAuth2Server(manager)

// 设置server
server.setUserAuthorizationHandleFunc({
    ctx: JoyContext => _clientId
})
server.setClientInfoHandleFunc(clientFormHandleFunc)

// 开启Http服务器
let joy = Joy.default()
let router = joy.router
// 注册认证处理器
router.get("/authorize", server.authorizeRequestHandleFunc)
router.post("/authorize", server.authorizeRequestHandleFunc)
// 注册获取Token处理器
router.get("/token", server.tokenRequestHandleFunc)
router.post("/token", server.tokenRequestHandleFunc)

```

资源服务器实现授权回调接口：

```
let joy = Joy.default()
let router = joy.router
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
        
        // 调用 授权服务器的 /token
        let rsp = client.postform(ctx, "/token", form)
        let token = rsp.json<TokenBody>().getOrThrow()
        // 获取 accessToken
        validateAccessToken(ctx, token.accessToken)
}

// 注册授权处理器
router.post("/oauth2_cb_2", handler2)
router.get("/oauth2_cb_2", handler2)
```

客户端发送请求：

```
let clientId: String = "abcdef"
let plainChallenge = "axxdafafdddaafdadadfdsafadfdafdada"

// 向授权服务器发送请求
// redirect_uri为资源服务器地址
let client = JoyHttpClientService("http://127.0.0.1:18881/")
let rsp = client.get(
    ctx,
    "/authorize",
    HashMap<String, ToString>(
        [
            ("response_type", "code"),
            ("client_id", clientId),
            ("scope", "all"),
            ("state", "123"),
            ("redirect_uri", "http://127.0.0.1:28882/oauth2_cb_2"),
            ("code_challenge", plainChallenge)
        ]
    )
)

// 拿到Token
let token = rsp.json<TokenBody>().getOrThrow()
```

----
<< [返回](../../README.md#使用指导)