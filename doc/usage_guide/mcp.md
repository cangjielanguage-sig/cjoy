# MCP

CJoy 提供完整的MCP(Model Context Protocol)服务端支持，简化AI工具集成开发。

## 概述

CJoy MCP系统基于以下核心概念设计：

- **协议支持**：完整实现MCP 2025-03-26规范
- **传输层**：支持SSE和StreamableHttp两种传输协议
- **组件支持**：完整的Tool、Resource、Prompt三大组件
- **宏驱动**：通过注解自动生成MCP协议代码
- **类型安全**：编译时类型检查和自动转换
- **会话管理**：内置会话存储和状态管理
- **扩展性**：支持自定义认证和中间件扩展

### 协议版本支持

| 版本 | 支持状态 | 特性 |
|------|----------|------|
| 2025-03-26 | ✅ | 完整MCP规范实现 |

### 传输协议对比

| 协议 | 支持状态 | 优势 | 适用场景 |
|--------|----------|------|----------|
| SSE | ✅ | 实时通信、浏览器兼容 | Web应用、实时更新 |
| StreamableHttp | ✅ | 标准HTTP、易于调试 | 桌面应用、批量操作 |

### MCP功能支持矩阵

| 功能 | 支持状态 | 说明 |
|------|----------|------|
| Tool查询与调用 | ✅ | 核心工具功能 |
| Resource查询 | ✅ | 静态资源访问 |
| Resource模板 | ✅ | 动态资源生成 |
| Prompt查询 | ✅ | 模板化消息 |
| 列表变更监听 | ❌ | 暂不支持 |
| 订阅变更通知 | ❌ | 暂不支持 |
| 批量请求 | ❌ | 暂不支持 |

---

## 一、Tool开发

### 1.1 基础Tool定义

```cangjie
import cjoy.mcp.*
import cjoy.macros.*

// 简单计算工具
@Tool[name = "add", description = "Add two numbers and return the sum"]
public func add(
    @ToolParam[description = "The first number to add"] a: Int,
    @ToolParam[description = "The second number to add"] b: Int
): Int {
    a + b
}

// 字符串处理工具
@Tool[name = "concat", description = "Concatenate two strings"]
public func concatenate(
    @ToolParam[description = "First string"] str1: String,
    @ToolParam[description = "Second string"] str2: String
): String {
    str1 + str2
}

// 布验证的复杂工具
@Tool[name = "validateEmail", description = "Validate email address format"]
public func validateEmail(
    @ToolParam[description = "Email address to validate"] email: String
): ValidationResult {
    let pattern = Regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
    let isValid = pattern.matches(email)
    
    return ValidationResult(
        isValid: isValid,
        message: if (isValid) { "Valid email format" } else { "Invalid email format" },
        normalizedEmail: email.toLower()
    )
}
```

### 1.2 参数类型支持

| 参数类型 | 支持情况 | 示例 |
|----------|-----------|------|
| 基础类型 | ✅ | `Int`, `String`, `Bool`, `Float64` |
| `Option<T>` | ✅ | `Option<String>`, `Option<Int>` |
| `Array<T>` | ✅ | `Array<String>`, `Array<Int>` |
| `HashMap<K,V>` | ✅ | `HashMap<String, String>` |
| JsonSerializable | ✅ | 实现JsonSerializable的类 |
| JoyContext | ✅ | 用于获取HTTP上下文 |

### 1.3 复杂参数设计

```cangjie
// 使用数据类组合参数
@Json
class FileOperation {
    @JsonField[description = "File path to operate on"]
    public var path: String = ""
    
    @JsonField[description = "Operation type: read, write, delete"]
    public var operation: String = ""
    
    @JsonField[description = "File content for write operation"]
    public var content: String = ""
    
    @JsonField[description = "Operation options"]
    public var options: HashMap<String, String> = HashMap()
}

@Tool[name = "fileOperation", description = "Perform file system operations"]
public func fileOperation(operation: FileOperation): FileOperationResult {
    try {
        match (operation.operation) {
            case "read" => 
                let content = readFile(operation.path)
                return FileOperationResult(
                    success: true,
                    content: content,
                    operation: "read"
                )
                
            case "write" =>
                writeFile(operation.path, operation.content)
                return FileOperationResult(
                    success: true,
                    content: "",
                    operation: "write"
                )
                
            case "delete" =>
                deleteFile(operation.path)
                return FileOperationResult(
                    success: true,
                    content: "",
                    operation: "delete"
                )
                
            case _ =>
                return FileOperationResult(
                    success: false,
                    error: "Unsupported operation: ${operation.operation}"
                )
        }
        
    } catch (e: IOException) {
        return FileOperationResult(
            success: false,
            error: "File operation failed: ${e.message}"
        )
    }
}
```

### 1.4 错误处理最佳实践

```cangjie
// 自定义错误类型
enum ToolError {
    case InvalidParameter(String)
    case ExecutionFailed(String)
    case ResourceNotFound(String)
}

@Tool[name = "safeOperation", description = "Perform safe operations with proper error handling"]
public func safeOperation(
    @ToolParam[description = "Operation type"] operationType: String
): OperationResult {
    try {
        // 参数验证
        if (operationType.isEmpty) {
            throw ToolError.InvalidParameter("Operation type cannot be empty")
        }
        
        // 执行操作
        let result = performOperation(operationType)
        
        return OperationResult(
            success: true,
            result: result,
            message: "Operation completed successfully"
        )
        
    } catch (e: ToolError) {
        // 将业务错误转换为MCP兼容响应
        match (e) {
            case ToolError.InvalidParameter(msg) =>
                return OperationResult(
                    success: false,
                    error: "Invalid parameter: ${msg}"
                )
            case ToolError.ExecutionFailed(msg) =>
                return OperationResult(
                    success: false,
                    error: "Execution failed: ${msg}"
                )
            case ToolError.ResourceNotFound(msg) =>
                return OperationResult(
                    success: false,
                    error: "Resource not found: ${msg}"
                )
        }
        
    } catch (e: Exception) {
        return OperationResult(
            success: false,
            error: "Unexpected error: ${e.message}"
        )
    }
}
```

## 二、Resource开发

### 2.1 静态Resource

```cangjie
import cjoy.mcp.*
import cjoy.macros.*

// 配置信息Resource
@Resource[uri = "app://config", description = "Application configuration", name = "appConfig"]
public func getAppConfig(): AppConfig {
    AppConfig(
        appName: "CJoy Application",
        version: "1.0.0",
        debug: false,
        maxConnections: 100,
        databaseUrl: "postgresql://localhost:5432/mydb",
        cacheTimeout: 300
    )
}

// 日志文件Resource
@Resource[uri = "logs://application", description = "Application logs", mimeType = "text/plain"]
public func getApplicationLogs(): String {
    let logFile = Path("./logs/application.log")
    if (exists(logFile)) {
        try (file = File(logFile, OpenMode.Read)) {
            return file.readToEnd()
        }
    }
    return "No logs available"
}

// 系统状态Resource
@Resource[uri = "system://status", description = "Current system status"]
public func getSystemStatus(): HashMap<String, String> {
    let uptime = DateTime.now().toUnixTimeStamp() - systemStartTime
    let memoryUsage = getCurrentMemoryUsage()
    let diskSpace = getDiskSpaceInfo()
    
    return HashMap<String, String>(
        ["uptime": "${uptime} seconds"],
        ["memoryUsage": memoryUsage],
        ["diskSpace": diskSpace],
        ["status": "healthy"
    ])
}
```

### 2.2 动态Resource模板

```cangjie
// 用户特定数据Resource
@Resource[uri = "user://{userId}/profile", description = "User profile information"]
public func getUserProfile(
    @ResourceParam[description = "User ID"] userId: String,
    ctx: JoyContext
): UserProfile {
    // 从数据库获取用户信息
    let user = userRepository.getUserById(userId)
    
    // 检查用户权限（通过上下文获取认证信息）
    let isAuthenticated = ctx.getHeader("Authorization")?.isSome() ?? false
    if (!isAuthenticated && user.isPrivate) {
        throw AuthorizationError("Not authorized to access private profile")
    }
    
    return UserProfile(
        id: user.id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        preferences: user.preferences,
        lastLogin: user.lastLogin,
        isAccessible: isAuthenticated
    )
}

// 数据查询Resource
@Resource[uri = "data://{dataset}/query", description = "Query dataset information"]
public func queryDataset(
    @ResourceParam[description = "Dataset name"] dataset: String,
    @ResourceParam[default = "all", description = "Query fields"] fields: Array<String>,
    @ResourceParam[description = "Time range"] timeRange: String
): DatasetResult {
    // 验证数据集访问权限
    if (!hasDatasetAccess(getCurrentUser(), dataset)) {
        throw AuthorizationError("No access to dataset: ${dataset}")
    }
    
    let results = dataQueryEngine.query(dataset, fields, timeRange)
    
    return DatasetResult(
        dataset: dataset,
        queryTime: timeRange,
        fields: fields,
        results: results,
        count: results.size,
        truncated: results.size >= maxQueryResults
    )
}

// 报表生成Resource
@Resource[uri = "report://{type}/{format}", description = "Generate reports in different formats"]
public func generateReport(
    @ResourceParam[description = "Report type"] reportType: String,
    @ResourceParam[description = "Export format"] format: String
): ReportData {
    match (format) {
        case "json" => generateJsonReport(reportType)
        case "csv" => generateCsvReport(reportType)
        case "pdf" => generatePdfReport(reportType)
        case _ => throw ValidationError("Unsupported export format: ${format}")
    }
}
```

### 2.3 Resource权限控制

```cangjie
// 带权限检查的Resource
@Resource[uri = "secure://{resource}", description = "Secure resource with access control"]
public func getSecureResource(
    @ResourceParam[description = "Resource identifier"] resource: String,
    ctx: JoyContext
): SecureResourceData {
    // 获取用户权限级别
    let userRole = getUserRole(ctx)
    let resourceLevel = getResourceAccessLevel(resource)
    
    // 权限检查
    if (userLevel < resourceLevel) {
        throw AuthorizationError("Insufficient privileges to access resource: ${resource}")
    }
    
    // 获取敏感数据
    let sensitiveData = getSecureData(resource, userLevel)
    
    return SecureResourceData(
        resource: resource,
        accessLevel: resourceLevel,
        data: sensitiveData,
        auditLog: createAuditLog(ctx, resource, userRole)
    )
}
```

## 三、Prompt开发

### 3.1 简单Prompt模板

```cangjie
import cjoy.mcp.*
import cjoy.macros.*

// 问候Prompt
@Prompt[name = "greetUser", description = "Generate a greeting message for a user"]
public func greetUser(
    @PromptParam[description = "User name"] userName: String
): String {
    "Hello ${userName}! Welcome to CJoy application. How can I assist you today?"
}

// 代码解释Prompt
@Prompt[name = "explainCode", description = "Generate explanation for code snippets"]
public func explainCode(
    @PromptParam[description = "Code to explain"] code: String,
    @PromptParam[default = "javascript", description = "Programming language"] language: String
): String {
    "Please explain the following ${language} code:\n\n```\n${code}\n```\n\nProvide a clear explanation of what this code does, its structure, and any potential improvements."
}

// 任务引导Prompt
@Prompt[name = "taskGuide", description = "Provide step-by-step guidance for completing tasks"]
public func taskGuide(
    @PromptParam[description = "The task to complete"] task: String,
    @PromptParam[description = "User's experience level"] experience: String
): String {
    let guidance = match (experience) {
        case "beginner" => getBeginnerGuidance(task)
        case "intermediate" => getIntermediateGuidance(task)
        case "expert" => getExpertGuidance(task)
        case _ => getGeneralGuidance(task)
    }
    
    return "I'll help you complete this task step by step. Let's break it down:\n\n${guidance}"
}
```

### 3.2 复杂Prompt模板

```cangjie
// 带条件逻辑的Prompt
@Prompt[name = "conditionalPrompt", description = "Generate conditional responses based on context"]
public func conditionalPrompt(
    @PromptParam[description = "User query"] query: String,
    @PromptParam[description = "User context information"] context: HashMap<String, String>
): String {
    let hasPremium = context.get("hasPremium") == "true"
    let userLevel = context.get("level") ?? "basic"
    
    let basePrompt = "You are asking: ${query}."
    
    if (hasPremium) {
        return "${basePrompt}\n\nSince you have premium access, I can provide:\n- Detailed analysis\n- Advanced recommendations\n- Priority support"
    } else {
        return "${basePrompt}\n\nI can provide:\n- Basic assistance\n- General guidance\n- Helpful tips"
    }
}

// 多步骤交互Prompt
@Prompt[name = "interactivePrompt", description = "Multi-step interactive prompt"]
public func interactivePrompt(
    @PromptParam[description = "Initial request"] initialRequest: String
): Array<PromptMessage> {
    return [
        PromptMessage(
            role: "assistant",
            content: "I'll help you with: ${initialRequest}. First, I need some information."
        ),
        PromptMessage(
            role: "assistant", 
            content: "Could you please provide:\n1. What specific aspect are you interested in?\n2. What's your timeline?\n3. Any constraints I should know about?"
        ),
        PromptMessage(
            role: "assistant",
            content: "Once I have this information, I'll provide a tailored solution."
        )
    ]
}

// 动态内容生成Prompt
@Prompt[name = "dynamicContent", description = "Generate content based on multiple parameters"]
public func dynamicContent(
    @PromptParam[description = "Content type"] contentType: String,
    @PromptParam[description = "Target audience"] audience: String,
    @PromptParam[description = "Content tone"] tone: String
): String {
    let template = selectTemplate(contentType, audience, tone)
    return "Here's content for a ${contentType} targeting ${audience} with a ${tone} tone:\n\n${template}"
}
```

## 四、服务注册与配置

### 4.1 MCP服务注册

```cangjie
import cjoy.mcp.*
import cjoy.*

main(): Int64 {
    let joy = Joy.default()
    
    // 注册SSE模式
    McpServer.registerSseTo(joy, ssePath: "/sse", messagePath: "/mcp")
    
    // 或者注册StreamableHttp模式
    McpServer.registerStreamableTo(joy, path: "/mcp", isJsonResp: true)
    
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 4.2 认证集成

```cangjie
// 自定义认证中间件
class McpAuthMiddleware <: JoyMiddlewareFunc {
    public func handle(ctx: JoyContext, next: JoyMiddlewareFunc): Unit {
        let authHeader = ctx.getHeader("Authorization")
        
        // 验证API密钥
        if (!isValidApiKey(authHeader)) {
            ctx.status(401).json(ErrorResponse(
                error: "Unauthorized",
                message: "Invalid or missing API key"
            ))
            return
        }
        
        // 设置用户上下文
        ctx.put("userId", getUserIdFromKey(authHeader))
        
        next.handle(ctx)
    }
}

// 注册带认证的MCP服务
main(): Int64 {
    let joy = Joy.default()
    
    // 添加认证中间件
    joy.use(McpAuthMiddleware())
    
    // 注册MCP服务
    McpServer.registerStreamableTo(joy, path: "/mcp", isJsonResp: true)
    
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 4.3 配置管理

```cangjie
// MCP服务配置
@Component
class McpServerConfig {
    @Value[#"${mcp.server.name:CJoyServer}"#]
    public var serverName: String
    
    @Value[#"${mcp.server.version:1.0.0}"#]
    public var version: String
    
    @Value[#"${mcp.server.maxTools:100}"#]
    public var maxTools: Int
    
    @Value[#"${mcp.server.enableDebug:false}"#]
    public var enableDebug: Bool
    
    @Value[#"${mcp.server.allowedOrigins:*}"#]
    public var allowedOrigins: Array<String>
}

// 使用配置的服务启动
@Post[path = "/mcp/config"]
func updateConfig(ctx: JoyContext, @BodyParam config: McpServerConfig): Unit {
    // 验证配置
    if (!validateConfig(config)) {
        ctx.status(400).json(ErrorResponse(
            message: "Invalid configuration"
        ))
        return
    }
    
    // 更新配置（这里简化处理，实际应该持久化）
    updateServerConfig(config)
    
    ctx.json(SuccessResponse(
        message: "Configuration updated successfully"
    ))
}
```

## 五、最佳实践与注意事项

### 5.1 Tool开发最佳实践

| 实践 | 说明 | 示例 |
|------|------|------|
| **参数验证** | 验证所有输入参数 | 使用Option处理可选参数 |
| **错误处理** | 提供清晰的错误信息 | 返回结构化错误响应 |
| **幂等性** | 确保相同输入产生相同输出 | 避免副作用 |
| **性能优化** | 缓存重复查询结果 | 避免重复计算 |
| **文档完善** | 提供详细的参数和返回描述 | 便于AI理解和使用 |

### 5.2 Resource安全最佳实践

| 安全措施 | 说明 | 实现方式 |
|-----------|----------|----------|
| **权限检查** | 验证用户访问权限 | 结合认证中间件 |
| **数据脱敏** | 隐藏敏感信息 | 只返回必要字段 |
| **访问日志** | 记录资源访问记录 | 便于审计和监控 |
| **速率限制** | 限制访问频率 | 防止资源滥用 |
| **数据过滤** | 根据用户权限过滤数据 | 实现数据安全 |

### 5.3 Prompt设计原则

| 原则 | 说明 | 设计要点 |
|------|------|----------|
| **明确性** | 清晰表达需求 | 避免模糊和歧义 |
| **一致性** | 保持风格统一 | 使用相同的术语和格式 |
| **可控性** | 引导AI在正确方向 | 避免无关内容 |
| **可重用** | 设计通用模板 | 提高开发效率 |
| **用户友好** | 考虑用户体验 | 提供有用的上下文信息 |

### 5.4 性能优化建议

```cangjie
// 使用缓存优化Tool性能
@Component
class CachedToolService {
    private let _cache: ConcurrentHashMap<String, ToolResult>
    
    init(cacheService: CacheService) {
        _cacheService = cacheService
    }
    
    @Tool[name = "cachedData", description = "Get cached data with performance optimization"]
    public func getCachedData(
        @ToolParam[description = "Data key"] key: String
    ): ToolResult {
        // 先检查缓存
        if (let Some(cached) <- _cache.get(key)) {
            return cached
        }
        
        // 缓存未命中，执行计算
        let result = performExpensiveComputation(key)
        
        // 缓存结果
        _cache.add(key, result)
        
        return result
    }
}

// 批量处理优化
@Tool[name = "batchProcessor", description = "Process multiple items efficiently"]
public func batchProcess(
    @ToolParam[description = "Items to process"] items: Array<String>
): BatchResult {
    let results = ArrayList<ProcessResult>()
    
    // 分批处理，避免内存溢出
    let batchSize = 50
    for (i in 0..items.size step batchSize) {
        let batch = items[i..<i + batchSize]
        let batchResults = processBatch(batch)
        results.appendAll(batchResults)
    }
    
    return BatchResult(
        totalItems: items.size,
        processedItems: results.size,
        results: results
    )
}
```

### 5.5 注意事项

| 注意事项 | 说明 | 解决方案 |
|----------|------|----------|
| **参数限制** | MCP协议有参数限制 | 合理设计参数结构 |
| **响应大小** | 过大响应可能超时 | 控制返回数据量 |
| **并发处理** | 高并发访问共享资源 | 使用线程安全的数据结构 |
| **错误传播** | 避免敏感信息泄露 | 统一错误处理格式 |
| **版本兼容** | 协议变更考虑向后兼容 | 设计扩展性强的接口 |
| **监控日志** | 监控MCP服务状态 | 实现完整的可观测性 |


使用示例：[examples/mcpserver](../../examples/src/mcpserver/main.cj) 或者测试代码 [test/mcp_test](../../src/test/mcp_test.cj)。

#### Tool入参

参数的类型注释对于正确的工具功能至关重要：

- 为MCP协议生成准确的JSON Schema
- 告知LLM每个参数的预期数据类型

支持的类型：

 - 入参是实现stdx.encoding.json.stream包下JsonDeserializable接口的类型，以及基本类型，String等。
 - 入参宏`@ToolParam`可选，属性`name`默认取参数名，建议通过`@ToolParam(description:...)`来增强参数描述
 - 入参可以是可选参数，如`Option<类型>`，则Tool的Schema对应的参数也是可选
 - 入参还可以是JoyContext类型，用于获取HTTP上下文信息，不用`@ToolParam`标注

当工具的输入参数较多时，可以把多个参数聚合在一个类型中，如下所示：

```cangjie
@Json
public class Params {
    @JsonField[description = "number a"]
    public var a: Int
    @JsonField[description = "number b"]
    public var b: Int
}

@Tool[description = "add two number"]
public func add2(param: Params): Int {
    param.a + param.b
}

@Tool[description = "add two number"]
public func add3(param: Params, ctx: JoyContext): Int {
    param.a + param.b
}
```

示例中`add2`和`add3`与前面的`add`是等价的，有相同的MCP工具的inputSchema。

#### Tool出参

框架自动将函数返回的值转换为客户端的适当的MCP协议定义的Content格式：

 - 出参是实现ToString或JsonSerializable接口的类型，返回TextContent
 - 出参是`Array<ToString|JsonSerializable>`或`ArrayList<ToString|JsonSerializable>`类型，返回多个TextContent
 - 出参是cjoy.mcp.Image类型或`Array<Image>`或`ArrayList<Image>`，返回ImageContent
 - 出参是cjoy.mcp.Audio类型或`Array<Audio>`或`ArrayList<Audio>`，返回AudioContent
 - 调用函数出错，返回TextContent(isError=true, text="error message")

### Resource

静态Resource表示MCP客户端可以读取的数据或文件，动态ResourceTemplate通过允许客户端根据URI中传递的参数请求**动态**生成资源来扩展这一概念。

Resource为LLM或客户端应用程序提供对数据的只读访问，Resource允许LLM访问与对话相关的文件、数据库内容、配置或动态生成的信息。当客户端请求资源URI时：
- CJoy找到相应的资源定义，路由到对应的函数
- 如果它是动态Resource（由函数定义），该提取URI中参数
- 返回对应的内容（文本、JSON、二进制数据）给调用者

Cjoy提供`@Resource`宏标注函数，发布为MCP中静态与动态Resource。

```cangjie
@Resource[uri = "data://secret"]
public func secretData(): String {
    "secret data"
}

@Resource[uri = "resource://{name}/detail"]
public func systemStatus(ctx: JoyContext, name: String): HashMap<String, String> {
    HashMap<String, String>([("name", name)])
}
```

宏与宏属性说明：

|宏|属性参数|说明|
|---|---|---|
|`@Resource`|uri:"..", name="..", description:"..",mimeType:""|作用于函数上。`name`默认函数名|
|`@ResourceParam`|name="..", description:"..", default:""|作用函数参数上。`@ResourceParam`可选，`name`默认取参数名|

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`uri`||否|指定资源的URI，格式如resource://{name}/detail，其中{name}动态参数变量|
|`name`||是|指定资源的名称|
|`description`||是|用于描述资源，为了大模型更好的效果，描述应简洁清楚无歧义|
|`mimeType`||是|资源的类型|
|`default`||是|参数默认值|

使用示例：[examples/mcpserver](../../examples/src/mcpserver/main.cj) 或者测试代码 [test/mcp_test](../../src/test/mcp_test.cj)。

#### Resource入参

函数支持的入参

 - 可以是JoyContext类型，用于获取HTTP上下文信息
 - 当是动态Resource，绑定URI中参数，参数名为URL中变量，入参为基础类型，String
  
```cangjie
@Resource[uri = "resource://{name}/detail"]
public func systemStatus(ctx: JoyContext, name: String): HashMap<String, String> {
    // name参数是URI中的{name}
    HashMap<String, String>([("name", name)])
}
```

#### Resource出参

框架自动将函数返回的值转换为客户端的适当的MCP协议定义的ResourceContents格式：

 - 出参是实现ToString接口的类型，返回TextResourceContents(mimeType="text/plain")
 - 出参是实现JsonSerializable接口的类型，返回TextResourceContents(mimeType="application/json")
 - 出参是`Array<ToString|JsonSerializable>`或`ArrayList<ToString|JsonSerializable>`类型，返回多个TextResourceContents
 - 出参是HashMap类型，返回TextResourceContents(mimeType="application/json")
 - 出参是`Array<Byte>`类型，返回BlobResourceContents(mimeType="application/octet-stream")，对响应进行Base64编码
 - 当出参非上述类型，返回TextResourceContents(mimeType="ext/plain"), 内容为空
 - 返回XXXResourceContents优先取@Resource指定的mimeType值，不存在则取上述默认值

### Prompt

Prompt是可重用的消息模板，可帮助LLM生成结构化、有目的的响应。当客户端请求Prompt时：

 - CJoy找到相应的Prompt定义
 - 如果它有参数，提取参数
 - 生成的消息将返回给LLM以指导其响应
 - 允许您定义一致的、可重用的模板，LLM可以在不同的客户端和上下文中使用这些模板


CJoy提供`@Prompt`宏标注函数，发布为MCP中Prompt。

```cangjie
@Prompt[name = askUserTopic]
public func askUserTopic(topic: String): String {
    "Can you please explain the concept of ${topic}"
}

@Prompt[name = analyze_data_request, description = "Creates a request to analyze data with specific parameters"]
public func dataAnalysisPrompt(
    @PromptParam[description = "The URI of the resource containing the data."] dataUri: String,
    @PromptParam[default = "summary", description = "Type of analysis."] analysisType: String
): String {
    "Please perform a '${analysisType}' analysis on the data found at ${dataUri}."
}
```

宏与宏属性说明：

|宏|属性参数|说明|
|---|---|---|
|`@Prompt`|name="..", description:".."|作用于函数上。`name`默认函数名|
|`@PromptParam`|name="..", description:"..", default:""|作用函数参数上。`@PromptParam`可选，`name`默认取参数名|

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`||是|指定Prompt或参数的名称|
|`description`||是|用于描述Prompt或参数，描述应简洁清楚无歧义|
|`default`||是|参数默认值|

使用示例：[examples/mcpserver](../../examples/src/mcpserver/main.cj) 或者测试代码 [test/mcp_test](../../src/test/mcp_test.cj)。

#### Prompt入参

函数支持的入参

 - 可以是JoyContext类型，用于获取HTTP上下文信息
 - 可以为基础类型，String
 - 可以为Option<类型>
  
#### Prompt出参

框架自动将函数返回的值转换为客户端的适当MCP定义格式：

 - 出参是实现ToString接口的类型，返回PromptMessage.TextContent
 - 出参是实现JsonSerializable接口的类型，返回PromptMessage.TextContent
 - 出参是`Array<ToString|JsonSerializable>`或`ArrayList<ToString|JsonSerializable>`类型，返回多个PromptMessage.TextContent
 - 出参是HashMap类型，返回TextContent
 - 出参是`cjoy.mcp.Message`类型，返回PromptMessage.TextContent
 - 出参是`Array<Message>`或`ArrayList<Message>`类型，返回多个PromptMessage.TextContent
 - 出参是`cjoy.mcp.PromptMessage`类型，返回PromptMessage
 - 出参是`Array<PromptMessage>`或`ArrayList<PromptMessage>`类型，返回多个PromptMessage
 - 当出参没有指定role时，默认是role=assistant

### 注册

目前传输层支持SSE与StreamableHttp协议，如下示例为把MCP注册到HTTP服务实例接口上：

```cangjie
let joy = Joy.create(cfg)
// 注册到Http实例上
McpServer.registerSseTo(joy)
McpServer.registerStreamableTo(joy, isJsonResp: true)
joy.run("127.0.0.1", 18881)
```

SSE方式，`McpServer.registerSseTo`支持把MCP的函数自动注册到服务实例上，有如下参数：

 - joy: 服务实列
 - ssePath：接收sse的PATH，默认为`/sse`
 - messagePath: 接收MCP消息的Path，默认为`/messages`

StreamableHttp方式，`McpServer.registerStreamableTo`支持把MCP的函数自动注册到服务实例上，有如下参数：

  - joy: 服务实例
  - path：接收MCP消息的Path，默认为`/mcp`
  - isJsonResp: 响应采用Json方式代替SSE方式

注：目前只支持isJsonResp=true

## 客户端

客户端仅仅用于测试，示例如下：

```cangjie
main(): Int64 {
    // 创建McpSseClient
    try(client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
        // 会话协商
        let _ = client.initialize()
        // 查询工具
        let _ = client.listTools()
        // 调用工具
        let _ = client.callTool(CallToolRequest(name: "add", arguments: HashMap<String, Int64>([("a", 1), ("b", 2)])))
        let _ = client.callTool(CallToolRequest(name: "multiply", arguments: HashMap<String, Int64>([("a", 2), ("b", 3)])))
    } 
    return 0
}
```

使用示例：[examples/mcpclient](../../examples/src/mcpclient/main.cj) 。

可以使用Python的fastmcp客户端来对接CJoy开发的MCP服务端 [examples/mcpclient/client.py](../../examples/src/mcpclient/client.py) 。

----
<< [返回](../../README.md#使用指导)