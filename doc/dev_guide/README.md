# 开发指南

## 代码结构

```
.
├── CHANGELOG.md
├── cjpm.lock
├── cjpm.toml
├── LICENSE
├── README.md
└── src
    ├── framework
    |   ├── chunked.cj
    |   ├── context.cj
    |   ├── engine.cj
    |   ├── handler.cj
    |   ├── ntree.cj
    |   ├── render.cj
    |   ├── route.cj
    |   ├── *_test.cj
    ├── json
    │   ├── macros
    │   │   ├── *.cj
    │   ├── jsonm.cj
    │   └── api
    │       └── *.cj
    ├── macros
    │   └── macros.cj
    │   └── *.cj
    ├── middleware
    │   ├── *.cj
    └── test
    │    ├── *_test.cj
├── examples
│   ├── README.md
│   ├── chuncked
│   ├── macros
│   ├── rest
│   ├── simple
│   ├── sse
│   └── tls
├── doc
│   ├── dev_guide
│   ├── usage_guide
│   └── imgs
│       └── *.png
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
 - `src/test`放全局测试（HLT）代码，各目录下`*_test.cj`是内部类测试（LHT）代码
 - 宏定义与实现分离，如`src/json/macros/macros.cj`只定义宏，方便查看些模块有哪些宏，`src/json/macros/*.cj`为宏的解释与代码生成
 - 类尽可能不要定义为public，只对外暴露最小的API，比如一些实现辅助类就没有必要public
 - 没有必要一个cj文件只放一个类或接口，实现一个功能的类与其关联类可以放在一个文件中，但每个类要职责单一

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

### Json

Json的序列化与反序列化基于`encoding.json.stream`接口，提供宏对类与Struct进行标注，生成其接口实现。

 - 宏定义
   - jsonm.cj
 - 宏解释与代码生成
   - macros
     - JsonClassInfo：Json类宏的解释与代码生成
     - JsonFieldInfo：JsonField宏的解释与代码生成
   - api
     - JsonTool：对象<->String互转辅助类

----
<< [返回](../../README.md)