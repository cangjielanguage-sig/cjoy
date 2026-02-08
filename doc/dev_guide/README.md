# 开发指南

## 代码结构

```
cjoy/
├── src/                     # 源代码目录
│   ├── framework/           # 核心框架层
│   │   ├── engine.cj       # 引擎核心（Joy, JoyConfig, JoyContext）
│   │   ├── route.cj        # 路由接口定义
│   │   ├── tree.cj         # 前缀树路由实现
│   │   ├── handler.cj      # 处理函数接口
│   │   └── macros/         # 路由处理宏
│   ├── ioc/                # IoC 容器实现
│   │   ├── factory.cj
│   │   ├── context.cj
│   │   └── macros/         # IoC 相关宏
│   ├── json/               # JSON 序列化/反序列化
│   │   ├── json_tool.cj
│   │   ├── json_schema.cj
│   │   └── macros/         # JSON 相关宏
│   ├── validation/         # 参数验证
│   │   ├── validation.cj
│   │   ├── constraint.cj
│   │   └── macros/         # 验证相关宏
│   ├── bind/               # 参数绑定
│   ├── log/                # 日志系统
│   ├── eventbus/           # 事件总线
│   ├── schedule/           # 调度任务
│   ├── mcp/                # MCP 服务
│   ├── middleware/         # 中间件实现
│   ├── session/            # 会话管理
│   ├── utils/              # 工具函数
│   └── test/               # 高层测试
├── examples/               # 示例项目
│   ├── src/
│   │   ├── simple/         # 简单示例
│   │   ├── macros/         # 宏使用示例
│   │   ├── rest/           # RESTful API 示例
│   │   └── tls/            # TLS 示例
├── doc/                    # 文档
├── testdata/               # 测试数据
└── cjpm.toml               # 项目配置
```

 - `src/framework`：框架代码
 - `src/macros`：Handler与Middleware的宏实现
 - `src/middleware`：中间件
 - `src/test`：测试
 - `src/json`：json序列化宏实现
 - `examples`：样例
 - `doc`：文档
  
原则：

 - 大的特性src目录下创建子目录，如`src/json`
 - 每个特性对外公共的API放API目录下，如`src/json/api`，若提供宏则放在`src/json/macros`
 - `src/test`放高层测试（HLT）代码，各目录下`*_test.cj`是内部类测试（LHT）代码
 - 宏定义与实现分离，如`src/json/macros/macros.cj`只定义宏，方便查看些模块有哪些宏，`src/json/macros/*.cj`为宏的解释与代码生成
 - 类尽可能不要定义为public，只对外暴露最小的API，比如一些实现辅助类就没有必要public
 - 没有必要一个cj文件只放一个类或接口，实现一个功能的类与其关联类可以放在一个文件中，但每个类要职责单一

## 项目结构深入了解

### 核心模块功能

#### 1. 框架核心 (`src/framework/`)
- `engine.cj`：引擎核心，负责管理 Web 服务器实例
- `route.cj`：路由接口定义，提供路由注册和管理方法
- `tree.cj`：前缀树路由实现，实现高效的路由匹配算法
- `handler.cj`：处理函数接口，定义请求处理和中间件接口
- `macros/`：路由处理宏，提供 `@Get`, `@Post`, `@Middleware` 等注解

#### 2. IoC 容器 (`src/ioc/`)
- `factory.cj`：Bean 工厂管理
- `context.cj`：应用上下文管理
- `macros/`：IoC 相关宏，提供 `@Component`, `@Controller`, `@Autowired` 等注解

#### 3. JSON 处理 (`src/json/`)
- `json_tool.cj`：JSON 工具类，提供对象和字符串之间的转换
- `json_schema.cj`：JSON 模式验证
- `macros/`：JSON 相关宏，提供 `@Json`, `@JsonField` 等注解

#### 4. 参数验证 (`src/validation/`)
- `validation.cj`：验证核心逻辑
- `constraint.cj`：约束定义
- `macros/`：验证相关宏，提供 `@Valid`, `@Size`, `@Email` 等注解

#### 5. 其他模块
- `bind/`：参数绑定工具
- `log/`：日志系统
- `eventbus/`：事件总线
- `schedule/`：调度任务
- `mcp/`：MCP 服务
- `middleware/`：中间件实现
- `session/`：会话管理
- `utils/`：工具函数

## 主要类与接口

### Web框架

从文件可以看到几大功能点与分层：

 - 引擎层
   - engine.cj：用于管理WebServer实例
     - 类Joy：引擎实例管理
     - 类JoyConfig：实例配置
 - 路由层
   - ntree.cj：路由路径树
     - 类TreeNode：压缩前辍树
    - route.cj：路径与Handler注册
      - 接口JoyRouters：路由管理接口
      - 类JoyRouteGroup：实现JoyRouters接口
      - 类TreeRouteDistributor：实现Cangjie SDK的HttpRequestDistributor与HttpRequestHandler接口，把所有请求路由给它做分发
 - 接口层：
   - handler.cj： Handler与Middleware接口定义
     - 类JoyRequestHandler：请求处理接口
     - 类JoyHandlers：请求处理类集合，用于宏生成的代码注册
     - 类JoyRequestHandlerChain：请求处理链
      - 类JoyMiddlewareHandler：请求中间件接口
      - 类JoyMiddlewares：中间件类集合，用于宏生成的代码注册
      - 类JoyMiddleware：中间件接口
   - context.cj：每次请求产生上下文
     - 类JoyContext：请求上下文
  - 渲染层：
    - render.cj：渲染接口定义，为以后支持其它格式的渲染扩展。目前Json与String由于简单，暂未采用实现JoyRender接口。

### Handler与Middleware宏

 - 宏定义
   - macros.cj
 - 宏解释与代码生成
    - ParamInfo：参数宏的解释与代码生成
    - FuncInfo：函数宏的解释与代码生成
    - MiddlewareInfo：中间件宏的解释与代码生成
  
原则：

 - 宏定义文件不要展开宏的解释，保持此文件的整洁
 - 内部提供函数对各个宏解释

## 测试用例写作指南

### 测试框架概述

CJoy 使用仓颉语言内置的单元测试框架，提供了完整的测试支持，包括：
- `@Test`：标记测试类
- `@TestCase`：标记测试方法
- `@BeforeAll`/`@AfterAll`：测试前后的设置和清理
- `@Assert`：断言方法
- `@Fail`：标记测试失败

### 测试文件结构

#### 1. 测试文件命名
- 内部类测试（LHT）：与源文件同目录，命名为 `{文件名}_test.cj`
- 高层测试（HLT）：放在 `src/test/` 目录下，命名为 `{功能}_test.cj`

#### 2. 测试类命名
测试类应使用 `TestCaseSuit` 后缀，遵循以下模式：
```cangjie
@Test
public class {功能}TestCaseSuit {
    // 测试方法
}
```

**示例**：
```cangjie
@Test
public class JwtTestCaseSuit {
    // JWT 相关测试方法
}

@Test
public class TreeNodeTestCaseSuit {
    // 路由树相关测试方法
}
```

#### 3. 测试方法命名
测试方法应使用 `test` 前缀，后跟具体功能描述：
```cangjie
@TestCase
public func test{功能描述}() {
    // 测试逻辑
}
```

**示例**：
```cangjie
@TestCase
public func testSignHS256() {
    // 测试 HS256 签名算法
}

@TestCase
public func testParseValidateFailExpire() {
    // 测试过期 token 验证失败
}
```

### 测试编写规范

#### 1. 测试分类
- **单元测试**：测试单个类或函数的功能
- **集成测试**：测试多个组件的交互
- **系统测试**：测试整个框架的功能

#### 2. 测试原则
- **独立性**：每个测试方法应独立运行，不依赖其他测试的状态
- **可重复性**：测试应在任何环境下都能产生相同的结果
- **清晰性**：测试代码应简洁易懂，便于维护
- **完整性**：覆盖所有正常和异常场景

#### 3. 常用测试模式

**基础断言模式**：
```cangjie
@TestCase
public func testBasicAssert() {
    let result = someFunction()
    @Assert(result, expectedValue)
}
```

**异常测试模式**：
```cangjie
@TestCase
public func testException() {
    try {
        someFunctionThatThrows()
        @Fail("应该抛出异常")
    } catch (ex: SomeException) {
        @Assert(ex.message.contains("预期错误信息"), true)
    }
}
```

**测试环境设置与清理**：
```cangjie
@Test
public class FrameworkTestCaseSuit {
    var _instance: ?Joy = None
    let _ctx = MapContext()
    let _client = JoyHttpClientService("http://127.0.0.1:18883/")

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.group("/api/v1")
            _instance = joy
            JoyHandlers.registerTo(joy)
            joy.run("127.0.0.1", 18883)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _client.destroy()
        _instance?.shutdown()
    }

    // 测试方法...
}
```

### 运行测试

CJoy 使用 `cjpm` 工具运行测试，支持多种运行方式：

#### 1. 运行所有测试
```bash
cjpm test
```

#### 2. 运行特定测试套件
```bash
cjpm test -i --filter={测试套件名}.*
```

**示例**：
```bash
cjpm test -i --filter=FileServerTestCaseSuit.*
```

#### 3. 运行单个测试用例
```bash
cjpm test -i --filter={测试套件名}.{测试方法名}
```

**示例**：
```bash
cjpm test -i --filter=FileServerTestCaseSuit.testStaticFile
```

### 测试最佳实践

1. **边界值测试**：测试参数的边界条件
2. **等价类划分**：将输入划分为等价类，每个等价类测试一次
3. **错误推测**：根据经验推测可能的错误场景
4. **代码覆盖率**：确保测试覆盖主要代码路径
5. **持续集成**：每次代码变更后运行测试

### 示例：HTTP 接口测试

```cangjie
@Test
public class FrameworkTestCaseSuit {
    var _instance: ?Joy = None
    let _ctx = MapContext()
    let _client = JoyHttpClientService("http://127.0.0.1:18883/")

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            JoyHandlers.registerTo(joy)
            joy.run("127.0.0.1", 18883)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _client.destroy()
        _instance?.shutdown()
    }

    @TestCase
    public func testOk() {
        let rsp = _client.get(_ctx, "/test_ok")
        assertResponse(rsp, "ok")
    }

    private func assertResponse(rsp: JoyHttpResponse, expected: String): Unit {
        @Assert(rsp.status, 200)
        @Assert(rsp.text, expected)
    }
}
```

### 补充说明

- 所有对外暴露的 API 都应该有对应的测试用例
- 测试代码应该与生产代码保持同步更新
- 提交代码时应该确保所有测试通过
- 避免在测试中使用硬编码的环境依赖

----
<< [返回](../../README.md)