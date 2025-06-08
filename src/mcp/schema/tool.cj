/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.schema

import std.collection.{HashMap, ArrayList}
import cjoy.json.*

@Json
public class Tool {
    public var name: String = ""
    public var description: String = ""
    public var inputSchema: Any = Option<Any>.None
}

@Json
public class ListToolsResult {
    public var nextCursor: ?String = None
    public var tools: ArrayList<Tool> = ArrayList()
}

@Json
public class CallToolRequest {
    public var name: String = ""

    @JsonField[omitempty = true]
    public var arguments: Any = Option<Any>.None
}

@Json
public open class Content {
    @JsonField[name = "type"]
    public var type_: String = ""
}

@Json
public class TextContent {
    public var text: String = ""
}

@Json
public class CallToolResult {
    public var isError: Bool = false
    public var content: ArrayList<TextContent> = ArrayList()
}
