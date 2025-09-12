/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.multipkgs.user

import cjoy.*
import cjoy.macros.*

@Get[path = "/users"]
func getUsers(ctx: JoyContext): String {
    "users"
}
