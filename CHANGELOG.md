Changelog
------

# v1.0.4

- 修复：修正 JSON 数字、字符、时间与 Schema 处理
- 修复：修正 IoC 控制器宏、Bean 生命周期与依赖深度处理
- 修复：修正认证、CORS、CSRF 与安全中间件处理
- 修复：增强 JWT 校验并修正定时任务调度
- 修复：修正绑定、校验与事件订阅处理
- 修复：修正文件会话数据一致性与路径处理，防止路径穿越
- 修复：修正配置加载、合并与键名转换，以及启动配置接线
- 修复：修正文件服务范围请求、缓存与 MIME 处理
- 修复：修正 OAuth2 令牌、作用域与校验问题
- 修复：修正 multipart 解析与文件处理
- 修复：修复失败的测试用例，补充回归测试

# v1.0.3

- 修复：修正客户端 IP 解析与 IPv6 远程地址处理
- 修复：修正 405/OPTIONS 分发，并保留 OPTIONS 请求的分组中间件
- 修复：修正分块传输与 Expect: 100-continue 请求体读取
- 修复：修正不区分大小写路由破坏参数与正则的问题
- 修复：修正文件/附件未找到时的处理
- 修复：修正同一分组多个中间件被覆盖的问题
- 修复：修正 HeaderBindParam 的 Option 分支与元组返回类型判断
- 修复：修正 SSE 多行数据、group("/")、staticFs 空路径与 WebSocket 关闭处理
- 增强：补充上述修复的回归测试

# v1.0.2

 - 变更：清理一些unused import与variable
 - 变更：IOC生成的factory代码清理unused variable

# v1.0.1

 - 变更：适配仓颉1.1.0版本

# v1.0.0

- 增强：增加各模块的测试桥覆盖率
- 增强：所有API文档转成中文
- 增强：所有测试用例增加功能描述
- 增强：完善MCP的流式传输
- 特性：validation模块支持when条件表达式与@EqualField

# v0.90.0

 - 变更：废弃LogTool，启用JoyLoggerFactory适配其它的日志框架
 - 特性：增加JoyBoot，简化应用启动引导
 - 增强：提升API Doc规范性与准确性
 - 特性：Handler宏的入参支持命名参数

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