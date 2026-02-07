# CsrfProtect 中间件

CSRF (Cross-Site Request Forgery) 跨站请求伪造是一种攻击方式，攻击者诱导用户在已认证的网站上执行非预期的操作。CsrfProtect 中间件通过 CSRF Token 来防止此类攻击。

---

## 概述

CJoy CsrfProtect中间件基于以下核心概念设计：

- **Token生成**：基于 SHA256 哈希 + Base64 编码生成 CSRF Token
- **Session集成**：Secret 存储在 Session 中，确保 Token 安全
- **灵活配置**：支持从 Header、Query、Form、Param 等位置获取 Token
- **过滤函数**：支持跳过特定请求的 CSRF 验证
- **自定义错误处理**：支持自定义验证失败响应

核心类：`CsrfProtect`，参见 [csrf.cj](../../src/middleware/csrf.cj)

---

## 一、工作原理

1. 服务器生成一个随机 Secret，存储在 Session 中
2. 使用 Secret 和随机 Salt 生成 CSRF Token（通过 SHA256 哈希 + Base64 编码）
3. 客户端在表单或请求中携带此 Token
4. 服务器验证 Token 是否匹配，防止伪造请求

---

## 二、基本用法

CsrfProtect 中间件需要配合 Session 使用：

```cangjie
import cjoy.middleware.{SessionManager, CsrfProtect, getSession}
import cjoy.middleware.JoySessionConfig
import cjoy.session.MemorySessionStorage

main(): Int64 {
    let joy = Joy.default()

    // 1. 注册 Session 中间件（CsrfProtect 依赖 Session）
    let sessionManager = SessionManager(MemorySessionStorage())
    joy.router.use(sessionManager)

    // 2. 注册 CsrfProtect 中间件
    let csrf = CsrfProtect(
        secret: "your-secret-key-here"
    )
    joy.router.use(csrf)

    joy.run("127.0.0.1", 8080)
    return 0
}
```

---

## 三、获取 CSRF Token

使用 `getCsrfToken` 函数生成或获取当前的 CSRF Token：

```cangjie
import cjoy.middleware.getCsrfToken

@Get[path = "/form"]
func showForm(ctx: JoyContext): Unit {
    // 获取 CSRF Token
    let token = getCsrfToken(ctx)

    // 在 HTML 表单中使用
    let html = """
        <html>
        <body>
            <form method="POST" action="/submit">
                <input type="hidden" name="csrf_token" value="${token}" />
                <input type="text" name="username" />
                <button type="submit">提交</button>
            </form>
        </body>
        </html>
    """
    ctx.html(html)
}
```

---

## 四、配置选项

### 4.1 构造函数参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| secret | String | - | 用于生成 Token 的密钥 |
| ignoreMethods | Array<String> | ["GET", "HEAD", "OPTIONS"] | 不需要 CSRF 保护的 HTTP 方法 |
| lookupKey | String | "header:X-CSRF-TOKEN" | 从请求中提取 Token 的位置 |
| filterHandler | JoyRequestFilterFunc | None | 用于跳过 CSRF 验证的过滤函数 |
| errorHandler | JoyRequestHandlerFunc | 返回 401 | CSRF 验证失败时的处理函数 |

### 4.2 ignoreMethods

指定不需要 CSRF 保护的 HTTP 方法：

```cangjie
// 默认不保护 GET、HEAD、OPTIONS
let csrf = CsrfProtect(secret: "my-secret")

// 只保护 POST 方法
let csrf = CsrfProtect(
    secret: "my-secret",
    ignoreMethods: ["GET", "HEAD", "OPTIONS", "PUT", "DELETE", "PATCH"]
)
```

### 4.3 lookupKey

指定从请求中提取 CSRF Token 的位置，格式为 `<source>:<name>`：

| source | 说明 |
|---------|------|
| header | 从 HTTP 请求头获取 |
| query | 从 URL 查询参数获取 |
| form | 从 POST 表单获取 |
| param | 从 URL 路径参数获取 |

```cangjie
// 从请求头获取（默认）
let csrf = CsrfProtect(
    secret: "my-secret",
    lookupKey: "header:X-CSRF-TOKEN"
)

// 从表单获取
let csrf = CsrfProtect(
    secret: "my-secret",
    lookupKey: "form:csrf_token"
)

// 从查询参数获取
let csrf = CsrfProtect(
    secret: "my-secret",
    lookupKey: "query:token"
)
```

### 4.4 filterHandler

用于跳过 CSRF 验证的过滤函数：

```cangjie
let csrf = CsrfProtect(
    secret: "my-secret",
    filterHandler: {
        ctx: JoyContext =>
            // 公开 API 不需要 CSRF 保护
            ctx.path.startsWith("/api/public/")
    }
)
```

### 4.5 errorHandler

自定义 CSRF 验证失败的处理：

```cangjie
let csrf = CsrfProtect(
    secret: "my-secret",
    errorHandler: {
        ctx: JoyContext =>
            ctx.status(401).json(@ToJson({
                "code": 401,
                "message": "CSRF 验证失败，请刷新页面重试"
            }))
    }
)
```

---

## 五、完整示例

```cangjie
import cjoy.Joy
import cjoy.middleware.{SessionManager, CsrfProtect, getSession, getCsrfToken}
import cjoy.middleware.JoySessionConfig
import cjoy.session.MemorySessionStorage
import cjoy.json.macros.*

main(): Int64 {
    let joy = Joy.default()

    // 注册 Session
    let sessionManager = SessionManager(MemorySessionStorage())
    joy.router.use(sessionManager)

    // 注册 CsrfProtect
    let csrf = CsrfProtect(
        secret: "my-csrf-secret-key",
        lookupKey: "form:csrf_token"
    )
    joy.router.use(csrf)

    // 显示表单（GET 请求不需要 CSRF 验证）
    joy.router.get("/form", {ctx: JoyContext =>
        let token = getCsrfToken(ctx)
        ctx.html("""
            <!DOCTYPE html>
            <html>
            <head><title>CSRF 保护表单</title></head>
            <body>
                <h1>CSRF 保护表单示例</h1>
                <form method="POST" action="/submit">
                    <input type="hidden" name="csrf_token" value="${token}" />
                    <label>用户名: <input type="text" name="username" /></label><br>
                    <button type="submit">提交</button>
                </form>
            </body>
            </html>
        """)
    })

    // 处理表单提交（POST 请求需要 CSRF 验证）
    joy.router.post("/submit", {ctx: JoyContext =>
        if (let Some(username) <- ctx.getPostForm("username")) {
            ctx.json(@ToJson({
                "message": "提交成功",
                "username": username
            }))
        } else {
            ctx.json(@ToJson({"message": "用户名不能为空"}))
        }
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

---

## 六、AJAX 请求示例

对于 AJAX 请求，需要在请求头中携带 CSRF Token：

```javascript
// 前端获取 Token 并存储
const token = document.querySelector('input[name="csrf_token"]').value;
localStorage.setItem('csrfToken', token);

// 发送 AJAX 请求时携带 Token
fetch('/api/data', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'X-CSRF-TOKEN': localStorage.getItem('csrfToken')
    },
    body: JSON.stringify({ data: 'value' })
});
```

服务器端配置：

```cangjie
let csrf = CsrfProtect(
    secret: "my-secret",
    lookupKey: "header:X-CSRF-TOKEN"  // 从请求头获取
)
joy.router.use(csrf)
```

---

## 七、注意事项

1. **Session 依赖**：CsrfProtect 必须配合 SessionManager 使用

2. **Secret 密钥**：使用强随机密钥，不要在代码中硬编码

3. **Token 生命周期**：Token 与 Session 绑定，Session 失效后 Token 也会失效

4. **GET 请求**：默认 GET、HEAD、OPTIONS 请求不需要 CSRF 验证

5. **前端框架**：使用前端框架时，需要将 Token 注入到每个状态改变请求中

6. **HTTPS**：生产环境必须使用 HTTPS

7. **SameSite Cookie**：配合 HttpOnly 和 Secure Cookie 使用增强安全性

8. **日志记录**：验证失败会记录错误日志，可用于监控攻击

---
<< [返回](../../README.md#使用指导)
