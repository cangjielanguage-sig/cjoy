# IoC服务

## 框架

CJoy零反射（基于编译宏）实现了控制反转(Inversion of Control)框架。IoC当前在**实验性探索**, 请大家积极反馈使用问题。

### 接口

IoC框架关键接口设计:

 - BeanLifecycle：所有管理类型称为Bean，宏生成Bean会自动实现此接口，接受生命周期管理
 - BeanFactory：每个Bean会自动生成对应的BeanFactory
 - ApplicationContext：IoC容器，管理所有Bean实例
 - BeanFactoryManager：管理所有Bean的BeanFactory

用户需要关注的方法：

 - BeanFactoryManager.getApplicationContext(): 获取全局的ApplicationContext
 - BeanFactoryManager.registerPostFunc(): 注册一些全局的后处理函数
 - BeanFactoryManager.executePostFuncs(): 执行注册的后处理函数
 
ApplicationContext:

 - getXXX(): 根据类型，名称获取对应的Bean对象
 - createAllBeans(): 创建所有Bean对象
 - destroyAllBeans(): 销毁所有Bean对象

单独使用IoC框架时，用户需要按如下使用流程操作：

 - 采用宏@Component标注一些类型，支持Class或Struct
 - 初始化所有Bean对象，调用ApplicationContext.createAllBeans()
    - 根据依赖关系逐一创建Bean
    - 调用Bean的afterInit()方法，用户可以自已重载此函数
 - 调用BeanFactoryManager.executePostFuncs()
 - ApplicationContext.getBean(): 按需获取Bean
 - 程序退出时之前，调用ApplicationContext.destroyAllBeans()

### 宏

IoC框架提供如下宏，用于生成BeanFactory实现，以及注释Bean信息。

|宏|属性参数|说明|
|---|---|---|
|`@Component`|name="",scope=singleton,extends=[]|Bean组件|
|`@Autowired`|name=""|依赖注入|
|`@Controller`|path="/abc/def",name="",scope=singleton,extends=[]|Bean组件，可以配合@Get，@Put HttpHandler宏使用|

以上宏属性参数说明： 

|宏属性参数|是否可选|说明|
|---|---|---|
|`name`|是|Component与Controller声明Bean名称，Autowired注入依赖Bean的名称。|
|`scope`|是|值为singleton或prototype。singleton为单例模式，prototype为原型模式，每次调用ApplicationContext.getBeanByTypeName会产生新的实例|
|`extends`|是|Component与Controller的属性，指定Bean可以发什么接口发布，被其它的Bean按些接口来引入依赖。|
|`path`|是|Controller的基础Path。|

框架目前只支持构造方法注入，并存在如下约束：

 - 所有Bean类型名称必须全局唯一
 - Bean类型**只能存在一个**构造init方法

示例1：@Autowired指定名称注入
```
@Component
class Bean1 {
    private let _bean2: Bean2
    init(@Autowired[name = "bean2"] b2: Bean2) {
        _bean2 = b2
    }
}

@Component[name = "bean2"]
class Bean2 {}
```

示例2：可选注入接口，接口未实现
```
interface Inter1 {}

@Component
class Bean3 {
    init(itner: ?Inter1) {
    }
}
```

示例3：Array注入接口多个实现
```
interface Inter2 {}

@Component[extends = ["Inter2"]]
class Bean4 <: Inter2 {}

@Component[extends = ["Inter2"]]
class Bean5 <: Inter2 {}

@Component
class Bean6 {
    init(arr: Array<Inter2>) {
    }
}
```

示例4：注入多个Bean，方法支持@Validated
```
@Component
class Bean7 {
    init(b6: Bean6, b1: Bean1) {
    }

    @Validated
    public func validate(@NotEmpty input: String): Unit {
    }
}
```

## @Controller

CJoy提供宏`@Controller`，用于标注在Http请求处理Bean，配合@Get, @Put等Handler宏标注在Bean上的函数，框架路由对应的请求到对应的处理函数。Bean上的@Get等宏函数参数与普通的函数使用@Get等宏相同。

使用示例：[examples/restioc](../../examples/src/restioc/main.cj) 。

使用流程：

 - 采用宏@Controller标注某类型，支持Class或Struct
 - 调用JoyHandlers.registerTo，让生成Handler自动注册到Joy实例了

 每个Joy实例会在JoyHandlers.registerTo或joy.run函数调用时，会自动调用如下函数

 - BeanFactoryManager.getApplicationContext().createAllBeans()
 - BeanFactoryManager.executePostFuncs()

`@Controller`有一个属性path，@Get等标注的函数生成Handler会拼接成完整的path。

 - @Controller[path="/users"]
 - @Get[path="${name}"]
 - 生成的GetHandler注册的path为`/users/{name}`

 ## 服务

每个Joy实例会自动注册一个名为`ioc`的ApplicationContext服务，用户可以在任一Handler中使用

```
func handle(ctx: JoyContext): Unit {
    let appCtx = ctx.getService<ApplicationContext>("ioc").getOrThrow()
    appCtx.getBean<XXX>("xx")
}
```

----
<< [返回](../../README.md#使用指导)