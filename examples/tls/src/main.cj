package tls

import cjoy.*

import net.http.*
import net.tls.*
import std.io.*
import std.fs.{File, OpenMode}
import crypto.x509.{X509Certificate, PrivateKey}
import net.tls.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)

    // 注册路由
    let router = joy.router
    router.get(
        "/{name}",
        {
            ctx: JoyContext =>
            let name = ctx.getParam("name").getOrDefault({=> "no name"})
            ctx.string("name in paramter path, name=${name}")
        }
    )
    router.get(
        "/abc",
        {
            ctx: JoyContext => ctx.string("static path abc")
        }
    )

    // 读取证书
    let tlsConfig = loadTlsConfig()
    
    // 启动服务
    let serverBuider = ServerBuilder().addr("127.0.0.1").port(18881).tlsConfig(tlsConfig)
    joy.run(serverBuider)
    return 0
}

func loadTlsConfig(): TlsServerConfig {
    let certificatePath = "server_cert.pem"
    let certificateKeyPath = "server_key.pem"
    let certText = readPermFile(certificatePath)
    let keyText = readPermFile(certificateKeyPath)

    let certificate = X509Certificate.decodeFromPem(certText)
    let privateKey = PrivateKey.decodeFromPem(keyText)
    
    TlsServerConfig(certificate, privateKey)
}

func readPermFile(path: String): String {
    var str = ""
    try (file = File(path, Read)) {
        str = String.fromUtf8(readToEnd(file))
    }
    str
}