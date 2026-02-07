# IoC服务

CJoy 基于编译宏实现零反射的控制反转（Inversion of Control）框架，提供完整的依赖注入和生命周期管理。

## 概述

CJoy IoC框架基于以下核心概念设计：

- **零反射设计**：基于编译宏生成代码，运行时零性能损耗
- **依赖注入**：支持构造函数注入、接口注入、集合注入等多种模式
- **生命周期管理**：完整的Bean生命周期管理，包括初始化和销毁
- **作用域控制**：支持单例(Singleton)和原型(Prototype)两种作用域
- **接口扩展**：支持Bean实现接口并通过接口类型注入
- **配置集成**：支持配置值注入到Bean字段
- **控制器支持**：支持HTTP处理器的自动注册和管理

### 核心接口定义

| 接口 | 作用 | 参见 |
|------|------|------|
| `BeanLifecycle` | Bean生命周期接口，所有Bean自动实现 | [ioc_api.cj](../../src/ioc/ioc_api.cj) |
| `BeanFactory` | Bean工厂接口，负责创建Bean实例 | [ioc_api.cj](../../src/ioc/ioc_api.cj) |
| `ApplicationContext` | IoC容器接口，管理Bean实例 | [ioc_api.cj](../../src/ioc/ioc_api.cj) |
| `BeanFactoryManager` | Bean工厂管理器，管理全局工厂 | [factory.cj](../../src/ioc/factory.cj) |

### Bean作用域

| 作用域 | 说明 | 创建时机 |
|--------|------|----------|
| `SINGLETON` | 单例模式，整个应用只有一个实例 | 容器初始化时创建 |
| `PROTOTYPE` | 原型模式，每次请求都创建新实例 | 每次getBean时创建 |

### 依赖注入模式

| 注入方式 | 说明 | 示例 |
|--------|------|------|
| 按名称注入 | 通过Bean名称注入特定实现 | `@Autowired[name="userService"]` |
| 按类型注入 | 通过Bean类型自动注入 | `@Autowired` |
| 接口注入 | 注入接口的某个实现 | `service: UserService` |
| 集合注入 | 注入接口的所有实现 | `services: Array<UserService>` |
| 可选注入 | 注入可能不存在的Bean | `service: ?UserService` |

---

## 一、核心宏使用

### 1.1 @Component 宏

将类或结构体标记为Bean组件，支持依赖注入和生命周期管理。

#### 基本用法

```cangjie
import cjoy.ioc.*
import cjoy.macros.*

@Component
class UserService {
    public func getUser(id: String): String {
        "user_${id}"
    }
}
```

#### 完整属性配置

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` | String | 类名首字母小写 | Bean名称，用于依赖注入 |
| `scope` | String | `"singleton"` | Bean作用域：`"singleton"`或`"prototype"` |
| `extends` | Array<String> | `[]` | 实现的接口类型名数组 |

#### 作用域示例

```cangjie
// 单例Bean（默认）
@Component[scope = "singleton"]
class SingletonService {
    // 整个应用只有一个实例
}

// 原型Bean
@Component[scope = "prototype"]
class PrototypeService {
    // 每次注入都创建新实例
}
```

#### 接口扩展

```cangjie
interface DataRepository {
    func save(data: String): Unit
    func findById(id: String): ?String
}

@Component[extends = ["DataRepository"]]
class DatabaseRepository <: DataRepository {
    public func save(data: String): Unit {
        // 数据库保存逻辑
    }
    
    public func findById(id: String): ?String {
        // 数据库查询逻辑
        Some("data_${id}")
    }
}
```

### 1.2 @Autowired 宏

标记构造函数参数为需要注入的依赖。

#### 按类型注入

```cangjie
@Component
class OrderService {
    private let _userRepository: UserRepository
    private let _productService: ProductService
    
    init(userRepo: UserRepository, productService: ProductService) {
        _userRepository = userRepo
        _productService = productService
    }
}
```

#### 按名称注入

```cangjie
@Component
class PaymentService {
    private let _primaryProcessor: PaymentProcessor
    private let _secondaryProcessor: PaymentProcessor
    
    // 指定Bean名称注入
    init(@Autowired[name = "primaryPaymentProcessor"] primary: PaymentProcessor,
         @Autowired[name = "secondaryPaymentProcessor"] secondary: PaymentProcessor) {
        _primaryProcessor = primary
        _secondaryProcessor = secondary
    }
}

@Component[name = "primaryPaymentProcessor"]
class PrimaryPaymentProcessor <: PaymentProcessor {}

@Component[name = "secondaryPaymentProcessor"]
class SecondaryPaymentProcessor <: PaymentProcessor {}
```

#### 集合注入

```cangjie
@Component
class NotificationService {
    private let _channels: Array<NotificationChannel>
    
    // 注入所有NotificationChannel实现
    init(channels: Array<NotificationChannel>) {
        _channels = channels
    }
    
    public func sendNotification(message: String): Unit {
        for (channel in _channels) {
            channel.send(message)
        }
    }
}

@Component[extends = ["NotificationChannel"]]
class EmailNotification <: NotificationChannel {}

@Component[extends = ["NotificationChannel"]]
class SmsNotification <: NotificationChannel {}

@Component[extends = ["NotificationChannel"]]
class PushNotification <: NotificationChannel {}
```

#### 可选依赖注入

```cangjie
@Component
class OptionalService {
    private let _cacheService: ?CacheService
    
    // 可选注入，如果CacheService不存在也不会报错
    init(cacheService: ?CacheService) {
        _cacheService = cacheService
    }
    
    public func getData(key: String): String {
        match (_cacheService) {
            case Some(cache) => cache.get(key) ?? "default"
            case _ => "default"
        }
    }
}
```

### 1.3 @Value 宏

将配置值注入到Bean字段。

#### 基本语法

| 语法 | 说明 | 示例 |
|------|------|------|
| `#"${key:default}"#` | 带默认值的配置 | `#"${server.port:8080}"#` |
| `#"${key}"#` | 必须存在的配置 | `#"${server.host}"#` |

#### 使用示例

```cangjie
@Component
class AppConfig {
    @Value[#"${server.host:localhost}"#]
    let serverHost: String
    
    @Value[#"${server.port:8080}"#]
    let serverPort: Int
    
    @Value[#"${cache.enabled:true}"#]
    let cacheEnabled: Bool
    
    @Value[#"${cache.timeout:30}"#]
    let cacheTimeout: ?Int  // 可选配置项
    
    @Value[#"${app.version}"#]
    let appVersion: ?String // 必须配置项
}
```

#### 支持的数据类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `String` | 字符串类型 | `let name: String` |
| `Int64`, `Int32`, `Int16`, `Int8` | 整数类型 | `let port: Int` |
| `Float64`, `Float32` | 浮点类型 | `let rate: Float64` |
| `Bool` | 布尔类型 | `let enabled: Bool` |
| `Option<T>` | 可选类型 | `let timeout: ?Int` |
| `Option<String>` | 可选字符串 | `let version: ?String` |

### 1.4 @Controller 宏

将类标记为HTTP控制器，支持路由处理器自动注册。

#### 基本用法

```cangjie
@Controller[path = "/api"]
class UserController {
    @Get[path = "/users"]
    public func listUsers(ctx: JoyContext): Unit {
        ctx.json(["user1", "user2", "user3"])
    }
    
    @Get[path = "/users/{id}"]
    public func getUser(ctx: JoyContext, @PathParam id: String): Unit {
        ctx.json("user_${id}")
    }
}
```

#### 路径拼接规则

| 控制器路径 | 方法路径 | 最终路径 |
|-----------|----------|----------|
| `"/api"` | `"/users"` | `"/api/users"` |
| `"/api/v1"` | `"/users/{id}"` | `"/api/v1/users/{id}"` |
| `""` | `"/health"` | `"/health"` |

#### 完整控制器示例

```cangjie
@Json
class User {
    var id: String = ""
    var name: String = ""
    var email: String = ""
}

@Controller[path = "/users", name = "userController"]
class UserController {
    private let _users: HashMap<String, User> = HashMap()
    
    @Post[path = ""]
    public func createUser(ctx: JoyContext, @BodyParam user: User): Unit {
        _users.add(user.id, user)
        ctx.status(201).json(user)
    }
    
    @Get[path = "/{id}"]
    public func getUser(ctx: JoyContext, @PathParam id: String): Unit {
        match (_users.get(id)) {
            case Some(user) => ctx.json(user)
            case _ => ctx.status(404).string("User not found")
        }
    }
    
    @Put[path = "/{id}"]
    public func updateUser(ctx: JoyContext, @PathParam id: String, @BodyParam user: User): Unit {
        if (_users.contains(id)) {
            _users.add(id, user)
            ctx.json(user)
        } else {
            ctx.status(404).string("User not found")
        }
    }
    
    @Delete[path = "/{id}"]
    public func deleteUser(ctx: JoyContext, @PathParam id: String): Unit {
        if (_users.remove(id)) {
            ctx.status(204)
        } else {
            ctx.status(404).string("User not found")
        }
    }
}
```


## 二、生命周期管理

### 2.1 生命周期接口

所有Bean自动实现`BeanLifecycle`接口，提供生命周期钩子：

```cangjie
@Component
class LifecycleService {
    private var _initialized: Bool = false
    
    // Bean创建后调用
    public func afterInit(): Unit {
        _initialized = true
        // 执行初始化逻辑，如资源准备、连接池初始化等
        println("LifecycleService initialized")
    }
    
    // Bean销毁前调用
    public func beforeDestroy(): Unit {
        if (_initialized) {
            // 执行清理逻辑，如资源释放、连接关闭等
            println("LifecycleService destroying")
        }
    }
}
```

### 2.2 Bean创建顺序

框架根据依赖关系自动确定Bean创建顺序：

```cangjie
@Component
class ServiceA {
    init(serviceB: ServiceB, serviceC: ServiceC) {
        // 依赖于ServiceB和ServiceC
    }
}

@Component
class ServiceB {
    init(serviceD: ServiceD) {
        // 依赖于ServiceD
    }
}

@Component
class ServiceC {
    // 无依赖
}

@Component
class ServiceD {
    // 无依赖
}

// 创建顺序：ServiceC, ServiceD -> ServiceB -> ServiceA
```

### 2.3 初始化流程

```cangjie
main(): Int64 {
    // 1. 手动初始化IoC容器
    BeanFactoryManager.initAllBeans()
    
    // 应用逻辑...
    
    // 2. 程序退出前清理资源
    BeanFactoryManager.destroyAllBeans()
    return 0
}
```

### 2.4 后处理函数

注册在所有Bean初始化后执行的函数：

```cangjie
import cjoy.ioc.BeanFactoryManager

// 注册后处理函数
BeanFactoryManager.registerPostFunc("databaseMigration") {
    // 所有Bean初始化完成后执行
    println("Performing database migration...")
    migrateDatabase()
}

BeanFactoryManager.registerPostFunc("cacheWarmup") {
    // 缓存预热
    println("Warming up cache...")
    warmupCache()
}
```

## 三、IoC容器操作

### 3.1 获取ApplicationContext

#### 通过服务获取（推荐）

```cangjie
@Get[path = "/config"]
func getConfig(ctx: JoyContext): String {
    // 通过Joy服务获取IoC容器
    let appCtx = ctx.getService<ApplicationContext>("ioc").getOrThrow()
    let config = appCtx.getBean<AppConfig>()
    return config.serverHost
}
```

#### 全局获取

```cangjie
import cjoy.ioc.BeanFactoryManager

// 获取全局IoC容器
let appCtx = BeanFactoryManager.getApplicationContext()

// 按类型获取Bean
let userService = appCtx.getBean<UserService>()

// 按名称获取Bean
let primaryService = appCtx.getBean<PaymentProcessor>("primaryPaymentProcessor")

// 获取某个类型的所有Bean
let allRepositories = appCtx.getBeans<DataRepository>()
```

### 3.2 Bean获取方法

| 方法 | 说明 | 返回值 | 使用场景 |
|------|------|--------|----------|
| `getBean<T>()` | 按类型获取唯一Bean | `?T` | 确定只有一个实现时 |
| `getBean<T>(name: String)` | 按名称获取Bean | `?T` | 指定Bean名称时 |
| `getBeanByTypeName<T>(type: String)` | 按类型名获取Bean | `?T` | 动态类型名获取 |
| `getBeans<T>()` | 获取某个类型的所有Bean | `Collection<T>` | 接口多实现场景 |
| `getBeansByTypeName<T>(type: String)` | 按类型名获取所有Bean | `Collection<T>` | 动态类型名获取 |
| `getAllBeans()` | 获取所有Bean | `Collection<BeanLifecycle>` | 容器管理 |

### 3.3 动态Bean管理

```cangjie
@Component
class DynamicBeanManager {
    public func addCustomBean(ctx: ApplicationContext): Unit {
        // 动态添加Bean
        let customBean = CustomService()
        ctx.addBean("customService", "CustomService", customBean)
    }
    
    public func manageBeans(ctx: ApplicationContext): Unit {
        // 获取所有Bean信息
        let allBeans = ctx.getAllBeans()
        for (bean in allBeans) {
            println("Bean: ${bean}")
        }
        
        // 获取特定类型的Bean
        let services = ctx.getBeans<ServiceInterface>()
        println("Found ${services.size()} services")
    }
}
```

## 四、完整应用示例

### 4.1 分层架构示例

```cangjie
import std.collection.HashMap
import stdx.net.http.HttpStatusCode
import cjoy.*
import cjoy.ioc.*
import cjoy.macros.*

// 数据层
interface UserRepository {
    func findById(id: String): ?User
    func save(user: User): Unit
}

@Component[extends = ["UserRepository"], scope = "singleton"]
class DatabaseUserRepository <: UserRepository {
    private let _users: HashMap<String, User> = HashMap()
    
    public func findById(id: String): ?User {
        _users.get(id)
    }
    
    public func save(user: User): Unit {
        _users.add(user.id, user)
    }
}

// 服务层
@Component
class UserService {
    private let _userRepository: UserRepository
    private let _notificationService: NotificationService
    
    init(userRepo: UserRepository, notificationService: NotificationService) {
        _userRepository = userRepo
        _notificationService = notificationService
    }
    
    public func createUser(userData: User): User {
        _userRepository.save(userData)
        _notificationService.sendWelcomeEmail(userData.email)
        return userData
    }
}

// 控制层
@Controller[path = "/api"]
class UserController {
    private let _userService: UserService
    
    init(userService: UserService) {
        _userService = userService
    }
    
    @Post[path = "/users"]
    public func createUser(ctx: JoyContext, @BodyParam userData: User): Unit {
        try {
            let user = _userService.createUser(userData)
            ctx.status(201).json(user)
        } catch (e: Exception) {
            ctx.status(400).string(e.message)
        }
    }
}

// 配置类
@Component
class AppConfig {
    @Value[#"${app.name:CJoyApp}"#]
    let appName: String
    
    @Value[#"${app.version:1.0.0}"#]
    let appVersion: String
    
    public func afterInit(): Unit {
        println("Starting ${appName} v${appVersion}")
    }
}

main(): Int64 {
    let joy = Joy.default()
    
    // 注册所有生成的Handler
    JoyHandlers.registerTo(joy)
    
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 4.2 插件架构示例

```cangjie
// 插件接口
interface Plugin {
    func getName(): String
    func execute(context: String): String
}

// 插件实现
@Component[extends = ["Plugin"], name = "uppercasePlugin"]
class UppercasePlugin <: Plugin {
    public func getName(): String {
        "Uppercase Plugin"
    }
    
    public func execute(context: String): String {
        context.toUpper()
    }
}

@Component[extends = ["Plugin"], name = "lowercasePlugin"]
class LowercasePlugin <: Plugin {
    public func getName(): String {
        "Lowercase Plugin"
    }
    
    public func execute(context: String): String {
        context.toLower()
    }
}

// 插件管理器
@Component
class PluginManager {
    private let _plugins: Array<Plugin>
    
    init(plugins: Array<Plugin>) {
        _plugins = plugins
    }
    
    public func executePlugin(name: String, context: String): ?String {
        for (plugin in _plugins) {
            if (plugin.getName() == name) {
                return Some(plugin.execute(context))
            }
        }
        None
    }
    
    public func listPlugins(): Array<String> {
        _plugins |> map {p => p.getName()} |> collectArray
    }
}
```

## 五、使用注意事项

### 5.1 编译时约束

| 约束 | 说明 | 解决方案 |
|------|------|----------|
| **单构造函数** | 每个Bean只能有一个init构造函数 | 确保类定义只有一个init方法 |
| **名称唯一** | 所有Bean名称必须全局唯一 | 使用`name`属性指定不同名称 |
| **接口实现** | `@Component`必须真实实现声明的接口 | 确保extends数组中的接口都已实现 |
| **非原始类型** | `@Autowired`不能注入原始类型 | 使用包装类型或自定义类 |

### 5.2 依赖注入注意事项

#### 循环依赖检测

```cangjie
// ❌ 错误：循环依赖
@Component
class ServiceA {
    init(serviceB: ServiceB) {}  // 依赖B
}

@Component
class ServiceB {
    init(serviceA: ServiceA) {}  // 依赖A，形成循环
}

// ✅ 正确：使用接口解耦
interface ServiceBInterface {}

@Component
class ServiceA {
    init(serviceB: ServiceBInterface) {}  // 依赖接口
}

@Component[extends = ["ServiceBInterface"]]
class ServiceB <: ServiceBInterface {
    init(serviceA: ServiceA) {}  // 依赖具体实现
}
```

#### 可选依赖处理

```cangjie
@Component
class ServiceWithOptionalDep {
    init(requiredDep: RequiredService, optionalDep: ?OptionalService) {
        // requiredDep必须存在
        // optionalDep可能为None，需要处理
    }
    
    public func execute(): Unit {
        match (optionalDep) {
            case Some(service) => service.execute()
            case _ => println("Optional service not available")
        }
    }
}
```

### 5.3 作用域选择指南

| 场景 | 推荐作用域 | 原因 |
|------|-------------|------|
| 无状态服务 | `singleton` | 节省内存，线程安全 |
| 有状态对象 | `prototype` | 避免状态污染 |
| 数据源连接 | `singleton` | 连接池管理 |
| 请求作用域对象 | `prototype` | 每次请求新实例 |

### 5.4 性能优化建议

#### Bean懒加载

```cangjie
// ✅ 好的做法：按需获取Bean
@Component
class LazyService {
    public func processData(): String {
        // 只在需要时获取缓存Bean
        let appCtx = BeanFactoryManager.getApplicationContext()
        let cache = appCtx.getBean<CacheService>()
        return cache.getOrCompute("key", {=> "computed"})
    }
}

// ❌ 避免：在构造函数中注入不需要的Bean
@Component
class EagerService {
    init(cache: CacheService, logger: LoggerService, emailService: EmailService) {
        // 如果emailService很少使用，考虑按需获取
    }
}
```

#### 集合注入优化

```cangjie
@Component
class OptimizedService {
    private let _strategies: Array<Strategy>
    
    init(strategies: Array<Strategy>) {
        _strategies = strategies
    }
    
    public func executeStrategy(name: String, data: String): String {
        // ✅ 缓存策略查找结果
        let strategy = _strategies.find({s => s.getName() == name}) ?? getDefaultStrategy()
        strategy.execute(data)
    }
}
```

### 5.5 调试和监控

#### Bean创建日志

```cangjie
@Component
class DebugService {
    public func afterInit(): Unit {
        println("DebugService created at ${DateTime.now()}")
    }
    
    public func beforeDestroy(): Unit {
        println("DebugService destroyed at ${DateTime.now()}")
    }
}
```

#### 依赖关系分析

```cangjie
@Component
class DependencyAnalyzer {
    init(appCtx: ApplicationContext) {
        let allBeans = appCtx.getAllBeans()
        println("=== Bean Dependencies ===")
        for (bean in allBeans) {
            println("Bean: ${bean}")
        }
        println("Total beans: ${allBeans.size()}")
    }
}
```

### 5.6 常见问题和解决方案

**Q: 为什么Bean没有创建？**
A: 检查是否调用`BeanFactoryManager.initAllBeans()`，确认`@Component`或`@Controller`标注正确

**Q: 依赖注入失败怎么办？**
A: 检查Bean名称拼写、接口实现是否正确、是否存在循环依赖

**Q: 原型Bean获取到同一个实例？**
A: 确保使用`getBeanByTypeName()`方法获取，而不是`getBean()`

**Q: 如何测试Bean？**
A: 创建独立的ApplicationContext，注入Mock Bean进行单元测试

**Q: 配置注入不生效？**
A: 检查配置项是否存在、类型匹配、语法格式正确

### 5.7 最佳实践

1. **接口优先**：优先使用接口定义依赖，提高可测试性和可替换性
2. **依赖最小化**：只注入真正需要的依赖，避免过度耦合
3. **作用域明确**：根据Bean特性选择合适的作用域
4. **异常处理**：在依赖注入中妥善处理可选依赖和异常情况
5. **生命周期管理**：善用`afterInit()`和`beforeDestroy()`管理资源
6. **配置外部化**：使用`@Value`注解将配置外部化
7. **文档完善**：为复杂的Bean提供清晰的文档说明

---
 << [返回](../../README.md#使用指导)