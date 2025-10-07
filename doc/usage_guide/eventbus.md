# 事件总线

## EventBus

CJoy内置的轻量级的事件总线，为应用提供基于事件的解耦机制。

主要特性如下：

 - 支持一个事件有多个订阅者
 - 支持多个订阅者优先级，优先级越高越先触发
 - 支持通过通配符 *或** 来订阅一组事件
 - 支持事件同步，异步(队列与直接线程)发布

事件支持模式匹配，规则如下

 - `*` 只匹配一段非 . 的字符,可以进行更精细的匹配
 - `**` 则匹配任意多个字符,并且只能用于开头或结尾

 接口定义请参见EventBus

## 订阅者：

使用示例：[examples/eventbus](../../examples/src/eventbus/main.cj) 。

采用宏标注，CJoy框架会自动把订阅者函数注册给LocalEventBus.INSTANCE。

```
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

回调函数原型：

```
public type EventSubscriberFunc = (ctx: Context, evt: Event) -> Unit
```

 - 入参`ctx: Context`，可以在上下文中记录一些信息在下次回调时再使用。
 - 入参`evt: Event`, 获取事件的内容

## 发布者：

在Http Handler或Midlleware中使用，适合于收到Http请求时发布事件

```
@Post[path = "/crontab"]
func addCrontab(ctx: JoyContext): Unit {
    // 先根据服务名获取服务
    let bus = ctx.getService<EventBus>("eventbus").getOrThrow()
    bus.fireEvent(ctx, Event.of("e1").addData("k1", "v1"))
}
```

注：每个Joy实例会默认注册一个名为`eventbus`的事件总线服务。

## 服务

也可以创建其它的EventBus实例并注册为服务，可以指定构造参数:

```
let bus = LocalEventBus(queueSize: 200, consumerNum: 10)
joy.addService("xx_eventbus", bus)
```

注：自定义EventBus，注册订阅需要调用bus.onEvent函数，采用宏标注的函数只在默认实例上生效。

----
<< [返回](../../README.md#使用指导)