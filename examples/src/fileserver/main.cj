/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.fileserver

import cjoy.*

main(): Int64 {
    let joy = Joy.default()
    joy.router.staticFs("/static", "doc")
    joy.run("127.0.0.1", 18881)
    return 0
}