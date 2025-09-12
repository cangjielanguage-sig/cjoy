/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.multipkgs

import cjoy.*
import cjoy.macros.*
import cjoy.middleware.ExceptionHandler

// 需要引入package让其链接user，product
import examples.multipkgs.user
import examples.multipkgs.product

main(): Int64 {
    var cfg = JoyConfig(enableDebugLog: false)
    let joy = Joy.create(cfg)
    joy.router.use(ExceptionHandler())
    // 注册所有生成的handlers
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
