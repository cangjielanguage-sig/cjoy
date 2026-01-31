Changelog
------
# v0.90.0

 - 变更：废弃LogTool，启用JoyLoggerFactory适配其它的日志框架

# v0.80.0

 - 变更：宏统一由cjoy.macros重新导出
 - 特性：文件服务支持断点继传
 - 增强：API Doc注释

# v0.70.0

- 特性：支持IoC框架
- 特性：Handler宏支持在Bean中使用
- 特性：Scheduled宏支持在Bean中使用
- 特性：EventBus服务
- 特性：配置服务

# v0.61.0

- 特性：增加downloadAttachment支持单独以附件方式下载文件
- 优化：清理部分cjlint codecheck告警
- 修复：增加一些测试用例并修改其中的Bug

# v0.60.0

- 特性：增加日志宏
- 特性：增加Service框架，Schedule与Http client服务
- 特性：增加AccessLog, Session，JWT、Token认证等中间件
- 变更：引入STDX包采用环境变量CANGJIE_STDX_PATH
- 变更：样例代码examples移到独立工程
- 变更：删除JoyRender接口

# v0.50.0

- 特性：增加CORS中间件
- 变更：JoyContent从类为变成接口，方便测试Mock
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
- 变更：JoyContext.readXXX方法变更为getXXX
- 变更：JoyMultiPart.file, text, fileContent由方法变更为属性

# v0.22.0

- 特性：支持Websocket，以及examples
- 特性：支持multipart，以及examples
- 特性：支持文件上传，以及examples

# v0.21.0

- 特性：增加静态文件服务器能力
- 变更：JoyContext.readJsonBody变更为readJson

# V0.20.0

- 特性：增加宏支持Handler与Middleware自动注册与参数注入
- 特性：JoyContext增加支持Chunked与SSE API
- 样例：增加上述功能的examples

# V0.10.0

- 特性：Web框架
- 特性：4种路由格式，路由分组
- 特性：中间件能力，预置2个中间件(BasicAuth, ExceptionHandler)
- 特性：基于编译宏的Json序列化与反序列