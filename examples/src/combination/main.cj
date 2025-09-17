/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.combination

import cjoy.*
import cjoy.macros.*
import cjoy.json.*
import cjoy.bind.*
import cjoy.validation.*
import cjoy.middleware.*

@Json // 类实现Jsonable接口
@Valid // 类实现 JoyValidatable接口
class UserInfo {
    @Patten[regex = "^[0-9]{4,8}$", msg = "id要求是4~8个数字"]
    var id: String = ""

    @NotBlank
    @NotEmpty
    var name: String = ""

    @Length[max = 1024]
    var address: String = ""

    @NumberRange[min = 0, max = 1]
    var gender: Int = 0
}

@Bind // 类实现JoyBindable接口
@Valid
class PageInfo {
    @BindField[name = "page_size", default = 10]
    @NumberRange[min = 10, max = 100]
    var pageSize: Int64 = 0

    @BindField[name = "page_num"]
    @NumberRange[min = 1]
    var pageNum: Int64 = 1
}

@Post[path = "/users", produce = "json"]
@Validated
func createUser(
    // @BodyParam 绑定JSON body到user
    // @NestedValid表示也要嵌套检查user的各字段
    // 注意，宏嵌套使用，目前需要加()
    @NestedValid(@BodyParam user: UserInfo)): UserInfo {
    user
}

// GET /uses?name=xxx&page_size=10&page_num=10
@Get[path = "/users", produce = "json"]
@Validated
func listUsers(
    // 入参1, @QueryParam 绑定单个参数name
    // @NotEmpty对参数name校验
    @NotEmpty(@QueryParam[default = ""] name: String),
    // 入参2, @QueryBindParam 绑定一组Query参数page_size与page_num到复杂类型, 
    // @NestedValid表示也要嵌套检查pageInfo的各字段
    // @NestedValid作用于复杂类或结构，如果参数是单个字段存在校验宏@NotEmpty则不需要使用@NestedValid
    @NestedValid(@QueryBindParam pageInfo: PageInfo)): Array<UserInfo> {
    []
}

main(): Int64 {
    // 创建joy实例
    let joy = Joy.default()
    // 注册生成的handlers
    joy.router.use(ExceptionHandler())
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
