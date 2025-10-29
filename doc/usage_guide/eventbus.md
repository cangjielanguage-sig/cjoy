# 事件总线

## EventBus

CJoy内置轻量级的事件总线，为应用提供基于事件的解耦机制。

主要特性如下：

 - 支持一个事件有多个订阅者
 - 支持多个订阅者优先级，优先级越高越先触发
 - 支持通过通配符 `*` 或 `**` 来订阅一组事件
 - 支持事件同步，异步(队列与直接线程)发布

事件名称支持以英文点`.`分隔的多级名称，其模式匹配规则如下

 - `*` 只匹配一段非`.`的字符
 - `**` 则匹配任意多个字符，并且只能用于开头或结尾

示例：

  - "evt.some.*.*"       -> 匹配 "evt.some.thing.run" "evt.some.thing.do"
  - "evt.some.*.run"     -> 匹配 "evt.some.thing.run", 但不能匹配 "evt.some.thing.do"
  - "evt.some.**"        -> 匹配以 "evt.some."结尾的事件， 比如："evt.some.thing.run" "evt.some.thing.do"
  - "**.thing.run"       -> 匹配以 ".thing.run"开头的事件， 比如："evt.some.thing.run"

同步适合场景：

 - 关注事件处理结果，比如重要信息写文件，更新到Redis等

异步适合场景：

 - 队列方式(发布事件调用fireEventAsync)，订阅者在指定的消费线程中处理，适合事件处理非阻塞式的场景，队列满了会阻塞事件发布者。
 - 线程方式(发布事件调用asyncFireEvent)，发布是每次创建新的线程，适合事件处理耗时比较长场景，但并发数并不高。

接口定义请参见 [EventBus](../../src//eventbus/api/api.cj) 。

## 订阅者

使用示例：[examples/eventbus](../../examples/src/eventbus/main.cj) 。

方式1：采用宏标注，CJoy框架会自动把订阅者函数注册给全局的EventBus服务。

```cangjie
@SubscribeEvent[name = "sub1", pattern = "a.b.**"]
func handleEvent1(ctx: Context, evt: Event): Unit {
}
```

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`|函数名|是|订阅名称|
|`pattern`||否|事件匹配模式|
|`priority`||是|优先级，默认为0|

注：宏@SubscribeEvent也可以配合IoC框架，在Bean上的函数上使用。

方式2： 调用接口注册订阅者

 - `bus.onEvent(...)`: 处理多次事件
 - `bus.onceEvent(...)`: 处理一次事件即注销

事件处理优先级，在注册订阅者，可以指定优先级，数字越高优先级越高

 - name: sub1, priority: 0
 - name: sub2, priority: 1

优先级高的订阅者在处理事件时，sub1可以调用事件的abort()方法，则优先级低的订阅者sub2不能再接收到此事件。

回调函数原型：

```cangjie
public type EventSubscriberFunc = (ctx: Context, evt: Event) -> Unit
```

 - 入参`ctx: Context`，可以在上下文中记录一些信息在下次回调时再使用。
 - 入参`evt: Event`, 获取事件的内容

## 发布者

在Http Handler或Midlleware中使用，适合于收到Http请求时发布事件。

```cangjie
@Post[path = "/event"]
func handle(ctx: JoyContext): Unit {
    // 先根据服务名获取服务
    let bus = ctx.getService<EventBus>("eventbus").getOrThrow()
    bus.fireEvent(ctx, Event.of("e1").addData("k1", "v1"))
}
```

注：每个Joy实例会默认注册一个名为`eventbus`的事件总线服务，其默认配置：

 - queueSize：事件队列长度，默认值为500
 - consumerNum：消费线程数，默认为20

## 服务

内建的名为`eventbus`的事件EventBus服务，通常用于一些低时延的事件处理。如果应用存在一些高并发，长阻塞的事件处理时，建议创建其它的EventBus实例并注册为服务，可以指定合适的队列长度与消费者线程数参数:

```cangjie
// 注册独立的事件总线服务
let bus = LocalEventBus(queueSize: 200, consumerNum: 10)
joy.addService("xx_eventbus", bus)

// 注册订阅者
bus.onEvent("a.b.c.d", "sub", {
    ctx: Context, evt: Event =>
    // 处理事件
})
```

注：自定义EventBus实例，注册订阅者需要调用`bus.onEvent`函数，采用宏标注的函数只在全局的实例上生效。

----
<< [返回](../../README.md#使用指导)