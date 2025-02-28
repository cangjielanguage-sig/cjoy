/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package multipart

import std.io.*
import std.fs.*
import cjoy.*
import cjoy.multipart.*

/*
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="id"

00009527
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="photo"; filename="photo.png"
Content-Type: image/png

PNG ... content of photo.png
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
 */
main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    let joy = Joy.create(cfg)
    let router = joy.router
    // 方式1，默认缓存
    router.post(
        "/saveUserInfo1",
        {
            ctx: JoyContext =>
            var config = JoyMultiPartConfig()
            config.fileCacheDir = "./test_tmp"
            try (form = JoyMultiPartForm.create(ctx, config)) {
                // 获取form-data; name="id"
                if (let Some(id) <- (form.getPart("id")?.text() ?? None)) {
                    println(id)
                }
                // 获取form-data; name="photo"; filename="photo.png"
                if (let Some(file) <- (form.getPart("photo")?.file() ?? None)) {
                    let tempPath = Path("./phones")
                    copy(file.info.path, to: tempPath.join(file.info.name))
                }
            }
            ctx.ok()
        }
    )

    // 方式2，用户自定义Handler
    router.post(
        "/saveUserInfo2",
        {
            ctx: JoyContext =>
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
                // 处理form-data; name="photo"; filename="photo.png"
                let tempPath = Path("./phones")
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
            }
            ctx.ok()
        }
    )

    joy.run("127.0.0.1", 18881)
    return 0
}
