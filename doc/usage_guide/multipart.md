# MultiPart

CJoy 提供完整的multipart/form-data处理支持，包括数据解析、文件缓存、自定义处理器等功能。

## 概述

CJoy MultiPart系统基于以下核心概念设计：

- **自动解析**：基于RFC 2388标准解析multipart/form-data请求
- **内存/磁盘缓存**：支持内存缓存和小文件磁盘缓存两种模式
- **流式处理**：支持自定义处理器实现边解析边处理
- **文件管理**：自动处理文件名、Content-Type、临时文件管理
- **错误处理**：完整的异常处理和资源清理
- **性能优化**：支持大文件分块处理和内存控制

### 核心接口定义
- `JoyMultiPartForm`：表单解析器，参见 [multipart/form.cj](../../src/multipart)
- `JoyMultiPart`：表单部分包装，参见 [multipart/form.cj](../../src/multipart)
- `JoyMultiPartConfig`：缓存配置，参见 [multipart/form.cj](../../src/multipart)

### 请求格式支持

| 特性 | 支持状态 | 说明 |
|------|----------|------|
| 文本字段 | ✅ | 普通表单字段处理 |
| 文件上传 | ✅ | 包含filename的文件字段 |
| 多文件上传 | ✅ | 同名字段多个文件 |
| 中文文件名 | ✅ | 自动处理UTF-8编码 |
| Content-Type | ✅ | 自动识别MIME类型 |
| 大文件处理 | ✅ | 支持流式处理 |

---

使用示例：[examples/multipart](../../examples/src/multipart/main.cj) 。

## 一、基础使用

### 1.1 内存缓存模式

```cangjie
import cjoy.*
import cjoy.multipart.*

@Post[path = "/upload/memory"]
func uploadWithMemoryCache(ctx: JoyContext): Unit {
    // 配置为内存缓存模式
    var config = JoyMultiPartConfig()
    // 不设置fileCacheDir，默认使用内存缓存
    
    try (form = JoyMultiPartForm.create(ctx, config)) {
        form.parse()
        
        // 获取文本字段
        if (let Some(username) <- form.getPart("username")?.text) {
            println("用户名: ${username}")
        }
        
        // 获取文件信息
        if (let Some(file) <- form.getPart("avatar")?.file) {
            println("文件名: ${file.info.name}")
            println("文件大小: ${file.info.size}")
            println("Content-Type: ${file.info.contentType}")
            
            // 获取文件内容（小文件适合内存缓存）
            let content = form.getPart("avatar")?.fileContent ?? None
            if (let Some(data) <- content) {
                println("文件内容长度: ${data.size}")
                // 处理文件内容...
            }
        }
    }
    
    ctx.ok()
}
```

### 1.2 磁盘缓存模式

```cangjie
@Post[path = "/upload/disk"]
func uploadWithDiskCache(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "./temp_uploads"  // 设置磁盘缓存目录
    
    try (form = JoyMultiPartForm.create(ctx, config)) {
        form.parse()
        
        // 获取上传的文件
        if (let Some(file) <- form.getPart("document")?.file) {
            println("临时文件路径: ${file.info.path}")
            
            // 移动文件到目标位置
            let targetDir = Path("./documents")
            let targetPath = targetDir.join(file.info.name)
            
            // 确保目标目录存在
            if (!exists(targetDir)) {
                targetDir.createDirectory()
            }
            
            // 移动文件
            copy(file.info.path, to: targetPath)
            println("文件已移动到: ${targetPath}")
        }
    }
    
    ctx.ok()
}
```

### 1.3 多文件上传处理

```cangjie
@Post[path = "/upload/multiple"]
func uploadMultipleFiles(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "./temp_uploads"
    
    try (form = JoyMultiPartForm.create(ctx, config)) {
        form.parse()
        
        // 处理用户信息
        if (let Some(userId) <- form.getPart("userId")?.text) {
            println("上传用户ID: ${userId}")
        }
        
        // 处理多个文件
        let photoCount = form.getPartCount("photos")
        println("上传了 ${photoCount} 张照片")
        
        for (i in 0..photoCount) {
            if (let Some(photo) <- form.getPartByIndex("photos", i)?.file) {
                let userDir = Path("./user_files").join(userId)
                userDir.createDirectory()
                
                let photoPath = userDir.join(photo.info.name)
                copy(photo.info.path, to: photoPath)
                println("照片已保存: ${photoPath}")
            }
        }
    }
    
    ctx.json(HashMap<String, String>(
        ["message": "上传成功", 
         "files": "${photoCount}"]
    ))
}
```

### 1.4 JoyMultiPart对象详解

```cangjie
// JoyMultiPart提供的属性和方法
if (let Some(part) <- form.getPart("data")) {
    // 基本信息
    let partName = part.name           // 表单字段名
    let partFileName = part.fileName   // 原始文件名
    let partContentType = part.contentType // MIME类型
    
    // 文本内容
    if (let Some(text) <- part.text) {
        println("文本内容: ${text}")
    }
    
    // 文件信息
    if (let Some(fileInfo) <- part.file) {
        let filePath = fileInfo.path      // 临时文件路径
        let fileSize = fileInfo.size     // 文件大小
        println("文件: ${filePath}, 大小: ${fileSize}")
    }
    
    // 直接获取文件内容（内存模式）
    if (let Some(content) <- part.fileContent) {
        println("文件内容长度: ${content.size}")
    }
}
```

### 1.5 配置选项详解

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|----------|------|
| `fileCacheDir` | String | `null` | 文件缓存目录，null表示内存缓存 |
| `maxMemorySize` | Int64 | 10MB | 内存缓存最大文件大小限制 |
| `tempFilePrefix` | String | "upload_" | 临时文件名前缀 |
| `allowedExtensions` | Array<String> | `[]` | 允许的文件扩展名 |
| `maxFileSize` | Int64 | 无限制 | 单文件最大大小限制 |

```cangjie
@Post[path = "/upload/secure"]
func secureUpload(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "./secure_uploads"
    config.maxFileSize = 10 * 1024 * 1024  // 10MB限制
    config.allowedExtensions = ["jpg", "png", "gif", "pdf"]  // 只允许图片和PDF
    
    try (form = JoyMultiPartForm.create(ctx, config)) {
        form.parse()
        
        if (let Some(file) <- form.getPart("file")?.file) {
            // 文件大小检查
            if (file.info.size > config.maxFileSize) {
                ctx.status(413).string("文件大小超过限制")
                return
            }
            
            // 文件扩展名检查
            let extension = file.info.path.extensionName.toLower()
            if (!config.allowedExtensions.contains(extension)) {
                ctx.status(400).string("不支持的文件类型")
                return
            }
            
            // 安全处理文件
            let safeFileName = generateSafeFileName(file.info.name)
            let targetPath = Path("./secure_storage").join(safeFileName)
            copy(file.info.path, to: targetPath)
            
            ctx.json(HashMap<String, String>(
                ["message": "上传成功",
                 "fileName": safeFileName,
                 "size": "${file.info.size}"]
            ))
            return
        }
    }
    
    ctx.status(400).string("请选择文件")
}
```

## 二、自定义流式处理

### 2.1 自定义Handler注册

```cangjie
import cjoy.*
import cjoy.multipart.*
import std.io.*

@Post[path = "/upload/streaming"]
func streamingUpload(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    // 不设置fileCacheDir，准备使用自定义Handler
    
    try (form = JoyMultiPartForm.create(ctx, config)) {
        // 注册文本字段Handler（使用内存缓存）
        form.handlePart("metadata", {part: JoyMultiPart, data: Array<Byte> =>
            let metadata = String.fromUtf8(data)
            println("收到元数据: ${metadata}")
        })
        
        // 注册大文件Handler（流式处理）
        form.handlePart("largeFile", {part: JoyMultiPart, data: Array<Byte> =>
            // 流式处理大文件，减少内存占用
            let timestamp = DateTime.now().toUnixTimeStamp().toSeconds().toString()
            let fileName = "upload_${timestamp}_${part.fileName}"
            let targetPath = Path("./uploads").join(fileName)
            
            try (fileStream = File(targetPath, OpenMode.Create)) {
                // 数据会分多次回调，这里直接写入文件
                fileStream.write(data)
            }
            
            println("文件流式写入: ${targetPath}")
        })
        
        // 注册缩略图Handler（自定义处理）
        form.handlePart("thumbnail", {part: JoyMultiPart, data: Array<Byte> =>
            if (data.size > 0) {
                generateThumbnail(data, part.fileName)
            }
        })
        
        // 解析表单，触发Handler回调
        form.parse()
        
        ctx.json(HashMap<String, String>(
            ["message": "流式上传成功"]
        ))
    }
}

// 生成缩略图函数
private func generateThumbnail(data: Array<Byte>, fileName: String): Unit {
    println("为 ${fileName} 生成缩略图，数据大小: ${data.size}")
    // 实际的缩略图生成逻辑...
}
```

### 2.2 混合处理策略

```cangjie
@Post[path = "/upload/hybrid"]
func hybridUpload(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "./temp"
    
    try (form = JoyMultiPartForm.create(ctx, config)) {
        // 小文件使用默认缓存
        form.handlePart("avatar", {part: JoyMultiPart, data: Array<Byte> =>
            if (data.size <= 1024 * 1024) {  // 1MB以下使用缓存
                println("头像文件使用缓存处理: ${part.fileName}")
                // 使用默认缓存处理
            }
        })
        
        // 大文件使用自定义处理
        form.handlePart("document", {part: JoyMultiPart, data: Array<Byte> =>
            if (data.size > 1024 * 1024) {  // 1MB以上流式处理
                println("文档文件流式处理: ${part.fileName}")
                let targetPath = Path("./documents").join(part.fileName)
                
                try (file = File(targetPath, OpenMode.Create)) {
                    file.write(data)
                }
            }
        })
        
        // 元数据使用默认缓存
        // 不注册Handler，使用框架默认缓存
        
        form.parse()
        
        ctx.status(200).string("混合上传成功")
    }
}
```

### 2.3 进度处理

```cangjie
@Post[path = "/upload/progress"]
func progressUpload(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    var totalSize: Int64 = 0
    var processedSize: Int64 = 0
    
    try (form = JoyMultiPartForm.create(ctx, config)) {
        // 先获取总大小（通过Content-Length头）
        if (let Some(contentLength) <- ctx.getHeader("Content-Length")) {
            totalSize = Int64.parse(contentLength) ?? 0
        }
        
        form.handlePart("file", {part: JoyMultiPart, data: Array<Byte> =>
            processedSize += data.size
            
            // 计算进度
            let progress = if (totalSize > 0) {
                (processedSize.toFloat64() / totalSize.toFloat64() * 100).toInt32()
            } else { 0 }
            
            println("上传进度: ${progress}%")
            
            // 可以通过WebSocket或其他方式推送给前端
            // WebSocketManager.broadcastProgress(progress)
            
            // 写入文件
            let tempPath = Path("./temp").join(part.fileName)
            try (file = File(tempPath, OpenMode.Append)) {
                file.write(data)
            }
        })
        
        form.parse()
        
        ctx.json(HashMap<String, Int64>(
            ["totalSize": totalSize,
             "processedSize": processedSize]
        ))
    }
}
```

## 三、错误处理与安全

### 3.1 异常处理

```cangjie
@Post[path = "/upload/safe"]
func safeUpload(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "./uploads"
    config.maxFileSize = 50 * 1024 * 1024  // 50MB限制
    
    try {
        try (form = JoyMultiPartForm.create(ctx, config)) {
            form.parse()
            
            let uploadResults = ArrayList<HashMap<String, String>>()
            
            for (partName in ["file1", "file2", "file3"]) {
                if (let Some(file) <- form.getPart(partName)?.file) {
                    if (file.info.size > config.maxFileSize) {
                        uploadResults.add(HashMap<String, String>(
                            ["name": partName,
                             "status": "error",
                             "message": "文件大小超过限制"]
                        ))
                        continue
                    }
                    
                    // 安全文件名处理
                    let safeName = sanitizeFileName(file.info.name)
                    let targetPath = config.fileCacheDir.join(safeName)
                    
                    copy(file.info.path, to: targetPath)
                    
                    uploadResults.add(HashMap<String, String>(
                        ["name": partName,
                         "status": "success",
                         "originalName": file.info.name,
                         "safeName": safeName,
                         "path": targetPath.toString()]
                    ))
                }
            }
            
            ctx.json(uploadResults)
        }
        
    } catch (e: IOException) {
        ctx.status(500).json(HashMap<String, String>(
            ["error": "文件系统错误",
             "message": e.message]
        ))
    } catch (e: Exception) {
        ctx.status(400).json(HashMap<String, String>(
            ["error": "上传失败",
             "message": e.message]
        ))
    }
}
```

### 3.2 安全检查

```cangjie
// 文件名安全处理
private func sanitizeFileName(fileName: String): String {
    let sanitized = fileName
        .replace("..", "_")                    // 防止路径遍历
        .replace("/", "_")                     // 防止路径分隔符
        .replace("\\", "_")                    // 防止Windows路径分隔符
        .replace("%", "_")                     // 防止URL编码
        .take(100)                             // 限制文件名长度
    
    // 只保留安全字符
    var result = StringBuilder()
    for (char in sanitized) {
        if ((char >= 'a' && char <= 'z') || 
            (char >= 'A' && char <= 'Z') || 
            (char >= '0' && char <= '9') || 
            char == '_' || char == '-' || char == '.') {
            result.append(char)
        }
    }
    
    result.toString()
}

// MIME类型验证
private func isAllowedMimeType(contentType: String): Bool {
    let allowedTypes = [
        "image/jpeg", "image/png", "image/gif",
        "application/pdf", "text/plain",
        "application/json"
    ]
    allowedTypes.contains(contentType.toLower())
}
```

## 四、性能优化

### 4.1 内存优化

```cangjie
@Post[path = "/upload/optimized"]
func optimizedUpload(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    config.maxMemorySize = 5 * 1024 * 1024  // 5MB内存限制
    config.fileCacheDir = "./temp"
    
    try (form = JoyMultiPartForm.create(ctx, config)) {
        // 为不同大小的文件配置不同处理策略
        form.handlePart("smallFile", {part: JoyMultiPart, data: Array<Byte> =>
            // 小文件直接内存处理
            processSmallFile(part.name, data)
        })
        
        form.handlePart("largeFile", {part: JoyMultiPart, data: Array<Byte> =>
            // 大文件分块处理
            processLargeFileInChunks(part.name, data)
        })
        
        form.parse()
        
        ctx.json(HashMap<String, String>(
            ["message": "优化上传完成"]
        ))
    }
}

// 分块处理大文件
private func processLargeFileInChunks(fileName: String, data: Array<Byte>): Unit {
    let chunkSize = 64 * 1024  // 64KB块大小
    let filePath = Path("./large_files").join(fileName)
    
    try (file = File(filePath, OpenMode.Create)) {
        var offset = 0
        while (offset < data.size) {
            let endSize = if (offset + chunkSize > data.size) {
                data.size - offset
            } else {
                chunkSize
            }
            
            let chunk = data[offset..offset + endSize]
            file.write(chunk)
            
            offset += endSize
        }
    }
}
```

### 4.2 注意事项

| 注意事项 | 说明 | 解决方案 |
|----------|------|----------|
| **资源清理** | 必须使用`try()`确保临时文件清理 | `try (form = JoyMultiPartForm.create())` |
| **并发限制** | 控制同时上传文件数量和总大小 | 使用配置限制和队列机制 |
| **磁盘空间** | 监控磁盘空间，避免上传失败 | 实现空间检查和清理机制 |
| **病毒扫描** | 对上传文件进行安全检查 | 集成第三方杀毒引擎 |
| **访问控制** | 实现权限检查和访问日志 | 结合用户认证和授权机制 |

---
 << [返回](../../README.md#使用指导)
