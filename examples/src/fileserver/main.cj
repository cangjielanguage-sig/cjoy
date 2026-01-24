/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.fileserver

import cjoy.*

main(): Int64 {
    let joy = Joy.default()
    // 把本地doc目录下所有文件映射到URL Path /static
    joy.router.staticFs("/static", "../doc")
    joy.router.staticFile("/static/logo.png", "../doc/imgs/logo.png")
    joy.run("127.0.0.1", 18881)
    return 0
}
