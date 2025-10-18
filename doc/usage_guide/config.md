# 配置服务

CJoy内置配置服务，支持读到环境变量，命令行参数，以及自己扩展的文件配置

## 框架

### 接口设计

主要提供配置访问Config接口

 - hashKey：判断配置项是否存在
 - getValue：获取配置项的值
 - bind：把配置项绑定一String，基本类型，或复杂类与结构体
 - resolve：解决配置引用表达式
 - addLoader：增加配置加载器

配置加载器ConfigLoader接口
 - load: 加载配置项
 - priority：优先级，数字越大优先级越高

### 内置实现

配置服务内置如下配置加载器

 - 环境变读取，它的优先级最高
 - 命令行参数，它的优先级为50，命令行参数的格式为-DconfigName=value，configName支持多级
   - 单值多级 
     - `-Da.b.c.d=1`
   - 数组多级
     - `-Da.b.c[0]=0 -Da.b.c[1]=1`
     - `-Da.b[0].c=0 -Da.b[0].c=1`
   - 单值一级
     - `-Dapp.address=127.0.0.1 -Dapp.port=18881`
   - 数组一级
     - `-Dapp.users[0]=xiao -Dapp.users[1]=lanling`

### 配置引用

支持配置表达式引用，格式为`#"${configName:default}"#`, 调用Config.resolve解释并获取值, 不存在插值返回为空字符串。注意需要`#"`开头与`"#`结尾或者其它的单行字符串字面量表示法，因为`${var}`与字符串插值相同。示例如下:

 - 单个配置引用：`#"${a.b.c.d}"#`
 - 多个配置引用：`#"${app.address}:${app.port}"#`
 - 带默认值引用：`#"${a.b.c.d:1234}"#`
 - 带默认值引用：`#"${app.address:127.0.0.1}:${app.port:18881}"#`

## 使用

需要调用Joy实例run之前，需要先把配置加载好，如下所示：

```cangjie
func main(args: Array<String>): Unit {
    // 加载命令行参数
    ConfigManger.INSTANCE.addLoder(ArgConfigLoader(args))
    // 加载自已扩展的配置加载器
    ConfigManger.INSTANCE.addLoder(JsonConfigLoader(args))
    //....
    joy.run("127.0.0.1", 18881)
}
```

方式1：结合IoC框架，采用@Value宏自动为Bean的成员变量注入

```cangjie
@Component
class Bean8 {
    @Value[#"${a.b.c:1}"#]
    let v1: Int // @Value会自动赋值

    @Value[#"${a.b.d:abc}"#]
    let v2: String

    @Value[#"${a.b.d:abc}"#]
    let v3: ?Int

    @Value[#"${a.b.d:abc}"#]
    let v4: ?String
}
```

方式2：使用API调用

每个Joy实例会自动注册一个名为`config`的Config服务，用户可以在任一Handler中使用

```cangjie
@Post[path = "/config"]
func handle(ctx: JoyContext): Unit {
    // 先根据服务名获取服务
    let config = ctx.getService<Config>("config").getOrThrow()
    // a开头的所有配置项绑定到对象
    let td = config.bind<TestData>("a")
    // 根据配置合名获取配置
    let val = config.getValue("a.b.c.d")
}
```

## 自定义扩展配置加载器

实现ConfigLoader接口，load方法返回`Map<String, Any>`，并指定优先级priority值。

注意，返回值`Map<String, Any>`需要内套`Map<String, Any>`或`List<Any>`，则配置项支持`a.b.c.d`这样的多级引用。

----
<< [返回](../../README.md#使用指导