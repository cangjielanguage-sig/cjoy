/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

macro package cjoy.json

import std.ast.Tokens
import cjoy.json.generate.{JsonClassInfo, JsonFieldInfo}

public macro Json(input: Tokens): Tokens {
    JsonClassInfo.parse(input)
}

public macro JsonField(attr: Tokens, input: Tokens): Tokens {
    JsonFieldInfo.parse(attr, input)
}
