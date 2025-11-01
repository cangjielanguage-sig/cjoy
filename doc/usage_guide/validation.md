# 校验

CJoy 内置校验框架，支持通过宏对类，结构，函数参数进行校验。

## 类与结构体

```cangjie
import cjoy.validation.*
import cjoy.json.*

@Valid
@Json
public struct Data {
    @Length[min = 0, max = 10, msg = "failure message tip"]
    @NotBlank
    @NotEmpty
    var str: String = "str"

    @NumberRange[min = 0, max = 123456789]
    var u32: UInt32 = 12345678

    @Size[max = 6]
    @NestedValid
    @NumberRange[min = 0, max = 123456789]
    var arr: Array<Int32> = [1, 2, 3, 4]

    @DateTimeRange[before = "DateTime.now().addDays(1)"]
    var data: DateTime = DateTime.now()

    @NestedValid
    var nestedData: NestedData = NestedData()
}
```

- 宏展开之后，会自动实现`JoyValidatable`接口，可以调用其`validate`方法进行对成员属性校验，若校验未通过，则抛出`JoyValidationException`异常。
- 宏`@Valid`可以与`@Json`,`@Bind`一起使用。

## 函数参数

```cangjie
@Validated
func test(@Size[max = 6] arrparam: Array<Int32>): Unit {
}
```

宏展开之后会修改函数的实现，在函数的最前面对宏标注的参数进行校验。

```cangjie
func test( arrparam: Array<Int32>): Unit {
    // 自动插入代码
    arrparam.validate("", false, SizeConstraint(0, 6, ""))
}
```

**注：** 函数参数校验 **仅为实验性探索**。参见Issue：[【需求】函数的参数支持多个宏标注](https://gitcode.com/Cangjie/UsersForum/issues/1924)

## 宏说明

|宏|属性参数|说明|
|---|---|---|
|`@Size`|min=0, max=100, msg="..."|校验Collection对象的Size|
|`@Length`|min=0, max=100, msg="..."|校验字符串长度|
|`@NumberRange`|min=0, max=100, msg="..."|校验数字范围|
|`@NotEmpty`|msg="..."|校验字符串非空|
|`@NotBlank`|msg="..."|校验字符串非空白，先trim再检查|
|`@Pattern`|regex="...", msg="..."|校验字符串，数字正则检查|
|`@DateTimeRange`|before="...", after="...", msg="..."|对DateTime范围进行校验，before与before支持写表达式，要求值为DateTime|
|`@ChMobileNumber`|msg="..."|校验字符串为中国手机号码|
|`@Email`|msg="..."|校验字符串为Email格式|
|`@IPV4`|msg="..."|校验字符串为IPV4格式|
|`@Valid`||作用于类或结构体，生成代码实现`JoyValidatable`接口|
|`@NestedValid`||作用于类或结构体的成员变量，表示对此成员类与结构嵌套校验，如果是HashMap，Array, ArrayList，则会对其容器内元素校验，校验规则共用此成员变量的宏标注|
|`@Validated`||作用于函数上，生成代码会修改函数体增加调用参数的`validate`方法|

----
<< [返回](../../README.md#使用指导)