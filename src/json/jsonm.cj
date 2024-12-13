package cjoy.json

import std.ast.Tokens

public macro Json(input: Tokens): Tokens {
    input
}

public macro JsonField(attr: Tokens, input: Tokens): Tokens {
    input
}