Changelog
------
# v0.21.0

- 特性：增加静态文件服务器能力
- API：Context.readJsonBody变更为Context.readJson

# V0.20.0

- 特性：增加宏支持Handler与Middleware自动注册与参数注入
- 特性：oyContext增加支持Chunked与SSE API
- 样例：增加上述功能的examples

# V0.10.0

- Web框架
- 4种路由格式，路由分组
- 中间件能力，预置2个中间件(BasicAuth, ExceptionHandler)
- 基于编译宏的Json序列化与反序列