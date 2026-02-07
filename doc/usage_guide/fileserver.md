# 文件服务器

CJoy 提供完整的文件服务器功能，支持静态文件服务、目录浏览、断点续传、附件下载等功能。

## 概述

CJoy 文件服务器系统基于以下核心功能设计：

- **静态文件服务**：支持单个文件和整个文件系统的静态资源服务
- **目录浏览**：自动生成目录索引页面，支持 index.html 默认页面
- **断点续传**：完整的 HTTP Range 支持，支持大文件分片下载和断点续传
- **缓存控制**：支持 ETag、Last-Modified、If-Modified-Since 等HTTP缓存机制
- **安全控制**：路径遍历保护、隐藏文件过滤、权限检查
- **附件下载**：支持强制下载模式和 MIME 类型自动识别
- **高性能**：32KB 缓冲区优化，支持流式传输

### 核心接口定义
- `JoyFileServer`：核心文件服务类，参见 [file_server.cj](../../src/fs/file_server.cj)
- `JoyFileServeHandler`：单文件处理器，参见 [handler.cj](../../src/fs/handler.cj)
- `JoyFileSystemServeHandler`：文件系统处理器，参见 [handler.cj](../../src/fs/handler.cj)
- `downloadAttachment`：附件下载函数，参见 [download.cj](../../src/fs/download.cj)

### HTTP 特性支持

| 特性 | 支持情况 | 说明 |
|------|----------|------|
| GET/HEAD | ✅ | 支持文件获取和元信息查询 |
| 断点续传 | ✅ | 完整的 HTTP Range 支持 |
| ETag | ✅ | 自动生成和验证 ETag |
| Last-Modified | ✅ | 支持基于时间的缓存验证 |
| 多Range | ✅ | 支持 multipart/byteranges 响应 |
| 304缓存 | ✅ | If-Modified-Since 支持 |
| 安全控制 | ✅ | 路径遍历保护，权限检查 |

---

## 一、单个文件路由

### 1.1 基本用法

```cangjie
// 注册单个静态文件路由
router.staticFile("/favicon.ico", "./resources/favicon.ico")
router.staticFile("/logo.png", "./assets/images/logo.png")
```

### 1.2 路由映射规则

| URL路径 | 本地文件路径 | 说明 |
|--------|-------------|------|
| `/favicon.ico` | `./resources/favicon.ico` | 直接映射 |
| `/logo.png` | `./assets/images/logo.png` | 直接映射 |

### 1.3 安全检查

文件服务会进行以下安全检查：
- **文件存在性**：文件必须存在且可读
- **文件类型**：不能是目录
- **权限检查**：文件必须具有读取权限
- **隐藏文件**：不允许服务隐藏文件（以`.`开头）

### 1.4 使用示例

```cangjie
main(): Int64 {
    let joy = Joy.default()
    
    // 网站图标
    joy.router.staticFile("/favicon.ico", "./public/favicon.ico")
    
    // 网站Logo
    joy.router.staticFile("/logo.png", "./public/images/logo.png")
    
    // 机器人协议文件
    joy.router.staticFile("/robots.txt", "./public/robots.txt")
    
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 1.5 访问测试

```bash
# 访问单个文件
curl -I http://localhost:18881/favicon.ico

# 响应头示例
HTTP/1.1 200 OK
Content-Type: image/x-icon
Content-Length: 4286
Last-Modified: Wed, 01 Jan 2025 12:00:00 GMT
ETag: "4286-1735689600"
Accept-Ranges: bytes
```

## 二、多文件路由

### 2.1 基本用法

```cangjie
// 注册文件系统路由
router.staticFs("/static", "/var/www")
router.staticFs("/assets", "./public/assets")
router.staticFs("/docs", "./documentation")
```

### 2.2 路径映射规则

指定URL前缀与本地目录路径，框架会注册通配符路由：

| URL路径 | 本地文件路径 | 说明 |
|--------|-------------|------|
| `/static/a.png` | `/var/www/a.png` | 直接映射 |
| `/static/images/logo.png` | `/var/www/images/logo.png` | 嵌套目录映射 |
| `/static/docs/manual.pdf` | `/var/www/docs/manual.pdf` | 多级目录映射 |
| `/static/a/b/c/d.png` | `/var/www/a/b/c/d.png` | 深层目录映射 |

### 2.3 路径处理规则

```cangjie
// 以下两种写法等效：
router.staticFs("/static", "./public")     // 自动补全为 /static/*
router.staticFs("/static/", "./public")    // 显式指定通配符
```

### 2.4 安全约束

| 安全检查 | 说明 | 违规响应 |
|----------|------|----------|
| 路径遍历 | 禁止 `..` 遍历上层目录 | 400 Bad Request |
| 隐藏文件 | 不允许访问隐藏文件 | 403 Forbidden |
| 权限检查 | 文件必须可读 | 403 Forbidden |
| 目录限制 | 只能访问根目录内的文件 | 403 Forbidden |
| 目录服务 | 目录访问需要特殊处理 | 目录列表或重定向 |

### 2.5 目录访问行为

#### 目录访问规则
- **路径以/结尾**：尝试返回 `index.html`，不存在则显示目录列表
- **路径不以/结尾**：重定向到带/的路径（301永久重定向）

#### Index.html 优先级
```cangjie
// 访问 /static/ 时的处理流程：
1. 检查 /static/index.html 是否存在
2. 存在：返回 index.html 内容
3. 不存在：返回目录列表页面
```

### 2.6 完整使用示例

```cangjie
main(): Int64 {
    let joy = Joy.default()
    
    // 静态资源目录
    joy.router.staticFs("/static", "./public")
    
    // 文档目录
    joy.router.staticFs("/docs", "./documentation")
    
    // 上传文件目录
    joy.router.staticFs("/uploads", "./uploads")
    
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 2.7 访问测试

```bash
# 访问目录下的文件
curl http://localhost:18881/static/css/style.css
curl http://localhost:18881/docs/api/index.html

# 访问目录（会显示目录列表或index.html）
curl http://localhost:18881/static/

# 路径遍历攻击尝试（会被拒绝）
curl http://localhost:18881/static/../../../etc/passwd
# 返回: HTTP/1.1 400 Bad Request

# 访问隐藏文件（会被拒绝）
curl http://localhost:18881/static/.git/config
# 返回: HTTP/1.1 403 Forbidden
```

## 三、附件下载

### 3.1 强制下载模式

使用 `downloadAttachment` 函数强制浏览器下载文件而不是显示文件内容。

```cangjie
import cjoy.fs.downloadAttachment
import std.fs.Path

@Get[path = "/download/report"]
func downloadReport(ctx: JoyContext): Unit {
    // 强制下载报告文件
    downloadAttachment(ctx, Path("./reports/monthly-report.pdf"))
}

@Get[path = "/download/archive"]
func downloadArchive(ctx: JoyContext): Unit {
    // 下载压缩包
    downloadAttachment(ctx, Path("./archives/project-backup.tar.gz"))
}
```

### 3.2 HTTP响应头

附件下载会自动设置以下HTTP响应头：

| 响应头 | 值 | 说明 |
|--------|-----|------|
| `Content-Disposition` | `attachment; filename="文件名"` | 强制下载模式 |
| `Content-Type` | 根据文件扩展名自动识别 | MIME类型 |
| `Transfer-Encoding` | `chunked` | 流式传输 |

### 3.3 文件名处理

```cangjie
// 文件名会自动处理特殊字符
downloadAttachment(ctx, Path("./data/我的文件 包含空格.zip"))
// 响应头: Content-Disposition: attachment; filename="我的文件 包含空格.zip"

// 文件名中的引号会自动转义
downloadAttachment(ctx, Path("./data/file\"name\"test.txt"))
// 响应头: Content-Disposition: attachment; filename="file\"name\"test.txt"
```

### 3.4 完整下载示例

```cangjie
import cjoy.fs.downloadAttachment
import std.fs.{Path, exists}
import std.io.IOException

@Get[path = "/download/{filename}"]
func downloadFile(ctx: JoyContext): String {
    let filename = ctx.getParam("filename") ?? ""
    let filePath = Path("./downloads/${filename}")
    
    try {
        // 检查文件是否存在
        if (!exists(filePath)) {
            ctx.status(404)
            return "文件不存在"
        }
        
        // 执行下载
        downloadAttachment(ctx, filePath)
        return ""
    } catch (e: IOException) {
        ctx.status(500)
        return "下载失败: ${e.message}"
    }
}

@Get[path = "/downloads"]
func listDownloads(ctx: JoyContext): String {
    // 显示可下载的文件列表
    let files = ["report-2025.pdf", "data-backup.zip", "image-gallery.tar.gz"]
    var html = "<h1>可下载文件</h1><ul>"
    
    for (file in files) {
        html += "<li><a href='/download/${file}'>${file}</a></li>"
    }
    
    html += "</ul>"
    return html
}
```

### 3.5 客户端访问示例

```bash
# 下载文件
curl -O http://localhost:18881/download/report.pdf

# 或者使用wget
wget http://localhost:18881/download/archive.tar.gz

# 查看响应头
curl -I http://localhost:18881/download/report.pdf

# 响应头示例：
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="report.pdf"
Transfer-Encoding: chunked
```

## 四、断点续传与缓存控制

### 4.1 HTTP Range 支持

CJoy文件服务器完全支持HTTP Range协议，提供以下功能：

| 功能 | HTTP头 | 说明 |
|------|---------|------|
| 单Range请求 | `Range: bytes=0-1023` | 下载文件的部分内容 |
| 多Range请求 | `Range: bytes=0-499,1000-1499` | 同时下载多个片段 |
| 后缀Range | `Range: bytes=-500` | 下载文件最后500字节 |
| 前缀Range | `Range: bytes=500-` | 下载从500字节开始到文件末尾 |

### 4.2 响应类型

| 请求类型 | 状态码 | 响应头 | 说明 |
|----------|--------|--------|------|
| 完整文件 | 200 OK | `Content-Length` | 整个文件传输 |
| 单Range | 206 Partial Content | `Content-Range`, `Content-Length` | 部分内容传输 |
| 多Range | 206 Partial Content | `Content-Type: multipart/byteranges` | 多部分响应 |
| Range无效 | 416 Range Not Satisfiable | `Content-Range: */total_size` | 请求范围无效 |

### 4.3 缓存控制机制

#### ETag 自动生成
```cangjie
// ETag格式: "文件大小-修改时间戳"
// 示例: "123456-1735689600"
func generateETag(size: Int64, modTime: DateTime): String {
    "\"${size}-${modTime.toUnixTimeStamp().toSeconds()}\""
}
```

#### 缓存验证头
| 缓存头 | 支持情况 | 用途 |
|--------|----------|------|
| `ETag` | ✅ | 文件版本标识 |
| `Last-Modified` | ✅ | 最后修改时间 |
| `If-Match` | ✅ | 条件请求 - 匹配才执行 |
| `If-None-Match` | ✅ | 条件请求 - 不匹配才执行 |
| `If-Modified-Since` | ✅ | 条件请求 - 修改后执行 |
| `If-Unmodified-Since` | ✅ | 条件请求 - 未修改才执行 |
| `If-Range` | ✅ | 条件Range请求 |

### 4.4 304 Not Modified 支持

```cangjie
// 客户端发送条件请求
curl -H "If-None-Match: \"123456-1735689600\"" http://localhost:18881/static/file.txt

// 如果文件未修改，返回304
HTTP/1.1 304 Not Modified
ETag: "123456-1735689600"
Last-Modified: Wed, 01 Jan 2025 12:00:00 GMT
```

### 4.5 断点续传示例

#### 客户端测试代码
```bash
# 1. 首次请求文件，获取总大小
curl -I http://localhost:18881/static/large-file.zip
# 响应: Content-Length: 10485760

# 2. 下载前1MB
curl -H "Range: bytes=0-1048575" http://localhost:18881/static/large-file.zip
# 响应: HTTP/1.1 206 Partial Content
# Content-Range: bytes 0-1048575/10485760

# 3. 下载剩余部分
curl -H "Range: bytes=1048576-" http://localhost:18881/static/large-file.zip
# 响应: HTTP/1.1 206 Partial Content  
# Content-Range: bytes 1048576-10485759/10485760

# 4. 多范围下载
curl -H "Range: bytes=0-1023,2048-3071,4096-5119" http://localhost:18881/static/file.txt
# 响应: multipart/byteranges 格式
```

#### 服务端处理示例
```cangjie
// CJoy自动处理Range请求，无需额外代码
router.staticFs("/static", "./public")

// 以下功能自动提供：
// - Range头解析
// - 内容范围验证  
// - 多部分响应生成
// - 206状态码设置
// - Content-Range头设置
```

### 4.6 性能优化特性

#### 缓冲区优化
```cangjie
// 32KB缓冲区，平衡内存使用和I/O性能
private static const BUFFER_SIZE: Int = 32 * 1024

// 流式传输，避免大文件一次性加载到内存
func readFileToWriter(file: File, offset: Int64, length: Int64, writer: (buf: Array<Byte>) -> Unit): Unit {
    let buf = Array<Byte>(BUFFER_SIZE, repeat: 0)
    // 分块读取和写入...
}
```

#### 内存使用控制
- **流式传输**：文件内容直接从磁盘传输到网络，不占用大量内存
- **分块处理**：使用32KB固定缓冲区，避免内存碎片
- **Range优化**：只请求文件需要的部分，减少I/O和内存使用


## 五、高级功能与配置

### 5.1 目录列表页面

当访问目录且没有 `index.html` 时，自动生成目录列表页面：

```html
<!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width">
    <title>Directory listing</title>
</head>
<body>
    <h1>Directory listing: /static/</h1>
    <pre>
        <a href="../">../</a>
        <a href="images/">images/</a>
        <a href="css/">css/</a>
        <a href="js/">js/</a>
        <a href="index.html">index.html</a>
    </pre>
</body>
</html>
```

### 5.2 MIME 类型自动识别

CJoy 根据文件扩展名自动识别MIME类型：

| 扩展名 | MIME类型 | 说明 |
|--------|----------|------|
| `.html`, `.htm` | `text/html` | HTML页面 |
| `.css` | `text/css` | 样式表 |
| `.js` | `application/javascript` | JavaScript脚本 |
| `.json` | `application/json` | JSON数据 |
| `.png` | `image/png` | PNG图片 |
| `.jpg`, `.jpeg` | `image/jpeg` | JPEG图片 |
| `.gif` | `image/gif` | GIF图片 |
| `.svg` | `image/svg+xml` | SVG矢量图 |
| `.pdf` | `application/pdf` | PDF文档 |
| `.zip` | `application/zip` | ZIP压缩包 |
| `.tar.gz` | `application/gzip` | GZIP压缩 |
| 默认 | `application/octet-stream` | 二进制流 |

### 5.3 自定义处理器

```cangjie
import cjoy.fs.{JoyFileServer, Path}

@Get[path = "/custom-file"]
func customFileServe(ctx: JoyContext): Unit {
    let filePath = Path("./special/custom.dat")
    
    // 自定义修改时间和ETag
    let customModTime = DateTime.parse("2025-01-01T12:00:00Z") ?? DateTime.now()
    let customETag = "\"custom-etag-12345\""
    
    // 使用自定义元数据服务文件
    JoyFileServer.serveContent(ctx, filePath, Some(customModTime), Some(customETag))
}

@Get[path = "/protected-file"]
func protectedFileServe(ctx: JoyContext): Unit {
    // 添加权限检查
    let authHeader = ctx.getHeader("Authorization")
    if (authHeader.isNone()) {
        ctx.status(401)
        ctx.header("WWW-Authenticate", "Basic realm=\"Protected Area\"")
        return
    }
    
    // 验证通过后服务文件
    JoyFileServer.serveFile(ctx, Path("./protected/secret.pdf"))
}
```

### 5.4 性能监控

```cangjie
import cjoy.log.macros.JoyLogInfo

@Component
class FileServerMonitor {
    @JoyCreateLogger("fileserver.monitor")
    
    func logFileAccess(ctx: JoyContext, filePath: String): Unit {
        let userAgent = ctx.getHeader("User-Agent") ?? "Unknown"
        let referer = ctx.getHeader("Referer") ?? "Direct"
        
        @JoyLogInfo("文件访问: path=${filePath}, ip=${ctx.remoteAddr}, user_agent=${userAgent}")
    }
}
```

## 六、注意事项

### 6.1 安全注意事项
- **路径遍历保护**：自动阻止 `../` 路径遍历攻击
- **隐藏文件保护**：不允许访问以 `.` 开头的隐藏文件
- **权限检查**：验证文件读取权限和目录访问权限
- **文件大小限制**：大文件建议使用流式传输避免内存溢出

### 6.2 性能注意事项
- **缓冲区大小**：默认32KB缓冲区，适合大多数场景
- **并发访问**：支持高并发文件下载，注意I/O负载
- **内存使用**：流式传输避免大文件加载到内存
- **磁盘I/O**：高频访问的文件建议使用SSD或内存缓存

### 6.3 兼容性注意事项
- **浏览器支持**：Range功能需要现代浏览器支持
- **防火墙配置**：某些防火墙可能阻止Range请求
- **代理服务器**：代理可能修改或删除Range相关头信息
- **移动网络**：移动网络下断点续传特别有用

### 6.4 最佳实践
- **文件组织**：静态文件统一放在 `public/` 或 `static/` 目录
- **缓存策略**：不常变化的文件使用长缓存时间
- **压缩传输**：启用gzip压缩减少传输量
- **CDN集成**：大文件考虑使用CDN分发
- **监控日志**：监控文件访问模式优化部署策略

### 6.5 常见问题

**Q: 为什么某些文件无法访问？**
A: 检查文件权限、是否为隐藏文件、路径是否正确

**Q: Range请求不生效怎么办？**
A: 检查客户端是否发送正确的Range头，防火墙是否阻止

**Q: 如何设置文件缓存时间？**
A: 可以通过自定义Handler添加Cache-Control头

**Q: 大文件下载占用内存过高？**
A: 确保使用流式传输，避免一次性读取整个文件

**Q: 如何禁用目录列表？**
A: 可以通过自定义Handler检查目录请求并返回403

---
 << [返回](../../README.md#使用指导)