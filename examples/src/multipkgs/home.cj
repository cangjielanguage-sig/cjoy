/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.multipkgs

import cjoy.*
import cjoy.macros.*

@Get[path = "/home"]
func home(ctx: JoyContext): String {
    "home"
}
