# 配置服务

CJoy 内置轻量配置服务，支持读取环境变量、命令行参数、属性配置文件、JSON 配置文件，以及自定义扩展的配置加载器甚至对接中心配置服务。

## 概述

CJoy 配置服务基于以下核心概念设计：

- **统一配置管理**：通过 `ConfigManager` 单例管理所有配置项
- **多级配置支持**：支持单值、数组、多级配置（如 `a.b.c.d`）
- **多源加载**：支持多种配置源，按优先级自动合并
- **配置绑定**：支持配置项绑定到对象，实现自动赋值
- **配置引用**：支持配置项之间相互引用，如 `${host}:${port}`
- **环境变量优先**：环境变量优先级最高，便于容器化部署
- **类型转换**：自动支持基本类型、数组、JSON 对象等类型转换

核心接口定义：
- `Config`：配置接口，参见 [conf_api.cj](../../src/config/conf_api.cj)
- `ConfigLoader`：配置加载器接口，参见 [conf_api.cj](../../src/config/conf_api.cj)

---

## 一、接口设计

### 1.1 Config 接口

```cangjie
public interface Config {
    // 判断配置项是否存在
    func hashKey(key: String): Bool

    // 获取配置项的值
    func getValue(key: String): ?String

    // 获取配置项的值（带默认值）
    func getValue(key: String, defaultValue: String): String

    // 绑定配置项到对象
    func bind<T>(key: String): ?T where T <: JoyBindable<T>

    // 解释配置引用表达式
    func resolve(exp: String): String

    // 添加配置加载器
    func addLoader(loaders: Array<ConfigLoader>): Unit
}
```

### 1.2 ConfigLoader 接口

```cangjie
public interface ConfigLoader {
    // 加载配置项到 Map
    func load(): Map<String, Any>

    // 优先级，数字越大优先级越高
    prop priority: Int
}
```

---

## 二、内置配置加载器

CJoy 内置以下配置加载器，按优先级从高到低排序：

| 加载器 | 优先级 | 说明 |
|---|---|---|
| 环境变量 | 最高 | 自动加载系统环境变量 |
| 命令行参数 | 50 | 通过 `-D` 参数加载 |
| JSON 配置文件 | 1 | JSON 格式配置文件 |
| Properties 配置文件 | 0 | Java Properties 格式配置文件 |

### 2.1 环境变量

自动加载系统环境变量，优先级最高，无需手动配置：

```cangjie
// 代码中直接引用环境变量
config.resolve(#"${HOME}"#)
```

### 2.2 命令行参数

通过 `-D` 参数指定配置，优先级为 50：

```bash
# 单值多级
./app -Da.b.c.d=1

# 数组多级
./app -Da.b.c[0]=0 -Da.b.c[1]=1
./app -Da.b[0].c=0 -Da.b[0].c=1

# 单值一级
./app -Dapp.address=127.0.0.1 -Dapp.port=18881

# 数组一级
./app -Dapp.users[0]=xiao -Dapp.users[1]=lanling
```

```cangjie
// main 函数接收命令行参数
func main(args: Array<String>): Int64 {
    let config = ConfigManager.INSTANCE
    config.addLoader(ArgConfigLoader(args))
    // ...
}
```

### 2.3 Properties 配置文件

Java Properties 格式配置文件，优先级为 0：

```properties
# joy.properties
server.address=127.0.0.1
server.port=18881
remote.ip-header=X-Forwarded-For
```

```cangjie
config.addLoader(PropertiesConfigLoader("./config/joy.properties"))
```

### 2.4 JSON 配置文件

JSON 格式配置文件，优先级为 1：

```json
{
  "server": {
    "address": "127.0.0.1",
    "port": 18881
  },
  "remote": {
    "ipHeader": "X-Forwarded-For"
  }
}
```

```cangjie
config.addLoader(JsonConfigLoader("./config/joy.json"))
```

---

## 三、配置名称规则

配置存储到内存中，会统一按如下规则转换：

- 大写字母转成下划线加小写
- 连续的大写只加一个下划线前缀

| 原始配置名 | 转换后 |
|---|---|
| `abCde` | `ab_cde` |
| `abCDe` | `ab_cde` |
| `AbCde` | `ab_cde` |

```cangjie
// 代码中使用
config.getValue("joy.server.address")

// 对应的命令行参数
./app -Djoy.server.address=127.0.0.1

// 对应的环境变量
export JOY_SERVER_ADDRESS=127.0.0.1
```

---

## 四、配置存储规则

配置通过 ConfigLoader 加载后，生成 `Map<String, Any>` 对象：

### 4.1 多级配置

多级配置按 `.` 分割，每一级创建一个 `Map<String, Any>`：

```cangjie
// 配置: a.b.c.d
// 存储结构:
// {
//   "a": {
//     "b": {
//       "c": {
//         "d": "value"
//       }
//     }
//   }
// }
```

### 4.2 数组配置

数组配置使用 `[]` 表示数组，数组元素存储为 `List<Any>`：

```cangjie
// 配置: a[0]=value1
// 存储结构:
// {
//   "a": ["value1"]
// }

// 配置: a[0]=value1, a[1]=value2
// 存储结构:
// {
//   "a": ["value1", "value2"]
// }
```

### 4.3 混合配置

```cangjie
// 配置: a[0].c=0, a[1].c=1
// 存储结构:
// {
//   "a": [
//     { "c": "0" },
//     { "c": "1" }
//   ]
// }
```

---

## 五、配置引用表达式

支持配置项之间相互引用，格式为 `#"${configName:default}"#`：

### 5.1 引用格式

| 格式 | 说明 |
|---|---|
| `#"${a.b.c.d}"#` | 单个配置引用 |
| `#"${app.address}:${app.port}"#` | 多个配置引用 |
| `#"${a.b.c.d:1234}"#` | 带默认值引用 |
| `#"${HOME}"#` | 引用环境变量 |

注意：表达式需要 `#"` 开头与 `"#` 结尾，或者使用单行字符串字面量表示法。

### 5.2 引用示例

```cangjie
// 引用单个配置
let dbUrl = config.resolve(#"${database.host}:${database.port}"#)

// 带默认值
let timeout = config.resolve(#"${request.timeout:5000}"#)

// 引用环境变量
let home = config.resolve(#"${HOME}"#)
```

---

## 六、使用方式

### 6.1 方式一：直接使用 API

在 Handler 中直接使用 Config API 获取配置：

```cangjie
@Get[path = "/config"]
func getConfig(ctx: JoyContext): String {
    // 获取 Config 服务
    let config = ctx.getService<Config>("config").getOrThrow()

    // 获取单个配置项
    let address = config.getValue("joy.server.address", "127.0.0.1")
    let port = config.bind<UInt16>("joy.server.port") ?? 18881

    config.resolve(#"${address}:${port}"#)
}
```

### 6.2 方式二：使用 @Value 宏注入

结合 IoC 框架，使用 `@Value` 宏自动注入配置值：

```cangjie
import cjoy.ioc.*
import cjoy.macros.*

@Component
class Bean1 {
    // 自动注入配置值
    @Value[#"${a.b.c:1}"#]
    let v1: Int

    @Value[#"${a.b.d:abc}"#]
    let v2: String

    @Value[#"${a.b.c:1}"#]
    let v3: ?Int

    @Value[#"${a.b.d:abc}"#]
    let v4: ?String
}
```

### 6.3 完整示例

```cangjie
import cjoy.*
import cjoy.macros.*
import cjoy.ioc.*
import cjoy.config.*
import cjoy.log.macros.*

@Component
class AppConfig {
    @Value[#"${joy.server.address:127.0.0.1}"#]
    let serverAddress: String

    @Value[#"${joy.server.port:18881}"#]
    let serverPort: UInt16

    @Value[#"${HOME:/tmp}"#]
    let homeDir: String
}

@JoyCreateLogger("examples.config")
@Get[path = "/config"]
func getConfig(ctx: JoyContext): String {
    // 获取 Config 服务
    let config = ctx.getService<Config>("config").getOrThrow()

    // 方式一：直接获取
    let address = config.getValue("joy.server.address")
    let port = config.getValue("joy.server.port")

    // 方式二：绑定到对象
    @JoyLogInfo("Server: ${address}:${port}")
    "Config loaded"
}

main(args: Array<String>): Int64 {
    // 加载配置
    let config = ConfigManager.INSTANCE

    // 添加命令行参数加载器
    config.addLoader(ArgConfigLoader(args))

    // 添加 Properties 配置文件
    config.addLoader(PropertiesConfigLoader("./config/joy.properties"))

    // 添加 JSON 配置文件
    config.addLoader(JsonConfigLoader("./config/joy.json"))

    // 创建 Joy 实例
    let joy = Joy.default()
    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 七、自定义扩展配置加载器

实现 `ConfigLoader` 接口，`load()` 方法返回 `Map<String, Any>`，并指定 `priority` 值。

### 7.1 自定义加载器示例

```cangjie
import cjoy.config.*
import std.collection.{HashMap, Map}
import std.fs.{File, OpenMode}
import std.io.StringReader

class YamlConfigLoader <: ConfigLoader {
    let filePath: String

    public YamlConfigLoader(filePath: String) {
        this.filePath = filePath
    }

    public func load(): Map<String, Any> {
        let data = HashMap<String, Any>()
        // 实现 YAML 解析逻辑
        try (fs: File = File(filePath, OpenMode.Read)) {
            var reader = StringReader(fs)
            while (let Some(line) <- reader.readln()) {
                // 解析 YAML 行
                let parts = line.split(":")
                if (parts.size == 2) {
                    let key = parts[0].trimAscii()
                    let value = parts[1].trimAscii()
                    data.add(key, value)
                }
            }
        }
        data
    }

    public prop priority: Int {
        get() {
            2  // 优先级高于 Properties，低于 JSON
        }
    }
}
```

### 7.2 中心配置服务示例

```cangjie
import cjoy.config.*
import std.net.Socket
import std.io.StringReader
import std.collection.HashMap

class ConsulConfigLoader <: ConfigLoader {
    let consulHost: String
    let consulPort: Int

    public ConsulConfigLoader(host: String, port: Int) {
        this.consulHost = host
        this.consulPort = port
    }

    public func load(): Map<String, Any> {
        let data = HashMap<String, Any>()
        // 从 Consul 中心配置服务拉取配置
        let url = "http://${consulHost}:${consulPort}/v1/kv/joy"
        // 使用 HTTP 客户端请求配置...
        data
    }

    public prop priority: Int {
        get() {
            100  // 最高优先级
        }
    }
}
```

使用自定义加载器：

```cangjie
main(args: Array<String>): Int64 {
    let config = ConfigManager.INSTANCE

    // 使用自定义加载器
    config.addLoader(YamlConfigLoader("./config/joy.yaml"))
    config.addLoader(ConsulConfigLoader("consul.example.com", 8500))

    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 八、配置绑定到对象

使用 `bind<T>()` 方法将配置项绑定到对象：

```cangjie
// 定义可绑定的对象
@Bind
class ServerConfig {
    @BindField[name = "address"]
    var address: String = ""

    @BindField[name = "port"]
    var port: Int = 0
}

@Bind
class DatabaseConfig {
    @BindField[name = "host"]
    var host: String = ""

    @BindField[name = "port"]
    var port: Int = 5432
}

// 绑定配置到对象
let serverConfig = config.bind<ServerConfig>("joy.server")
let dbConfig = config.bind<DatabaseConfig>("database")
```

---

## 九、注意事项

1. **优先级顺序**：环境变量 > 命令行参数 > JSON 文件 > Properties 文件 > 自定义加载器

2. **名称转换**：配置名自动转换为 snake_case，如 `JoyServerAddress` 转换为 `joy_server_address`

3. **循环引用**：不支持配置项之间的循环引用，会抛出 `ConfigException`

4. **类型安全**：`@Value` 宏只支持特定类型（String、基本类型、Option），使用其他类型会报错

5. **引用语法**：配置引用必须使用 `#"` 开头和 `"#` 结尾，或使用单行字符串字面量

6. **数组索引**：数组索引必须在 [0, 50] 范围内，超出范围会抛出异常

7. **配置绑定**：`bind<T>()` 需要对象使用 `@Bind` 注解并实现 `JoyBindable` 接口

8. **空值处理**：配置项不存在时返回 `None`，建议使用 `??` 提供默认值

9. **环境变量**：环境变量优先级最高，适合容器化部署时覆盖配置

10. **IoC 注入**：`@Value` 宏必须在 `@Component` 或 `@Controller` 注解的类中使用

---
<< [返回](../../README.md#使用指导)
