# 事件总线

CJoy 提供内置轻量级事件总线，为应用提供基于事件的解耦通信机制，支持发布-订阅模式的事件处理。

## 概述

CJoy 事件总线系统基于以下核心概念设计：

- **发布订阅模式**：支持一个事件有多个订阅者，实现松耦合的事件驱动架构
- **优先级处理**：支持多个订阅者优先级，优先级越高越先触发
- **通配符匹配**：支持通过通配符 `*` 或 `**` 来订阅一组事件
- **多种发布模式**：支持同步、异步队列、异步线程三种事件发布方式
- **事件中止**：支持优先级高的订阅者中止事件传播
- **多级事件名称**：事件名称支持以英文点`.`分隔的多级名称

### 核心接口定义
- `EventBus`：事件总线接口，参见 [bus_api.cj](../../src/eventbus/bus_api.cj)
- `Event`：事件数据类，参见 [event.cj](../../src/eventbus/event.cj)
- `EventSubscriber`：事件订阅者接口，参见 [bus_api.cj](../../src/eventbus/bus_api.cj)
- `LocalEventBus`：本地事件总线实现，参见 [local_bus.cj](../../src/eventbus/local_bus.cj)

### 事件名称模式匹配规则

事件名称支持以英文点`.`分隔的多级名称，通配符匹配规则如下：

- `*` 只匹配一段非`.`的字符
- `**` 则匹配任意多个字符，并且只能用于开头或结尾

匹配示例：

| 模式 | 匹配示例 | 不匹配示例 |
|------|----------|------------|
| `"evt.some.*.*"` | `"evt.some.thing.run"`, `"evt.some.thing.do"` | `"evt.some.thing.extra.run"` |
| `"evt.some.*.run"` | `"evt.some.thing.run"` | `"evt.some.thing.do"` |
| `"evt.some.**"` | `"evt.some.thing.run"`, `"evt.some.thing.do.extra"` | `"evt.other.thing.run"` |
| `"**.thing.run"` | `"evt.some.thing.run"`, `"other.thing.run"` | `"evt.some.thing.do"` |

### 发布模式选择

| 模式 | 方法 | 适用场景 | 特点 |
|------|------|----------|------|
| **同步发布** | `fireEvent()` | 关注事件处理结果，如重要信息写文件、更新到Redis等 | 阻塞式，等待所有订阅者处理完成 |
| **异步队列** | `fireEventAsync()` | 事件处理非阻塞式场景，高并发事件处理 | 队列处理，队列满了会阻塞事件发布者 |
| **异步线程** | `asyncFireEvent()` | 事件处理耗时比较长但并发数不高的场景 | 每次创建新线程，不阻塞发布者 |

---

## 一、订阅者

### 1.1 @SubscribeEvent 宏订阅

使用宏标注是最便捷的订阅方式，CJoy框架会自动把订阅者函数注册给全局的EventBus服务。

```cangjie
import cjoy.*
import cjoy.macros.*

@SubscribeEvent[name = "sub1", pattern = "a.b.**"]
func handleEvent1(ctx: Context, evt: Event): Unit {
    // 处理事件
}
```

#### 宏属性参数

| 属性 | 默认值 | 是否可选 | 说明 |
|------|--------|----------|------|
| `name` | 函数名 | 是 | 订阅名称，用于标识和删除订阅 |
| `pattern` | - | 否 | 事件匹配模式，支持通配符 |
| `priority` | 0 | 是 | 优先级，数值越高优先级越高 |

#### 在IoC容器中使用

`@SubscribeEvent`宏可以配合IoC框架，在Bean组件的函数上使用：

```cangjie
@Component
class UserService {
    @SubscribeEvent[name = "userCreated", pattern = "user.created"]
    func handleUserCreated(ctx: Context, evt: Event): Unit {
        let userId = evt.getData<String>("userId") ?? ""
        // 处理用户创建事件
    }
}
```

### 1.2 接口注册订阅

直接调用EventBus接口注册订阅者，提供更灵活的控制。

#### 注册方法

```cangjie
// 获取EventBus实例
let bus = ctx.getService<EventBus>("eventbus").getOrThrow()

// 注册永久订阅者
bus.onEvent("user.created", "userHandler", {
    ctx: Context, evt: Event => 
    // 处理事件
}, [priority])

// 注册一次性订阅者
bus.onceEvent("user.deleted", "cleanupHandler", {
    ctx: Context, evt: Event => 
    // 处理事件，触发后自动注销
}, [priority])
```

#### 订阅者接口实现

```cangjie
class CustomSubscriber <: EventSubscriber {
    public func handle(ctx: Context, evt: Event): Unit {
        // 实现事件处理逻辑
    }
}

// 注册接口实现
let subscriber = CustomSubscriber()
bus.onEvent("order.placed", "orderHandler", subscriber, [100])
```

### 1.3 优先级与事件中止

#### 优先级常量

```cangjie
import cjoy.eventbus.EventConsts

// 内置优先级常量
EventConsts.PRIORITY_MIN      // -1000，最低优先级
EventConsts.PRIORITY_LOW      // -500，低优先级  
EventConsts.PRIORITY_NORMAL   // 0，普通优先级
EventConsts.PRIORITY_HIGH     // 500，高优先级
EventConsts.PRIORITY_MAX      // 1000，最高优先级
```

#### 优先级处理示例

```cangjie
// 高优先级订阅者
@SubscribeEvent[name = "validator", pattern = "order.*", priority = 500]
func validateOrder(ctx: Context, evt: Event): Unit {
    let isValid = validate(evt.getData<Order>("order") ?? Order())
    if (!isValid) {
        // 中止事件传播，低优先级订阅者不会收到此事件
        evt.abort()
        return
    }
}

// 低优先级订阅者
@SubscribeEvent[name = "processor", pattern = "order.*", priority = 0]
func processOrder(ctx: Context, evt: Event): Unit {
    // 只有验证通过且未被中止才会执行
    process(evt.getData<Order>("order") ?? Order())
}
```

### 1.4 回调函数签名

```cangjie
public type EventSubscriberFunc = (ctx: Context, evt: Event) -> Unit
```

**参数说明**：
- `ctx: Context`：上下文对象，可以在上下文中记录信息在事件处理过程中使用
- `evt: Event`：事件对象，获取事件名称和数据

**Event对象方法**：

| 方法 | 说明 |
|------|------|
| `name: String` | 获取事件名称 |
| `data: EventData` | 获取所有事件数据 |
| `isAborted: Bool` | 检查事件是否已被中止 |
| `addData(name: String, value: Any): Event` | 添加事件数据，支持链式调用 |
| `getData<T>(name: String): ?T` | 获取指定类型的事件数据 |
| `abort(): Event` | 中止事件传播，优先级低的订阅者不会收到此事件 |

## 二、发布者

### 2.1 在HTTP Handler中发布事件

在Http Handler或Middleware中使用，适合于收到Http请求时发布事件。

```cangjie
@Post[path = "/event"]
func handle(ctx: JoyContext): Unit {
    // 获取默认EventBus服务
    let bus = ctx.getService<EventBus>("eventbus").getOrThrow()
    
    // 创建事件并发布
    let event = Event.of("user.created")
        .addData("userId", "12345")
        .addData("userName", "张三")
    
    bus.fireEvent(ctx, event)
}
```

### 2.2 事件创建

```cangjie
// 基础事件创建
let event = Event.of("order.placed")

// 添加数据（支持链式调用）
let event = Event.of("order.placed")
    .addData("orderId", "ORD-001")
    .addData("amount", 100.50)
    .addData("userId", "user123")

// 获取事件数据
let orderId = event.getData<String>("orderId") ?? ""
let amount = event.getData<Float64>("amount") ?? 0.0

// 中止事件传播
event.abort()
```

### 2.3 三种发布方式

#### 同步发布

```cangjie
@Post[path = "/create-order"]
func createOrder(ctx: JoyContext): Unit {
    let bus = ctx.getService<EventBus>("eventbus").getOrThrow()
    
    // 同步发布，等待所有订阅者处理完成
    bus.fireEvent(ctx, [
        Event.of("order.created").addData("order", order),
        Event.of("notification.needed").addData("type", "email")
    ])
    
    ctx.json("订单创建成功")
}
```

#### 异步队列发布

```cangjie
@Post[path = "/async-process"]
func asyncProcess(ctx: JoyContext): Unit {
    let bus = ctx.getService<EventBus>("eventbus").getOrThrow()
    
    // 异步队列发布，不阻塞当前请求
    bus.fireEventAsync(ctx, [
        Event.of("data.processing").addData("dataId", "data-123"),
        Event.of("audit.log").addData("action", "process")
    ])
    
    ctx.json("请求已接收，正在异步处理")
}
```

#### 异步线程发布

```cangjie
@Post[path = "/heavy-task"]
func heavyTask(ctx: JoyContext): Unit {
    let bus = ctx.getService<EventBus>("eventbus").getOrThrow()
    
    // 异步线程发布，创建新线程处理
    bus.asyncFireEvent(ctx, [
        Event.of("heavy.computation").addData("taskId", "task-456")
    ])
    
    ctx.json("耗时任务已启动")
}
```

### 2.4 默认EventBus配置

每个Joy实例会默认注册一个名为`eventbus`的事件总线服务，其默认配置：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `queueSize` | 500 | 事件队列长度 |
| `consumerNum` | 20 | 消费线程数 |

## 三、服务管理

### 3.1 默认EventBus服务

内建的名为`eventbus`的EventBus服务，通常用于低时延的事件处理场景。

```cangjie
// 获取默认EventBus服务
let bus = ctx.getService<EventBus>("eventbus").getOrThrow()
```

### 3.2 自定义EventBus实例

如果应用存在高并发、长阻塞的事件处理场景，建议创建其他EventBus实例并注册为服务，可以指定合适的队列长度与消费者线程数参数。

```cangjie
main(): Int64 {
    let joy = Joy.default()
    
    // 创建自定义EventBus实例
    let highThroughputBus = LocalEventBus(
        queueSize: 1000,    // 更大的队列
        consumerNum: 50     // 更多的消费线程
    )
    
    // 注册为服务
    joy.addService("high_throughput_eventbus", highThroughputBus)
    
    // 注册订阅者到自定义EventBus
    highThroughputBus.onEvent("heavy.process.*", "processor", {
        ctx: Context, evt: Event =>
        // 处理耗时事件
    }, [EventConsts.PRIORITY_NORMAL])
    
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 3.3 使用自定义EventBus

```cangjie
@Post[path = "/heavy-process"]
func heavyProcess(ctx: JoyContext): Unit {
    // 使用自定义的EventBus服务
    let bus = ctx.getService<EventBus>("high_throughput_eventbus").getOrThrow()
    
    bus.fireEventAsync(ctx, [
        Event.of("heavy.process.start").addData("taskId", generateTaskId())
    ])
    
    ctx.json("处理任务已提交到高吞吐队列")
}
```

### 3.4 服务使用注意事项

- **宏标注限制**：采用`@SubscribeEvent`宏标注的函数只在默认的`eventbus`实例上生效
- **自定义实例订阅**：自定义EventBus实例注册订阅者需要调用`bus.onEvent`函数
- **服务命名**：建议使用描述性的服务名，如`"audit_eventbus"`、`"notification_eventbus"`等
- **资源隔离**：不同类型的事件可以使用不同的EventBus实例，避免相互影响

## 四、完整示例

### 4.1 用户注册流程示例

```cangjie
import cjoy.*
import cjoy.macros.*
import cjoy.eventbus.*
import cjoy.ioc.*
import cjoy.json.*

@Json
class User {
    var id: String = ""
    var name: String = ""
    var email: String = ""
}

@Component
class UserService {
    @SubscribeEvent[name = "userValidator", pattern = "user.register", priority = 100]
    func validateUser(ctx: Context, evt: Event): Unit {
        let user = evt.getData<User>("user") ?? User()
        if (user.email.isEmpty) {
            evt.abort()
            ctx.put("error", "邮箱不能为空")
            return
        }
        @JoyLogInfo("用户验证通过: ${user.name}")
    }
    
    @SubscribeEvent[name = "userSaver", pattern = "user.register", priority = 50]
    func saveUser(ctx: Context, evt: Event): Unit {
        let user = evt.getData<User>("user") ?? User()
        user.id = generateUserId()
        // 保存用户到数据库
        @JoyLogInfo("用户保存成功: ${user.id}")
        ctx.put("savedUser", user)
    }
    
    @SubscribeEvent[name = "notificationSender", pattern = "user.register", priority = 0]
    func sendWelcomeEmail(ctx: Context, evt: Event): Unit {
        let user = ctx.get("savedUser") as User ?? User()
        // 发送欢迎邮件
        @JoyLogInfo("欢迎邮件已发送: ${user.email}")
    }
    
    private func generateUserId(): String {
        "USER_" + DateTime.now().timestamp.toString()
    }
}

@Post[path = "/register", produce = "json"]
func register(ctx: JoyContext): (UInt16, HashMap<String, String>) {
    let user = ctx.getBody<User>() ?? User()
    let bus = ctx.getService<EventBus>("eventbus").getOrThrow()
    
    // 同步发布用户注册事件
    bus.fireEvent(ctx, [Event.of("user.register").addData("user", user)])
    
    if (let Some(error) <- ctx.get("error") as String) {
        return (400, HashMap<String, String>().set("error", error))
    }
    
    return (200, HashMap<String, String>().set("message", "注册成功"))
}

main(): Int64 {
    let joy = Joy.default()
    
    // 注册所有生成的handlers和middlewares
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 4.2 订单处理系统示例

```cangjie
import cjoy.*
import cjoy.eventbus.*
import cjoy.macros.*

// 高吞吐量订单EventBus
let orderEventBus = LocalEventBus(queueSize: 2000, consumerNum: 100)

// 订单验证订阅者
@SubscribeEvent[name = "orderValidator", pattern = "order.*", priority = 200]
func validateOrder(ctx: Context, evt: Event): Unit {
    let orderId = evt.getData<String>("orderId") ?? ""
    if (orderId.isEmpty) {
        evt.abort()
        @JoyLogError("订单ID为空")
    }
}

// 库存检查订阅者
@SubscribeEvent[name = "inventoryChecker", pattern = "order.created", priority = 150]
func checkInventory(ctx: Context, evt: Event): Unit {
    let productId = evt.getData<String>("productId") ?? ""
    let quantity = evt.getData<Int64>("quantity") ?? 0
    
    // 检查库存
    let hasStock = checkProductStock(productId, quantity)
    if (!hasStock) {
        evt.abort()
        @JoyLogError("库存不足: ${productId}")
    }
}

// 订单创建订阅者
@SubscribeEvent[name = "orderCreator", pattern = "order.created", priority = 100]
func createOrder(ctx: Context, evt: Event): Unit {
    let orderId = evt.getData<String>("orderId") ?? ""
    // 创建订单记录
    @JoyLogInfo("订单创建成功: ${orderId}")
}

// 异步处理订阅者
@SubscribeEvent[name = "asyncProcessor", pattern = "order.created", priority = 50]
func asyncProcessOrder(ctx: Context, evt: Event): Unit {
    let orderId = evt.getData<String>("orderId") ?? ""
    // 异步处理，如发送确认邮件、更新统计等
    @JoyLogInfo("异步处理订单: ${orderId}")
}

@Post[path = "/orders", produce = "json"]
func createOrder(ctx: JoyContext): String {
    let request = ctx.getBody<HashMap<String, String>>() ?? HashMap<String, String>()
    
    let orderId = generateOrderId()
    let orderEvent = Event.of("order.created")
        .addData("orderId", orderId)
        .addData("productId", request.get("productId") ?? "")
        .addData("quantity", Int64.parse(request.get("quantity") ?? "0") ?? 0)
    
    // 使用高吞吐量EventBus异步处理
    orderEventBus.fireEventAsync(ctx, [orderEvent])
    
    return orderId
}

main(): Int64 {
    let joy = Joy.default()
    
    // 注册自定义订单EventBus
    joy.addService("order_eventbus", orderEventBus)
    
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}

private func generateOrderId(): String {
    "ORD_" + DateTime.now().timestamp.toString()
}

private func checkProductStock(productId: String, quantity: Int64): Bool {
    // 模拟库存检查
    true
}
```

## 五、注意事项

### 5.1 模式匹配注意事项
- **通配符限制**：`**`只能用于模式的开始或结束位置
- **节点匹配**：`*`只能匹配单个`.`分隔的节点，不能匹配包含`.`的字符串
- **模式验证**：无效模式会抛出`EventBusException`异常

### 5.2 事件处理注意事项
- **事件中止**：高优先级订阅者调用`evt.abort()`后，低优先级订阅者不会收到此事件
- **上下文使用**：`Context`对象可以在事件处理过程中传递状态信息
- **异常处理**：订阅者中的异常不会影响其他订阅者的执行

### 5.3 性能优化注意事项
- **队列配置**：根据事件处理的并发量和处理时间调整`queueSize`和`consumerNum`
- **发布模式选择**：高并发场景使用异步发布，同步场景使用同步发布
- **EventBus隔离**：不同类型事件使用不同的EventBus实例，避免相互影响

### 5.4 最佳实践
- **事件命名**：使用有层次结构的事件名称，如`"user.created"`、`"order.paid"`
- **优先级设计**：验证类订阅者使用高优先级，处理类订阅者使用普通优先级
- **错误处理**：在订阅者中做好异常处理，避免影响其他订阅者
- **资源清理**：应用关闭时调用`closeAndWait()`等待所有异步事件处理完成

### 5.5 常见问题
- **Q: 宏标注的订阅者为什么不触发？**
  A: 确保调用了`JoyHandlers.registerTo(joy)`注册所有生成的handlers
  
- **Q: 事件处理为什么会阻塞？**
  A: 检查是否使用了同步发布模式，考虑改用异步发布
  
- **Q: 如何取消订阅？**
  A: 使用`bus.removeSubscriber(pattern, name)`方法取消指定订阅
  
- **Q: 事件丢失怎么办？**
  A: 检查队列是否满了，增加`queueSize`或使用更快的消费线程数

----
 << [返回](../../README.md#使用指导)