/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

import stdx.net.http.HttpStatusCode
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts}

/**
 * 设置安全 HTTP 头部的安全中间件
 */
public class Security <: JoyMiddlewareHandler {
    /**
     * 构造 Security 实例
     *
     * @param allowedHosts 允许的完全限定域名列表。默认为空列表，允许任何主机名
     * @param frameDeny 如果设为 true，添加 X-Frame-Options 头，值为 DENY。默认为 false
     * @param customFrameOptionsValue 允许使用自定义值设置 X-Frame-Options 头。覆盖 FrameDeny 选项
     * @param contentTypeNosniff 如果为 true，添加 X-Content-Type-Options 头，值为 nosniff。默认为 false
     * @param browserXssFilter 如果为 true，添加 X-XSS-Protection 头，值为 1; mode=block。默认为 false
     * @param contentSecurityPolicy 允许使用自定义值设置 Content-Security-Policy 头。默认为 ""
     * @param referrerPolicy HTTP 头 "Referrer-Policy" 控制发送的引用来源信息
     * @param ieNoOpen 防止 Internet Explorer 在站点上下文中执行下载
     * @param featurePolicy 新头，允许站点控制哪些功能和 API 可以在浏览器中使用
     */
    public Security(
        // AllowedHosts is a list of fully qualified domain names that are allowed. Default is empty list, which allows any and all host names.
        let allowedHosts!: Array<String> = [],
        //  If FrameDeny is set to true, adds the X-Frame-Options header with the value of `DENY`. Default is false.
        let frameDeny!: Bool = false,
        // CustomFrameOptionsValue allows the X-Frame-Options header value to be set with a custom value. This overrides the FrameDeny option.
        let customFrameOptionsValue!: String = "",
        // If ContentTypeNosniff is true, adds the X-Content-Type-Options header  with the value `nosniff`. Default is false.
        let contentTypeNosniff!: Bool = false,
        // If BrowserXssFilter is true, adds the X-XSS-Protection header with the value `1; mode=block`. Default is false.
        let browserXssFilter!: Bool = false,
        // ContentSecurityPolicy allows the Content-Security-Policy header value to be set with a custom value. Default is "".
        let contentSecurityPolicy!: String = "",
        // HTTP header "Referrer-Policy" governs which referrer information, sent in the Referrer header, should be included with requests made.
        let referrerPolicy!: String = "",
        // Prevent Internet Explorer from executing downloads in your site’s context
        let ieNoOpen!: Bool = false,
        // Feature Policy is a new header that allows a site to control which features and APIs can be used in the browser.
        let featurePolicy!: String = "") {
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        if (!checkAllowHosts(ctx)) {
            ctx.status(HttpStatusCode.STATUS_FORBIDDEN)
            return
        }

        // Frame Options header.
        if (!customFrameOptionsValue.isEmpty()) {
            ctx.header(JoyHttpConsts.HEADER_X_FRAME_OPTIONS, customFrameOptionsValue)
        } else if (frameDeny) {
            ctx.header(JoyHttpConsts.HEADER_X_FRAME_OPTIONS, "DENY")
        }

        // Content Type Options header.
        if (contentTypeNosniff) {
            ctx.header(JoyHttpConsts.HEADER_X_CONTENT_TYPE_OPTIONS, "nosniff")
        }

        //  XSS Protection header.
        if (browserXssFilter) {
            ctx.header(JoyHttpConsts.HEADER_X_XSS_PROTECTION, "1; mode=block")
        }

        //  Content Security Policy header.
        if (!contentSecurityPolicy.isEmpty()) {
            ctx.header(JoyHttpConsts.HEADER_CONTENT_SECURITY_POLICY, contentSecurityPolicy)
        }

        //  referrerPolicy header
        if (!referrerPolicy.isEmpty()) {
            ctx.header(JoyHttpConsts.HEADER_REFERRER_POLICY, referrerPolicy)
        }

        //  X-Download-Options header.
        if (ieNoOpen) {
            ctx.header(JoyHttpConsts.HEADER_X_DOWNLOAD_OPTIONS, "noopen")
        }

        //  featurePolicy header
        if (!featurePolicy.isEmpty()) {
            ctx.header("Feature-Policy", featurePolicy)
        }

        chain.next(ctx)
    }

    private func checkAllowHosts(ctx: JoyContext): Bool {
        if (allowedHosts.isEmpty()) {
            return true
        }

        // 普通 HTTP/1.1 请求的 URL 由 request-target 构造，不含 host，必须从 Host 头读取
        let hostHeader = ctx.getHeader(JoyHttpConsts.HEADER_HOST) ?? return false
        var host = hostHeader.trimAscii().toAsciiLower()
        if (let Some(pos) <- host.lastIndexOf(b':')) {
            host = host[..pos]
        }
        for (h in allowedHosts) {
            if (h.trimAscii().toAsciiLower() == host) {
                return true
            }
        }
        return false
    }
}
