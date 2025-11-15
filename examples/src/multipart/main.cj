/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.multipart

import std.io.*
import std.fs.*
import cjoy.*
import cjoy.macros.*
import cjoy.multipart.*

/*
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="id"

00009527
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="photo"; filename="00009527.png"
Content-Type: image/png

PNG ... content of photo.png
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
 */

// 方式1，默认缓存
@Post[path = "/saveUserInfo1"]
func usingDefaultCache(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "./test_tmp"
    try (form = JoyMultiPartForm.create(ctx, config)) {
        form.parse()
        // 获取form-data; name="id"
        if (let Some(id) <- (form.getPart("id")?.text ?? None)) {
            println(id)
        }
        // 获取form-data; name="photo"; filename="00009527.png"
        if (let Some(file) <- (form.getPart("photo")?.file ?? None)) {
            let tempPath = Path("./photos")
            copy(file.info.path, to: tempPath.join(file.info.name))
        }
    }
    ctx.ok()
}

// 方式2，用户自定义Handler
@Post[path = "/saveUserInfo2"]
func customHandler(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    try (form = JoyMultiPartForm.create(ctx, config)) {
        // 注册回调的Handler
        // 处理form-data; name="id"
        form.handlePart(
            "id",
            {
                part: JoyMultiPart, data: Array<Byte> =>
                    let text = String.fromUtf8(data)
                    println("${part.name}=${text}")
            }
        )
        // 处理form-data; name="photo"; filename="00009527.png"
        let tempPath = Path("./photos")
        form.handlePart(
            "photo",
            {
                part: JoyMultiPart, data: Array<Byte> =>
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

@Post[path = "/uploadfile"]
func uploadFile(ctx: JoyContext): Unit {
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "/home/xiao/upload/cache"
    let tempPath = Path("/home/xiao/upload/dest")
    try (form = JoyMultiPartForm.create(ctx, config)) {
        form.parse()
        // 获取form-data; name="files"; filename="xxx"
        if (let Some(file) <- (form.getPart("files")?.file ?? None)) {
            copy(file.info.path, to: tempPath.join(file.info.name), overwrite: true)
        }
    }
    ctx.ok()
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.staticFile("/index.html", "./src/multipart/upload.html")
    JoyHandlers.registerTo(joy)
    joy.run("0.0.0.0", 18881)
    return 0
}
