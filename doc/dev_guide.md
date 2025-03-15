开发指导
-----

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
    │   ├── generate
    │   │   ├── *.cj
    │   ├── jsonm.cj
    │   └── utils
    │       └── *.cj
    ├── macros
    │   ├── generate
    │   │   ├── *.cj
    │   └── macros.cj
    ├── middleware
    │   ├── *.cj
    └── test
        ├── *_test.cj
├── doc
│   ├── dev_guide.md
│   └── imgs
│       └── *.png
├── examples
│   ├── README.md
│   ├── chuncked
│   ├── macros
│   ├── rest
│   ├── simple
│   ├── sse
│   └── tls
```

 - `src/framework`：框架代码
 - `src/macros`：Handler与Middleware的宏实现
 - `src/middleware`：中间件
 - `src/test`：测试
 - `src/json`：json序列化宏实现
 - `doc`：文档
 - `examples`：样例
  
原则：

 - 大的特性src目录下创建子目录，如`src/macros`
 - `src/test`放全局的测试代码，各目录下`*_test.cj`是内部类测试代码
 - 宏定义与实现分离，如`src/macros/macros.cj`只定义宏，`src/macros/generate/*.cj`为宏的解释与代码生成
 - 尽可能类不要定义public，只对外暴露最小的API，比如一些实现辅助类就没有必要public
 - 没有必要一个cj文件只放一个类或接口，实现一个功能的类与其关联类可以放在一个文件中，但每个类可职责单一

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
     - 类TreeRouteDistributor：实现Cangjie SDK的HttpRequestDistributor与HttpRequestHandler接口，并所有请求它路由给它做分发
 - 接口层：
   - handler.cj： Handler与Middleware接口定义
     - 类JoyRequestHandler：请求处理接口
     - 类JoyHandlers：请求处理类集合，用于宏生成的代码注册
     - 类JoyRequestHandlerChain：请求处理链
     - 类JoyMiddlewareHandler：请求中间件接口
     - 类JoyMiddlewares：中间件类集合，用于宏生成的代码注册
   - context.cj：每次请求产生上下文
     - 类JoyContext：请求上下文
  - 渲染层：
    - render.cj：渲染接口定义，为以后支持其它格式的渲染扩展。目前Json与String由于简单，暂未采用实现JoyRender接口。

### Handler与Middleware宏

 - 宏定义
   - macros.cj
 - 宏解释与代码生成
   - generate
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
   - generate
     - JsonClassInfo：Json类宏的解释与代码生成
     - JsonFieldInfo：JsonField宏的解释与代码生成
   - utils
     - JsonTool：对象<->String互转辅助类

原则：

 - 宏定义文件不要展开宏的解释，保持此文件的整洁
 - 内部提供函数对各个宏解释


## Commit Message

目前，社区有多种 Commit Message 的 [写法规范](https://github.com/ajoslin/conventional-changelog/blob/master/conventions)。比较流行的方案是 约定式提交规范（Conventional Commits），它受到了Angular提交准则的启发，并在很大程度上以其为依据。约定式提交规范是一种基于提交消息的轻量级约定。这个约定与SemVer相吻合，在提交信息中描述新特性、bug 修复和破坏性变更。本项目采用此方案。它的 Message 格式如下:

```
<类型>[可选的作用域]: <描述>

[可选的正文]

[可选的脚注]
```

类型type(必须) : 用于说明git commit的类别，只允许使用下面的标识：

- feat: 新功能（feature）
- fix: 修复BUG。
- docs: 文档（documentation）。
- style: 格式（不影响代码运行的变动）。
- refactor: 重构（即不是新增功能，也不是修改bug的代码变动）。
- upgrade/boost/perform: 升级、优化相关，比如提升性能、体验。
- test: 测试相关
- chore: 构建过程或辅助工具的变动
- revert: 回滚到上一个版本。
- version: 版本管理、版本发布、源代码相关（含：依赖组件版本管理）
