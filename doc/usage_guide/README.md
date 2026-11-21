# 20分钟掌握CJoy

## 开发环境搭建

### 环境要求
- **仓颉版本**：v1.0.4 或更高版本
- **CANGJIE_STDX_PATH**：需要配置此环境变量指向 stdx 包目录
- **cjpm**：Cangjie Package Manager，用于项目构建和管理

### 安装与配置
1. 安装仓颉编译器和 cjpm 工具
2. 配置 `CANGJIE_STDX_PATH` 环境变量：
   ```bash
   export CANGJIE_STDX_PATH=/path/to/stdx
   ```

**目录结构示例**：

```
$HOME
├── cangjie          # 仓颉 SDK 目录
└── cangjiestdx      # 新建此目录
    └── linux_x86_64_cjnative  # 解压对应的 stdx 包，不同 OS 目录名称不同
```

**配置环境变量**（Linux 与 MacOS）：

```bash
# 修改用户家目录的 .bashrc 或 .zshrc（取决于采用 bash 还是 zsh）
export CANGJIE_STDX_PATH=$HOME/cangjiestdx/linux_x86_64_cjnative/static/stdx
```

### 添加依赖

在您的项目 `cjpm.toml` 文件中添加依赖：

```toml
[dependencies]
cjoy = { git = "https://gitcode.com/Cangjie-SIG/cjoy.git", branch = "main" }
```

## 快速上手开发

### 1. 创建简单应用

**直接 API 模式**（适合简单应用）：
```cangjie
import cjoy.*

main(): Int64 {
    let joy = Joy.default()
    joy.router.get("/{name}", { ctx: JoyContext =>
        let name = ctx.getParam("name") ?? "no name"
        ctx.string("Hello, ${name}!")
    })
    joy.run("127.0.0.1", 18881)
    return 0
}
```

**宏驱动模式**（推荐）：
```cangjie
import cjoy.*
import cjoy.macros.*
import cjoy.json.*

@Json
class UserInfo {
    var id: String = ""
    var name: String = ""
    var address: String = ""
    var gender: Int = 0
}

@Get[path = "/users/{name}", produce="json"]
func getUser(@PathParam name: String): (UInt16, UserInfo) {
    let usr = UserInfo()
    usr.id = "00009527"
    usr.name = name
    usr.address = "shenzhen"
    (200, usr)
}

main(): Int64 {
    let joy = Joy.default()
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 2. 构建与运行

```bash
# 构建项目
cjpm build

# 运行示例
cd examples
cjpm run --name examples.simple
cjpm run --name examples.macros
cjpm run --name examples.rest
cjpm run --name examples.tls
```

## 核心功能开发

### 1. 路由管理

#### 基本路由
```cangjie
// 注册 GET 请求处理函数
joy.router.get("/path", { ctx: JoyContext =>
    ctx.string("Response")
})

// 注册 POST 请求处理函数
joy.router.post("/path", { ctx: JoyContext =>
    ctx.string("Response")
})
```

#### 路由分组
```cangjie
// 创建路由分组
let apiGroup = joy.router.group("/api/v1")
apiGroup.get("/users", userHandler)
apiGroup.post("/users", createUserHandler)

// 分组可以嵌套
let adminGroup = apiGroup.group("/admin")
adminGroup.get("/dashboard", dashboardHandler)
```

#### 路由参数
```cangjie
@Get[path = "/users/{id}"]
func getUser(@PathParam id: Int64): String {
    "User ID: ${id}"
}

@Get[path = "/search"]
func search(@QueryParam q: String, @QueryParam page: Int32 = 1): String {
    "Search: ${q}, Page: ${page}"
}
```

### 2. 请求处理

#### 获取请求信息
```cangjie
@Get[path = "/info"]
func getInfo(ctx: JoyContext): String {
    let method = ctx.method      // 请求方法
    let path = ctx.path          // 请求路径
    let url = ctx.url            // 完整 URL
    let remoteIp = ctx.getRemoteIP() // 远程 IP
    let userAgent = ctx.header("User-Agent") // 请求头

    "Method: ${method}, Path: ${path}"
}
```

#### 响应类型
```cangjie
// 返回字符串
ctx.string("Hello World")

// 返回 JSON
ctx.json(HashMap<String, String>([("message", "Hello")]))

// 返回状态码
ctx.status(404)
ctx.string("Not Found")

// 重定向
ctx.redirect(301, "/new-path")

// 返回文件
ctx.file("/path/to/file")
```

### 3. 参数绑定

CJoy 支持多种参数绑定方式：

#### 路径参数
```cangjie
@Get[path = "/users/{id}"]
func getUser(@PathParam id: Int64): String {
    "User ID: ${id}"
}
```

#### 查询参数
```cangjie
@Get[path = "/search"]
func search(@QueryParam q: String, @QueryParam page: Int32 = 1): String {
    "Search: ${q}, Page: ${page}"
}
```

#### 请求头参数
```cangjie
@Get[path = "/auth"]
func auth(@HeaderParam[name = "Authorization"] token: String): String {
    "Token: ${token}"
}
```

#### Cookie 参数
```cangjie
@Get[path = "/session"]
func getSession(@CookieParam sessionId: String): String {
    "Session ID: ${sessionId}"
}
```

#### 请求体参数
```cangjie
@Json
class User {
    var name: String = ""
    var email: String = ""
}

@Post[path = "/users"]
func createUser(@BodyParam user: User): String {
    "Created user: ${user.name}"
}
```

### 4. 参数验证

```cangjie
@Json
@Valid
class User {
    @NotBlank(message = "用户名不能为空")
    var name: String = ""

    @Email(message = "邮箱格式不正确")
    var email: String = ""

    @Size(min = 6, message = "密码长度至少6位")
    var password: String = ""
}

@Post[path = "/users"]
@Validated
func createUser(@BodyParam user: User): String {
    "Created user: ${user.name}"
}
```

### 5. 中间件开发

#### 全局中间件
```cangjie
@Middleware
func corsMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    ctx.header("Access-Control-Allow-Origin", "*")
    ctx.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS")
    chain.next(ctx)
}

main(): Int64 {
    let joy = Joy.default()
    JoyHandlers.registerTo(joy)
    JoyMiddlewares.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
```

#### 分组中间件
```cangjie
@Middleware[groups = "/api"]
func apiMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    ctx.header("X-API-Version", "1.0")
    chain.next(ctx)
}
```

#### 自定义中间件
```cangjie
class CustomMiddleware : JoyMiddlewareHandler {
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        // 前置处理
        let startTime = System.nanoTime()

        chain.next(ctx)

        // 后置处理
        let duration = System.nanoTime() - startTime
        ctx.header("X-Response-Time", "${duration}ns")
    }
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(CustomMiddleware())
    joy.run("127.0.0.1", 18881)
    return 0
}
```

## 宏系统使用

### 路由宏

```cangjie
// 基本用法
@Get[path = "/hello"]
func hello(): String {
    "Hello World"
}

// 支持多个方法
@Handler[method = "GET,POST", path = "/data"]
func getData(): String {
    "Data"
}

// 生产类型
@Get[path = "/json", produce = "json"]
func getJson(): HashMap<String, String> {
    HashMap([("message", "Hello")])
}
```

### IoC 宏

```cangjie
@Component[name = "userService", scope = "singleton"]
class UserService {
    func getUser(id: Int64): String {
        "User ${id}"
    }
}

@Controller[path = "/api/users"]
class UserController {
    let _userService: UserService

    init(@Autowired[name = "userService"] userService: UserService) {
        _userService = userService
    }

    @Get[path = "/{id}"]
    func getUser(@PathParam id: Int64): String {
        _userService.getUser(id)
    }
}
```

### JSON 宏

```cangjie
@Json
class Product {
    @JsonField[name = "product_id"]
    var id: Int64 = 0

    @JsonField[omitempty = true]
    var name: String = ""

    @JsonField[ignore = true]
    var internal: String = ""

    var price: Float64 = 0.0
}

func testJson() {
    let product = Product()
    product.id = 1
    product.name = "Apple"
    product.price = 5.99

    let jsonStr = JsonTool.toJson(product)
    println(jsonStr) // {"product_id":1,"name":"Apple","price":5.99}
}
```

### 验证宏

```cangjie
@Json
@Valid
class RegisterForm {
    @NotBlank(message = "用户名不能为空")
    @Length(min = 3, max = 20, message = "用户名长度在3-20个字符之间")
    var username: String = ""

    @Email(message = "邮箱格式不正确")
    var email: String = ""

    @NotBlank(message = "密码不能为空")
    @Size(min = 6, message = "密码长度至少6位")
    var password: String = ""
}

@Post[path = "/register"]
@Validated
func register(@BodyParam form: RegisterForm): String {
    "Registered user: ${form.username}"
}
```

## 部署与运行

### 1. 构建项目

```bash
cd your-project-dir

# 构建生产版本
cjpm build

# 构建调试版本
cjpm build -g
```

### 2. 运行项目

```bash
# 直接运行
cjpm run 

# 后台运行
nohup cjpm run &
```

### 3. 部署建议

- 使用 Docker 容器化部署
- 配置反向代理（如 Nginx）
- 启用 HTTPS
- 监控应用性能

## 开发实践建议

### 1. 代码规范

- 类名使用 PascalCase，方法名和变量名使用 camelCase
- 类尽可能不要定义为 public，只对外暴露最小的 API
- 实现一个功能的类与其关联类可以放在一个文件中，但每个类要职责单一

### 2. 错误处理

```cangjie
@Get[path = "/user/{id}"]
func getUser(@PathParam id: Int64): (UInt16, String) {
    try {
        let user = findUser(id)
        (200, user.toJson())
    } catch (ex: UserNotFoundException) {
        (404, "User not found")
    } catch (ex: Exception) {
        (500, "Internal server error")
    }
}
```

### 3. 日志记录

```cangjie
import cjoy.log.*

@JoyCreateLogger("module-name")

func someFunction() {
    @JoyLogDebug(logger, "Debug message")
    @JoyLogInfo(logger, "Info message")
    @JoyLogWarn(logger, "Warning message")
    @JoyLogError(logger, "Error message")
}
```

## 常见问题

### 1. 宏不生效
- 确保正确导入 `cjoy.macros.*`
- 检查宏使用是否符合语法要求
- 重新构建项目

### 2. 路由不匹配
- 检查路由是否正确注册
- 检查请求方法是否匹配
- 检查路由参数是否正确

### 3. 参数绑定失败
- 检查参数类型是否匹配
- 检查参数名是否正确
- 检查请求体格式是否正确

### 4. 验证失败
- 检查验证注解是否正确
- 检查验证规则是否符合要求
- 查看验证错误信息


## 详细使用指导

### 核心功能

- [服务启动](starter.md)
- [路由](routing.md)
- [请求处理](handler.md)
- [Middleware](middleware.md)
- [路由宏](macro.md)

### 基础服务

- [IoC 服务](ioc.md)
- [配置服务](config.md)
- [调度任务](schedule.md)
- [事件总线](eventbus.md)
- [Http 服务](httpx.md)

### 安全认证

- [认证概述](authentication.md)
- [Basic 认证](authentication.md#basic认证)
- [Token 认证](authentication.md#token认证)
- [JWT 认证](authentication.md#jwt认证)
- [OAuth2 认证](authentication.md#oauth2认证)

### 辅助工具

- [日志](logger.md)
- [参数绑定](binding.md)
- [JSON](json.md)
- [校验](validation.md)

### 协议扩展

- [分块传输](mcp.md)
- [文件服务器](fileserver.md)
- [WebSocket](websocket.md)
- [MultiPart](multipart.md)
- [MCP](mcp.md)