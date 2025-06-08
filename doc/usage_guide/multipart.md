# MultiPart

CJoy 提供对 `multipart` 的解释、数据缓存，提供API简化使用。

使用示例：[examples/multipart](../../src/examples/multipart/main.cj) 。

## 内置缓存

框架内置缓存支持文本的内存与文件磁盘缓存，通过API直接获取缓存内容。

```
import cjoy.*
import cjoy.multipart.*

router.post("/saveUserInfo1", {ctx: JoyContext =>
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "./test_tmp"
    try (form = JoyMultiPartForm.create(ctx, config)) {
        form.parse()
        // 获取form-data; name="id"
        if (let Some(id) <- (form.getPart("id")?.getText() ?? None)) {
            println(id)
        }
        // 获取form-data; name="photo"; filename="00009527.png"
        if (let Some(file) <- (form.getPart("photo")?.getFile() ?? None)) {
            let tempPath = Path("./photos")
            copy(file.info.path, to: tempPath.join(file.info.name))
        }
    }
    ctx.ok()
  }
)
```

- `JoyMultiPartForm `：实现 `Resource` 接口，需要使用 `try()` 确保缓存的临时对象在退出时被清理。
  - `parse()`: 解释表单内容
  - `getPart(name)`: 获取MultiPart对象
- `JoyMultiPart`
  - `text`: 获取表单文本内容
  - `file`: 获取表单上传文件缓存磁盘文件对象，用户可移动，拷贝到其它目标目录。当`JoyMultiPartConfig.fileCacheDir`不为空时，文件缓存在指定的目录下
  - `fileContent`: 获取表单上传文件缓存在内存中内容。当`JoyMultiPartConfig.fileCacheDir`为空时，默认缓存在内存中
  - `name`: 获取表单名称
  - `fileName`: 获取表单上传文件名
  - `contentType` : 获取表单上传文件类型

## 自定义Handler

框架支持对每个Part注册处理类，可在边解释Http Body时边回调，减少对内存与文件复制，适合于上传的文件直接存储到第三方的文件系统。

```
router.post("/saveUserInfo2", {ctx: JoyContext =>
    var config = JoyMultiPartConfig()
    try (form = JoyMultiPartForm.create(ctx, config)) {
        // 先注册回调的Handler
        // 处理form-data; name="id"
        form.handlePart("id", {part: JoyMultiPart, data: Array<Byte> =>
            let text = String.fromUtf8(data)
            println("${part.name}=${text}")
          }
        )
        // 处理form-data; name="photo"; filename="00009527.png"
        let tempPath = Path("./photos")
        form.handlePart("photo", {part: JoyMultiPart, data: Array<Byte> =>
            // 会多次回调，性能优化可以考虑减少File打开
            let fileName = tempPath.join(part.fileName)
            try (file = File(fileName, OpenMode.Append)) {
                file.write(data)
            }
          }
        )
        // 解释内容，触发回调Handler
        form.parse()
    }
    ctx.ok()
  }
)
```

- `JoyMultiPartForm`
  - `form.handlePart(name, handler)`: 注册Part的处理类

当用户有注册自定义Handler时，框架会优先调用Handler进行回调，不再做内存或磁盘缓存。同一个HTTP请求存在多个MultiPart时，不同的Part可以采用不同处理策略，如示例中的`id`可以采用内置缓存，`photo`可以注册自定义Handler。

----
<< [返回](../../README.md#使用指导)