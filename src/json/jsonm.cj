/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

macro package cjoy.json

import std.ast.Tokens
import cjoy.json.generate.{JsonClassInfo, JsonFieldInfo}

/**
* Json macro is used for annotation the object of class or struct can be serialized and deserialized.
*/
public macro Json(input: Tokens): Tokens {
    JsonClassInfo.parse(input)
}

/**
* JsonField macro is used for annotation the field of class or struct.
* 
* @param name：the key new name of json
* @param omitempty: vaule is true/false, whether to ignore empty strings or Options.None
* @param ignore：vaule is true/false, whether to ignore the field
* @param timeformat：the format for Datetime field
*/
public macro JsonField(attr: Tokens, input: Tokens): Tokens {
    JsonFieldInfo.parse(attr, input)
}
