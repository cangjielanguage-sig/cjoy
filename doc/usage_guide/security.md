# Security 中间件

Security 中间件用于设置安全相关的 HTTP 响应头，帮助保护应用免受常见的安全威胁。

## 基本用法

```cangjie
import cjoy.middleware.Security

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(Security(
        frameDeny: true,
        contentTypeNosniff: true,
        browserXssFilter: true
    ))
    // ... 注册路由
    joy.run("127.0.0.1", 8080)
    return 0
}
```

## 配置选项

### allowedHosts

允许访问的主机名列表。如果设置为空数组（默认值），则允许所有主机名。如果不为空，只有列表中的主机名才能访问，其他会返回 403 Forbidden。

```cangjie
let security = Security(allowedHosts: ["example.com", "www.example.com"])
joy.router.use(security)
```

### frameDeny

设置 `X-Frame-Options` 头为 `DENY`，防止页面被嵌入到 iframe 中，防止点击劫持攻击。

```cangjie
let security = Security(frameDeny: true)
joy.router.use(security)
```

响应头：
```
X-Frame-Options: DENY
```

### customFrameOptionsValue

自定义 `X-Frame-Options` 头的值。设置后将覆盖 `frameDeny` 选项。

```cangjie
// 允许同源页面嵌入
let security = Security(customFrameOptionsValue: "SAMEORIGIN")
joy.router.use(security)

// 允许指定域名嵌入
let security = Security(customFrameOptionsValue: "ALLOW-FROM https://trusted-site.com")
joy.router.use(security)
```

### contentTypeNosniff

设置 `X-Content-Type-Options` 头为 `nosniff`，防止浏览器 MIME 类型嗅探攻击。

```cangjie
let security = Security(contentTypeNosniff: true)
joy.router.use(security)
```

响应头：
```
X-Content-Type-Options: nosniff
```

### browserXssFilter

设置 `X-XSS-Protection` 头为 `1; mode=block`，启用浏览器的 XSS 过滤器。

```cangjie
let security = Security(browserXssFilter: true)
joy.router.use(security)
```

响应头：
```
X-XSS-Protection: 1; mode=block
```

### contentSecurityPolicy

设置 `Content-Security-Policy` (CSP) 头，用于定义资源加载策略，防止 XSS 等攻击。

```cangjie
// 基本策略：只允许同源资源
let security = Security(
    contentSecurityPolicy: "default-src 'self'"
)
joy.router.use(security)

// 完整策略示例
let security = Security(
    contentSecurityPolicy: "default-src 'self'; " +
                          "script-src 'self' https://cdn.example.com; " +
                          "style-src 'self' 'unsafe-inline'; " +
                          "img-src 'self' data: https:; " +
                          "connect-src 'self' https://api.example.com"
)
joy.router.use(security)
```

常用 CSP 指令：

| 指令 | 说明 |
|------|------|
| `default-src` | 所有资源类型的默认策略 |
| `script-src` | JavaScript 脚本 |
| `style-src` | CSS 样式表 |
| `img-src` | 图片 |
| `connect-src` | fetch、XMLHttpRequest、WebSocket 等 |
| `font-src` | 字体文件 |
| `object-src` | object、embed、applet |
| `media-src` | audio、video |
| `frame-src` | frame、iframe |
| `base-uri` | base 元素 |
| `form-action` | form 表单提交 |

CSP 值说明：

| 值 | 说明 |
|-----|------|
| `'self'` | 只允许同源 |
| `'none'` | 不允许任何来源 |
| `'unsafe-inline'` | 允许内联脚本/样式 |
| `'unsafe-eval'` | 允许 eval() |
| `data:` | 允许 data: URI |
| `https:` | 允许所有 HTTPS 源 |

### referrerPolicy

设置 `Referrer-Policy` 头，控制请求中包含的 Referer 信息。

```cangjie
// 不发送 Referer
let security = Security(referrerPolicy: "no-referrer")
joy.router.use(security)

// 仅在同源请求时发送 Referer
let security = Security(referrerPolicy: "same-origin")
joy.router.use(security)

// 发送完整的 URL
let security = Security(referrerPolicy: "unsafe-url")
joy.router.use(security)
```

Referrer-Policy 值：

| 值 | 说明 |
|-----|------|
| `no-referrer` | 不发送 Referer |
| `no-referrer-when-downgrade` | HTTPS → HTTP 不发送（默认） |
| `same-origin` | 仅同源发送 |
| `origin` | 只发送源（不含路径） |
| `strict-origin` | 同 origin，但 HTTPS → HTTP 不发送 |
| `origin-when-cross-origin` | 同源发完整 URL，跨源只发源 |
| `strict-origin-when-cross-origin` | 同 origin 同 origin-when-cross-origin，但 HTTPS → HTTP 不发送 |
| `unsafe-url` | 总是发送完整 URL |

### ieNoOpen

设置 `X-Download-Options` 头为 `noopen`，防止 IE 在站点上下文中执行下载。

```cangjie
let security = Security(ieNoOpen: true)
joy.router.use(security)
```

响应头：
```
X-Download-Options: noopen
```

### featurePolicy

设置 `Feature-Policy` 头（现已更名为 `Permissions-Policy`），控制浏览器功能和 API 的使用。

```cangjie
// 禁用地理定位
let security = Security(featurePolicy: "geolocation 'none'")
joy.router.use(security)

// 允许同源使用摄像头
let security = Security(featurePolicy: "camera 'self'")
joy.router.use(security)

// 多个功能策略
let security = Security(
    featurePolicy: "geolocation 'self'; " +
                   "camera 'self'; " +
                   "microphone 'none'"
)
joy.router.use(security)
```

常用功能：

| 功能 | 说明 |
|------|------|
| `geolocation` | 地理定位 |
| `camera` | 摄像头 |
| `microphone` | 麦克风 |
| `fullscreen` | 全屏 |
| `payment` | 支付请求 |
| `usb` | USB 设备 |
| `autoplay` | 自动播放 |
| `vibrate` | 震动 |
| `push` | 推送通知 |

## 完整示例

```cangjie
import cjoy.Joy
import cjoy.middleware.Security

main(): Int64 {
    let joy = Joy.default()

    let security = Security(
        allowedHosts: ["example.com", "www.example.com"],
        frameDeny: true,
        contentTypeNosniff: true,
        browserXssFilter: true,
        contentSecurityPolicy: "default-src 'self'; " +
                              "script-src 'self' https://cdn.example.com; " +
                              "style-src 'self' 'unsafe-inline'",
        referrerPolicy: "same-origin",
        ieNoOpen: true,
        featurePolicy: "geolocation 'self'; camera 'none'; microphone 'none'"
    )

    joy.router.use(security)

    joy.router.get("/", {ctx: JoyContext =>
        ctx.string("Hello, Secure World!")
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

## 局部应用

将 Security 中间件应用到特定路由组：

```cangjie
// 只对 /api 下的路由应用安全策略
joy.router
    .group("/api")
    .use(Security(frameDeny: true, contentTypeNosniff: true))
    .get("/data", {ctx => ctx.json([("key", "value")])})
```

## 安全建议

对于生产环境，建议至少启用以下选项：

```cangjie
let security = Security(
    frameDeny: true,           // 防止点击劫持
    contentTypeNosniff: true,  // 防止 MIME 嗅探攻击
    browserXssFilter: true     // 启用 XSS 过滤
)

// 如果已配置 CSP，可以禁用 browserXssFilter
let securityWithCSP = Security(
    frameDeny: true,
    contentTypeNosniff: true,
    contentSecurityPolicy: "default-src 'self'"
)
```

----
<< [返回](../../README.md#使用指导)
