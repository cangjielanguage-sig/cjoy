/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.boot

import std.collection.ArrayList
import cjoy.*
import cjoy.macros.*
import cjoy.boot.*

main(args: Array<String>): Int64 {
    let newArgs = ArrayList<String>(args)
    // 实际是在命令行启动加载profile配置文件
    newArgs.add("-Djoy.profile=full")
    JoyBoot.of(newArgs.toArray()).cfgPath("../testdata").run()
    return 0
}
