Changelog
------


# v0.50.0

- 特性：增加CORS中间件
- 变更：oyContent从类为变成接口，方便测试Mock
- 优化：宏实现逻辑统一都移到对应模块的macros目录下

# v0.40.0

- 特性：支持MCP Tool, Resource, Prompt服务端开发
- 特性：Json序列化与反序列支持范型，支持Any类型，支持DSL
- 特性：增加参数校验框架
- 变更：把样例代码移到src/examples目录下
- 变更：使用文档拆到多个文件中

# v0.30.0

- 特性：支持Query, PostForm， Header参数绑定到对象
- 优化：重构Bind相关的代码减少重复代码
- 变更：Context.readXXX方法变更为getXXX
- 变更：JoyMultiPart.file, text, fileContent由方法变更为属性

# v0.22.0

- 特性：支持Websocket，以及examples
- 特性：支持multipart，以及examples
- 特性：支持文件上传，以及examples

# v0.21.0

- 特性：增加静态文件服务器能力
- 变更：Context.readJsonBody变更为Context.readJson

# V0.20.0

- 特性：增加宏支持Handler与Middleware自动注册与参数注入
- 特性：JoyContext增加支持Chunked与SSE API
- 样例：增加上述功能的examples

# V0.10.0

- 特性：Web框架
- 特性：4种路由格式，路由分组
- 特性：中间件能力，预置2个中间件(BasicAuth, ExceptionHandler)
- 特性：基于编译宏的Json序列化与反序列