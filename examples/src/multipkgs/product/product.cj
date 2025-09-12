/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.multipkgs.product

import cjoy.*
import cjoy.macros.*

@Get[path = "/products"]
func getProducts(ctx: JoyContext): String {
    "products"
}
