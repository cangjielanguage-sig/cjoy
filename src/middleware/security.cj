/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

import std.collection.HashMap
import stdx.net.http.HttpStatusCode
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts}
import cjoy.log.LogTool

public class Security <: JoyMiddlewareHandler {
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

        let host = ctx.url.host
        for (h in allowedHosts) {
            if (h == host) {
                return true
            }
        }
        return false
    }
}
