# Http服务

CJoy 提供完整的HTTP客户端功能，支持多种认证方式、重试机制和自定义扩展。

## 概述

CJoy HTTP客户端系统基于以下核心概念设计：

- **链式构建**：支持装饰器模式的客户端构建
- **多种认证**：支持Basic、Token、OAuth2等认证方式
- **重试机制**：内置重试和超时处理
- **HTTPS支持**：完整的SSL/TLS证书处理
- **请求类型**：支持JSON、表单、文件上传等请求类型
- **响应处理**：完整的响应解析和类型转换
- **扩展性**：支持自定义认证和拦截器

### 核心接口定义
- `JoyHttpClient`：HTTP客户端接口，参见 [httpx/api.cj](../../src/httpx/api.cj)
- `JoyHttpRequest`：HTTP请求封装，参见 [httpx/api.cj](../../src/httpx/api.cj)
- `JoyHttpResponse`：HTTP响应封装，参见 [httpx/api.cj](../../src/httpx/api.cj)

### 请求类型支持

| 请求类型 | 支持状态 | 说明 |
|----------|----------|------|
| GET/POST/PUT/DELETE | ✅ | 标准HTTP方法 |
| JSON请求 | ✅ | 自动序列化/反序列化 |
| 表单请求 | ✅ | x-www-form-urlencoded |
| 文件上传 | ✅ | multipart/form-data |
| 自定义头 | ✅ | 完全控制请求头 |
| 超时设置 | ✅ | 连接和读取超时 |

---

## 一、基础使用

### 1.1 客户端创建与配置

```cangjie
import cjoy.httpx.*
import cjoy.httpx.auth.*

// 基础HTTP客户端
var client = JoyHttpClientService("https://api.example.com")

// 配置超时和证书处理
client = JoyHttpClientService("https://api.example.com", budilerFn: (url: String, verify: Bool) =>
    let cb = ClientBuilder()
    if (url.startsWith("https")) {
        var config = TlsClientConfig()
        if (!verify) {
            config.verifyMode = TrustAll
        }
        config.domain = URL.parse(url).hostName
        cb.tlsConfig(config)
    }
    let socketConnector = {
        sa: SocketAddress =>
            let socket = TcpSocket(sa)
            socket.readTimeout = Duration.minute
            socket.writeTimeout = Duration.minute
            socket.connect(timeout: Duration.minute)
            return socket
    }
    cb.readTimeout(Duration.minute)
    cb.connector(socketConnector)
)
```

### 1.2 服务注册与使用

```cangjie
import cjoy.*
import cjoy.httpx.*

main(): Int64 {
    let joy = Joy.default()
    
    // 注册HTTP客户端服务
    let client = JoyHttpClientService("https://jsonplaceholder.typicode.com")
    joy.addService("apiClient", client)
    
    joy.router.get("/users/{id}", {ctx: JoyContext =>
        // 从服务容器获取客户端
        let apiClient = ctx.getService<JoyHttpClient>("apiClient").getOrThrow()
        let userId = ctx.getParam("id") ?? "1"
        
        // 发送GET请求
        let response = apiClient.get(ctx, "/users/${userId}")
        
        if (response.status == 200) {
            let user = response.json<UserInfo>()
            ctx.json(user)
        } else {
            ctx.status(response.status).string("获取用户信息失败")
        }
    })
    
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 1.3 请求发送方式

#### GET请求
```cangjie
@Get[path = "/fetch"]
func fetchData(ctx: JoyContext): Unit {
    let client = ctx.getService<JoyHttpClient>("apiClient").getOrThrow()
    
    // 带查询参数的GET请求
    let queries = HashMap<String, String>([
        ("page", "1"),
        ("limit", "20"),
        ("search", "keyword")
    ])
    
    let response = client.get(ctx, "/users", queries: queries)
    
    if (response.status == 200) {
        ctx.json(response.json<Array<UserInfo>>())
    } else {
        ctx.status(response.status).json(ErrorResponse(
            message: "获取数据失败: ${response.status}"
        ))
    }
}
```

#### POST JSON请求
```cangjie
@Post[path = "/create"]
func createResource(ctx: JoyContext): Unit {
    let client = ctx.getService<JoyHttpClient>("apiClient").getOrThrow()
    
    let newResource = Resource(
        name: "New Resource",
        description: "Created via API"
    )
    
    // 自动JSON序列化
    let response = client.post(ctx, "/resources", body: newResource)
    
    if (response.status == 201) {
        let created = response.json<Resource>()
        ctx.status(201).json(created)
    } else {
        ctx.status(response.status).json(ErrorResponse(
            message: "创建失败: ${response.text}"
        ))
    }
}
```

#### 表单提交
```cangjie
@Post[path = "/submit"]
func submitForm(ctx: JoyContext): Unit {
    let client = ctx.getService<JoyHttpClient>("apiClient").getOrThrow()
    
    let formData = Form()
    form.add("username", "testuser")
    form.add("password", "testpass")
    form.add("remember", "true")

    // 表单编码提交
    let response = client.postForm(ctx, "/login", data: formData)
    
    if (response.status == 200) {
        let result = response.json<LoginResponse>()
        ctx.json(result)
    } else {
        ctx.status(response.status).string("登录失败")
    }
}
```

#### PUT/PATCH/DELETE
```cangjie
@Put[path = "/update/{id}"]
func updateResource(ctx: JoyContext): Unit {
    let client = ctx.getService<JoyHttpClient>("apiClient").getOrThrow()
    let resourceId = ctx.getParam("id") ?? ""
    
    let updateData = ResourceUpdate(
        name: "Updated Resource",
        version: 2
    )
    
    let response = client.put(ctx, "/resources/${resourceId}", body: updateData)
    
    if (response.status == 200) {
        ctx.json(response.json<Resource>())
    } else {
        ctx.status(response.status).json(ErrorResponse(
            message: "更新失败"
        ))
    }
}

@Delete[path = "/delete/{id}"]
func deleteResource(ctx: JoyContext): Unit {
    let client = ctx.getService<JoyHttpClient>("apiClient").getOrThrow()
    let resourceId = ctx.getParam("id") ?? ""
    
    let response = client.delete(ctx, "/resources/${resourceId}")
    
    if (response.status == 204 || response.status == 200) {
        ctx.status(204).string("删除成功")
    } else {
        ctx.status(response.status).json(ErrorResponse(
            message: "删除失败"
        ))
    }
}
```

## 二、认证与安全

### 2.1 Basic认证

```cangjie
@Post[path = "/basic-auth"]
func basicAuthExample(ctx: JoyContext): Unit {
    let baseClient = JoyHttpClientService("https://httpbin.org")
    
    // 添加Basic认证
    let authClient = BasicAuthClient(
        http: baseClient,
        username: "testuser",
        password: "testpass"
    )
    
    let response = authClient.get(ctx, "/basic-auth/user/pass")
    
    if (response.status == 200) {
        ctx.json(response.json<HashMap<String, String>>())
    } else {
        ctx.status(response.status).string("认证失败")
    }
}
```

### 2.2 Token认证

```cangjie
@Get[path = "/token-auth"]
func tokenAuthExample(ctx: JoyContext): Unit {
    let baseClient = JoyHttpClientService("https://api.example.com")
    
    // 添加Token认证
    let token = ctx.getHeader("Authorization")?.replace("Bearer ", "") ?? ""
    let authClient = TokenAuthClient(
        http: baseClient,
        token: token
    )
    
    let response = authClient.get(ctx, "/protected/profile")
    
    if (response.status == 200) {
        ctx.json(response.json<UserProfile>())
    } else {
        ctx.status(401).json(ErrorResponse(
            message: "Token无效或已过期"
        ))
    }
}
```

### 2.3 自定义认证

```cangjie
// 自定义认证客户端
class CustomAuthClient <: JoyHttpClient {
    private let _baseClient: JoyHttpClient
    private let _apiKey: String
    
    init(baseClient: JoyHttpClient, apiKey: String) {
        _baseClient = baseClient
        _apiKey = apiKey
    }
    
    public func get(ctx: JoyContext, path: String, queries: HashMap<String, String>, headers: HashMap<String, String>): JoyHttpResponse {
        var customHeaders = HashMap<String, String>()
        customHeaders.set("X-API-Key", _apiKey)
        customHeaders.set("X-Request-ID", generateRequestId())
        customHeaders.setAll(headers)
        
        let response = _baseClient.get(ctx, path, queries: queries, headers: customHeaders)
        
        // 处理认证失败响应
        if (response.status == 401) {
            // 尝试刷新Token
            let newToken = refreshToken()
            if (newToken != "") {
                customHeaders.set("Authorization", "Bearer ${newToken}")
                return _baseClient.get(ctx, path, queries: queries, headers: customHeaders)
            }
        }
        
        response
    }
    
    public func post(ctx: JoyContext, path: String, body: Any, queries: HashMap<String, String>, headers: HashMap<String, String>): JoyHttpResponse {
        var customHeaders = HashMap<String, String>()
        customHeaders.set("X-API-Key", _apiKey)
        customHeaders.setAll(headers)
        
        return _baseClient.post(ctx, path, body: body, queries: queries, headers: customHeaders)
    }
    
    public func put(ctx: JoyContext, path: String, body: Any): JoyHttpResponse {
        var customHeaders = HashMap<String, String>()
        customHeaders.set("X-API-Key", _apiKey)
        
        return _baseClient.put(ctx, path, body: body, headers: customHeaders)
    }
    
    public func delete(ctx: JoyContext, path: String): JoyHttpResponse {
        var customHeaders = HashMap<String, String>()
        customHeaders.set("X-API-Key", _apiKey)
        
        return _baseClient.delete(ctx, path, headers: customHeaders)
    }
    
    public func patch(ctx: JoyContext, path: String, body: Any): JoyHttpResponse {
        var customHeaders = HashMap<String, String>()
        customHeaders.set("X-API-Key", _apiKey)
        
        return _baseClient.patch(ctx, path, body: body, headers: customHeaders)
    }
    
    public func postForm(ctx: JoyContext, path: String, data: HashMap<String, String>): JoyHttpResponse {
        var customHeaders = HashMap<String, String>()
        customHeaders.set("X-API-Key", _apiKey)
        
        return _baseClient.postForm(ctx, path, data: data, headers: customHeaders)
    }
    
    private func refreshToken(): String {
        // Token刷新逻辑...
        "new_token_123"
    }
    
    private func generateRequestId(): String {
        "req_${DateTime.now().toUnixTimeStamp().toSeconds()}"
    }
}
```

## 三、高级功能

### 3.1 重试机制

```cangjie
@Post[path = "/retry-example"]
func retryExample(ctx: JoyContext): Unit {
    let baseClient = JoyHttpClientService("https://api.example.com")
    
    // 配置重试：最多3次重试，指数退避
    let retryClient = RetryClient(
        http: baseClient,
        maxRetries: 3,
        backoffStrategy: BackoffStrategy.Exponential,
        baseDelay: Duration.second * 1,
        maxDelay: Duration.second * 30
    )
    
    let response = retryClient.post(ctx, "/flaky-endpoint", body: HashMap<String, String>(
        ("action", "retry_test")
    ))
    
    if (response.status == 200) {
        ctx.json(SuccessResponse(
            message: "请求成功",
            attempts: retryClient.getLastAttempts()
        ))
    } else {
        ctx.status(response.status).json(ErrorResponse(
            message: "重试后仍然失败",
            attempts: retryClient.getLastAttempts()
        ))
    }
}
```

### 3.2 文件上传

```cangjie
@Post[path = "/upload-file"]
func uploadFile(ctx: JoyContext): Unit {
    let baseClient = JoyHttpClientService("https://api.example.com")
    
    // 读取文件
    let filePath = Path("./example.txt")
    if (!exists(filePath)) {
        ctx.status(400).string("文件不存在")
        return
    }
    
    try (file = File(filePath, OpenMode.Read)) {
        let fileContent = file.readToEnd()
        
        // 构建multipart请求
        let multipartData = JoyHttpMultiPart()
            .addText("description", "Example file upload")
            .addFile("file", "example.txt", "text/plain", fileContent.toUtf8ByteArray())
        
        let response = baseClient.postMultiPart(ctx, "/upload", body: multipartData)
        
        if (response.status == 200) {
            ctx.json(response.json<UploadResponse>())
        } else {
            ctx.status(response.status).json(ErrorResponse(
                message: "文件上传失败"
            ))
        }
    }
}
```

### 3.3 流式请求

```cangjie
@Get[path = "/stream-response"]
func streamResponse(ctx: JoyContext): Unit {
    let baseClient = JoyHttpClientService("https://api.example.com")
    
    // 配置流式响应处理
    let config = JoyHttpClientConfig()
    config.streamResponse = true
    
    let client = JoyHttpClientService("https://api.example.com", config: config)
    let response = client.get(ctx, "/large-data")
    
    if (response.status == 200) {
        // 处理流式响应
        let stream = response.getStream()
        var buffer = Array<Byte>(8192)
        var totalRead = 0
        
        while (true) {
            let readCount = stream.read(buffer)
            if (readCount <= 0) {
                break
            }
            
            totalRead += readCount
            
            // 处理读取的数据块...
            processStreamChunk(buffer[..readCount])
            
            if (totalRead % (1024 * 1024) == 0) {
                // 每1MB输出进度
                println("已读取: ${totalRead} bytes")
            }
        }
        
        ctx.json(SuccessResponse(
            message: "流式处理完成",
            totalBytes: totalRead
        ))
    }
}
```

### 3.4 响应处理

```cangjie
@Get[path = "/advanced-response"]
func advancedResponseExample(ctx: JoyContext): Unit {
    let client = ctx.getService<JoyHttpClient>("apiClient").getOrThrow()
    let response = client.get(ctx, "/complex-endpoint")
    
    // 获取响应状态码
    let statusCode = response.status
    println("状态码: ${statusCode}")
    
    // 获取响应头
    let contentType = response.header("Content-Type") ?? "unknown"
    let contentLength = response.header("Content-Length") ?? "unknown"
    println("Content-Type: ${contentType}")
    println("Content-Length: ${contentLength}")
    
    // 获取所有响应头
    let allHeaders = response.headers
    println("所有响应头:")
    for (key, value) in allHeaders) {
        println("  ${key}: ${value}")
    }
    
    // 处理JSON响应
    if (statusCode >= 200 && statusCode < 300) {
        if (contentType.contains("application/json")) {
            let data = response.json<ComplexResponse>()
            ctx.json(SuccessResponse(
                data: data,
                headers: allHeaders
            ))
        } else {
            let text = response.text
            ctx.json(SuccessResponse(
                data: text,
                type: "text"
            ))
        }
    } else {
        // 处理错误响应
        let errorText = response.text
        ctx.status(statusCode).json(ErrorResponse(
            code: "${statusCode}",
            message: errorText
        ))
    }
}
```

## 四、自定义扩展

### 4.1 拦截器模式

```cangjie
// 请求拦截器
class LoggingInterceptor <: JoyHttpClientInterceptor {
    public func intercept(request: JoyHttpRequest, next: HttpClientChain): JoyHttpResponse {
        println("发送请求: ${request.method} ${request.path}")
        
        let startTime = DateTime.now()
        let response = next.proceed(request)
        let duration = startTime.elapsedMilliseconds()
        
        println("收到响应: ${response.status}, 耗时: ${duration}ms")
        
        // 可以根据响应状态进行特殊处理
        if (response.status >= 500) {
            println("服务器错误，触发告警...")
            triggerAlert(request, response)
        }
        
        response
    }
}

// 使用拦截器的客户端
class InterceptedHttpClient <: JoyHttpClient {
    private let _baseClient: JoyHttpClient
    private let _interceptor: LoggingInterceptor
    
    init(baseClient: JoyHttpClient) {
        _baseClient = baseClient
        _interceptor = LoggingInterceptor()
    }
    
    public func get(ctx: JoyContext, path: String, queries: HashMap<String, String>, headers: HashMap<String, String>): JoyHttpResponse {
        let request = JoyHttpRequest(
            method: "GET",
            path: path,
            queries: queries,
            headers: headers
        )
        
        let chain = HttpClientChain(_baseClient)
        return _interceptor.intercept(request, chain)
    }
}
```

### 4.2 连接池管理

```cangjie
// 连接池客户端
class PooledHttpClient <: JoyHttpClient {
    private let _connectionPool: ConnectionPool
    private let _baseClient: JoyHttpClient
    
    init(baseUrl: String, poolSize: Int = 10) {
        _baseClient = JoyHttpClientService(baseUrl)
        _connectionPool = ConnectionPool(poolSize)
    }
    
    public func get(ctx: JoyContext, path: String, queries: HashMap<String, String>, headers: HashMap<String, String>): JoyHttpResponse {
        let connection = _connectionPool.getConnection()
        
        try {
            // 使用连接发送请求
            let response = _baseClient.get(ctx, path, queries: queries, headers: headers, connection: connection)
            _connectionPool.returnConnection(connection)
            return response
            
        } catch (e: Exception) {
            _connectionPool.returnConnection(connection)
            throw e
        }
    }
}
```

### 4.3 配置选项详解

```cangjie
// 完整配置示例
@Post[path = "/config-example"]
func configExample(ctx: JoyContext): Unit {
    let config = JoyHttpClientConfig()
    
    // 连接配置
    config.connectTimeout = Duration.second * 15
    config.readTimeout = Duration.minute * 2
    config.maxConnections = 100
    config.keepAlive = true
    config.keepAliveTimeout = Duration.second * 30
    
    // SSL/TLS配置
    config.trustAllCerts = false
    config.certFile = "/path/to/client.crt"
    config.keyFile = "/path/to/client.key"
    config.caFile = "/path/to/ca.crt"
    config.verifyHostname = true
    
    // 代理配置
    config.proxy = ProxyConfig(
        host: "proxy.example.com",
        port: 8080,
        username: "proxyuser",
        password: "proxypass"
    )
    
    // 重试配置
    config.retryConfig = RetryConfig(
        maxRetries: 5,
        baseDelay: Duration.second * 1,
        maxDelay: Duration.minute * 2,
        retryableStatusCodes: [500, 502, 503, 504],
        nonRetryableMethods: ["POST", "PUT", "DELETE"]
    )
    
    let client = JoyHttpClientService("https://api.example.com", config: config)
    let response = client.get(ctx, "/test")
    
    ctx.json(SuccessResponse(
        message: "配置客户端请求完成",
        status: response.status
    ))
}
```

## 五、性能优化与注意事项

### 5.1 性能优化策略

| 优化策略 | 说明 | 实现方式 |
|-----------|------|----------|
| **连接复用** | 复用HTTP连接减少握手开销 | 使用连接池或Keep-Alive |
| **并发控制** | 控制并发请求数量避免资源耗尽 | 设置合理的连接池大小 |
| **请求合并** | 将多个小请求合并为一个大请求 | 实现批量操作接口 |
| **缓存响应** | 缓存不常变化的响应数据 | 实现本地缓存机制 |
| **压缩传输** | 启用gzip压缩减少传输量 | 设置Accept-Encoding头 |

### 5.2 错误处理最佳实践

```cangjie
@Get[path = "/robust-request"]
func robustRequest(ctx: JoyContext): Unit {
    let client = ctx.getService<JoyHttpClient>("apiClient").getOrThrow()
    
    try {
        let response = client.get(ctx, "/data")
        
        match (response.status) {
            case 200..299 => 
                // 成功响应处理
                let data = response.json<ApiResponse>()
                ctx.json(SuccessResponse(data: data))
                
            case 400..499 => 
                // 客户端错误
                ctx.status(response.status).json(ErrorResponse(
                    code: "CLIENT_ERROR",
                    message: "请求参数错误: ${response.text}"
                ))
                
            case 500..599 => 
                // 服务器错误，可以重试
                ctx.status(503).json(ErrorResponse(
                    code: "SERVICE_UNAVAILABLE",
                    message: "服务暂时不可用，请稍后重试"
                ))
                
            case _ => 
                ctx.status(response.status).json(ErrorResponse(
                    code: "UNKNOWN_ERROR",
                    message: "未知错误"
                ))
        }
        
    } catch (e: NetworkException) {
        ctx.status(503).json(ErrorResponse(
            code: "NETWORK_ERROR",
            message: "网络连接失败: ${e.message}"
        ))
        
    } catch (e: TimeoutException) {
        ctx.status(408).json(ErrorResponse(
            code: "TIMEOUT_ERROR",
            message: "请求超时"
        ))
        
    } catch (e: Exception) {
        ctx.status(500).json(ErrorResponse(
            code: "INTERNAL_ERROR",
            message: "内部服务器错误: ${e.message}"
        ))
    }
}
```

### 5.3 注意事项

| 注意事项 | 说明 | 最佳实践 |
|----------|------|----------|
| **资源清理** | 确保连接和流正确关闭 | 使用try-with-resources或显式清理 |
| **超时设置** | 合理设置连接和读取超时 | 根据网络环境和业务需求调整 |
| **HTTPS证书** | 生产环境需要验证证书有效性 | 开发环境可适当放宽限制 |
| **重试策略** | 避免无限重试导致雪崩效应 | 实现指数退避和最大重试限制 |
| **监控日志** | 记录请求响应和性能指标 | 实现完整的请求链路追踪 |
| **并发限制** | 避免过多并发请求导致资源耗尽 | 根据服务能力设置合理并发数 |

---
 << [返回](../../README.md#使用指导)

----
<< [返回](../../README.md#使用指导)