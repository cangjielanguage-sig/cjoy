# 文件服务器

CJoy 提供文件服务器的封装，提供两个API：`staticFile` 与 `staticFs`。

## 单个文件路由

示例：`router.staticFile("/static/favicon.ico", "./resources/favicon.ico")`

## 多文件路由

示例：`router.staticFs("/static", "/var/www")`

指定URL Path与本地路径，框架会注册`/static/*`的路由，支持如下映射：

  - `/static/a.png` <--> `/var/www/a.png`
  - `/static/a/b/c/d.png` <--> `/var/www/a/b/c/d.png`

约束：

- URL Path映射只能是本地文件，且不能是隐藏文件，不能是子目录;
- URL Path中禁止使用`..` 遍历上层路径;

使用示例：[examples/fileserver](../../examples/src/fileserver/main.cj) 。

## 附件下载

提供API支持以附件方式下载指定的文件。

```
import cjoy.fs.downloadAttachment

@Get[path = "/xxx"]
func downloadFie(ctx: JoyContext): Unit {
  // 下载某个文件
  downloadAttachment(ctx, "./path/a.tar.gz")
}
```

----
<< [返回](../../README.md#使用指导)