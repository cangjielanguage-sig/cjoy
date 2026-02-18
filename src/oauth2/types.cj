/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.oauth2

import std.collection.HashMap
import std.time.DateTime
import std.crypto.digest.digest
import stdx.crypto.digest.SHA256
import cjoy.json.*
import cjoy.json.macros.*
import cjoy.framework.JoyContext
import cjoy.utils.rawBase64URLEncode

/**
 * TokenBody 表示调用 /token 路径时返回的基础令牌信息
 */
@Json
public class TokenBody {
    @JsonField[name = "token_type"]
    public var tokenType: String = ""
    @JsonField[name = "access_token"]
    public var accessToken: String = ""
    @JsonField[name = "refresh_token"]
    public var refreshToken: String = ""
    @JsonField[name = "code"]
    public var code: String = ""
    @JsonField[name = "expires_in"]
    public var expiresIn: Int = 0
}

/**
 * TokenInfo 表示令牌信息
 */
@Json
public class TokenInfo {
    public var clientId: String = ""
    public var userId: String = ""
    public var redirectURI: String = ""
    public var scope: String = ""

    public var code: String = ""
    public var codeChallenge: String = ""
    public var codeChallengeMethod: String = ""
    public var codeCreateAt: DateTime = DateTime.now()
    public var codeExpiredIn: Int = 0

    public var access: String = ""
    public var accessCreateAt: DateTime = DateTime.now()
    public var accessExpiredIn: Int = 0

    public var refresh: String = ""
    public var refreshCreateAt: DateTime = DateTime.now()
    public var refreshExpiredIn: Int = 0
    public var extension: HashMap<String, String> = HashMap()
}

/**
 * ClientInfo 表示客户端信息
 */
@Json
public class ClientInfo {
    public var id: String = ""
    public var secret: String = ""
    public var domain: String = ""
    public var isPublic: Bool = false
    public var userId: String = ""
}

/**
 * GenerateBasic 为生成令牌数据提供基础
 */
public class GenerateBasic {
    /**
     * 构造 GenerateBasic 实例
     *
     * @param client 客户端信息
     * @param userId 用户 ID
     * @param createAt 令牌创建时间
     * @param tokenInfo 令牌信息
     * @param request HTTP 请求上下文
     */
    public GenerateBasic(
        public let client!: ClientInfo,
        public let userId!: String,
        public let createAt!: DateTime,
        public let tokenInfo!: TokenInfo,
        public let request!: JoyContext
    ) {
    }
}

/**
 * TokenGenerateRequest 为令牌生成提供参数
 */
public class TokenGenerateRequest {
    /**
     * 构造 TokenGenerateRequest 实例
     *
     * @param request HTTP 请求上下文
     * @param clientId 客户端 ID
     * @param clientSecret 客户端密钥
     * @param userId 用户 ID
     * @param redirectURI 重定向 URI
     * @param scope 授权范围
     * @param code 授权码
     * @param codeChallenge PKCE 的代码挑战
     * @param codeChallengeMethod PKCE 的代码挑战方法
     * @param refresh 刷新令牌
     * @param codeVerifier PKCE 的代码验证器
     * @param accessTokenExp 访问令牌过期持续时间
     */
    public TokenGenerateRequest(
        public let request!: JoyContext,
        public let clientId!: String = "",
        public var clientSecret!: String = "",
        public var userId!: String = "",
        public var redirectURI!: String = "",
        public var scope!: String = "",
        public var code!: String = "",
        public var codeChallenge!: String = "",
        public var codeChallengeMethod!: CodeChallengeMethod = "",
        public var refresh!: String = "",
        public var codeVerifier!: String = "",
        public var accessTokenExp!: Duration = Duration.Zero
    ) {}
}

/**
 * 授权配置参数
 */
public class GrantConfig {
    public GrantConfig(
        // 访问令牌过期时间，0 表示永不过期
        public let accessTokenExp: Duration,
        // 刷新令牌过期时间，0 表示永不过期
        public let refreshTokenExp: Duration,
        // 是否生成刷新令牌
        public let isGenerateRefresh: Bool
    ) {
    }

    public static let CODE_EXP = Duration.minute * 10
    public static let AUTHORIZE_CODE_TOKEN_CFG = GrantConfig(Duration.hour * 2, Duration.hour * 24 * 3, true)
    public static let IMPLICIT_CODE_TOKEN_CFG = GrantConfig(Duration.hour * 1, Duration.Zero, false)
    public static let PASSWOD_CODE_TOKEN_CFG = GrantConfig(Duration.hour * 2, Duration.hour * 24 * 7, true)
    public static let CLIENT_CODE_TOKEN_CFG = GrantConfig(Duration.hour * 2, Duration.Zero, false)
    public static let REFRESH_CODE_TOKEN_CFG = RefreshingConfig(Duration.Zero, Duration.Zero, true, false, true, true)
}

/**
 * 刷新令牌配置
 */
public class RefreshingConfig {
    public RefreshingConfig(
        // 访问令牌过期时间，0 表示永不过期
        public let accessTokenExp: Duration,
        // 刷新令牌过期时间，0 表示永不过期
        public let refreshTokenExp: Duration,
        // 是否生成刷新令牌
        public let isGenerateRefresh: Bool,
        // 是否重置刷新创建时间
        public let isResetRefreshTime: Bool,
        // 是否移除访问令牌
        public let isRemoveAccess: Bool,
        // 是否移除刷新令牌
        public let isRemoveRefreshing: Bool
    ) {
    }
}

/**
 * 服务器配置参数
 */
public class ServerConfig {
    public ServerConfig(
        var tokenType!: String = "Bearer",
        var allowGetAccessRequest!: Bool = false,
        var allowResponseTypes!: Array<ResponseType> = [OAuthConsts.RESPONSE_TYPE_TOKEN, OAuthConsts.RESPONSE_TYPE_CODE],
        var allowGrantTypes!: Array<GrantType> = [OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE,
            OAuthConsts.GRANT_TYPE_PASSWORD_CREDENTIALS, OAuthConsts.GRANT_TYPE_CLIENT_CREDENTIALS,
            OAuthConsts.GRANT_TYPE_REFRESHING],
        var allowedCodeChallengeMethods!: Array<CodeChallengeMethod> = [OAuthConsts.CODE_CHALLENGE_S256,
            OAuthConsts.CODE_CHALLENGE_PLAIN],
        var forcePKCE!: Bool = false
    ) {
    }
}

/**
 * 授权请求
 */
public class AuthorizeRequest {
    public AuthorizeRequest(
        let responseType!: ResponseType,
        let clientId!: String,
        var scope!: String,
        var redirectURI!: String,
        var state!: String,
        var userId!: String,
        var codeChallenge!: String,
        var codeChallengeMethod!: CodeChallengeMethod,
        var accessTokenExp!: Duration,
        var request!: JoyContext
    ) {
    }
}

/**
 * PKCE 方法
 */
public type CodeChallengeMethod = String

extend CodeChallengeMethod {
    /**
     * 验证 PKCE 代码挑战
     *
     * @param cc 代码挑战
     * @param ver 代码验证器
     * @return 如果有效返回 true，否则返回 false
     */
    public func validate(cc: String, ver: String): Bool {
        match (this) {
            case "plain" => cc == ver
            case "S256" =>
                let bs = digest(SHA256(), ver.toArray())
                let a = rawBase64URLEncode(bs)
                let b = cc.trimEnd("=")
                a == b
            case _ => false
        }
    }
}

/**
 * 授权模式
 */
public type GrantType = String

/**
 * OAuth2 响应类型
 */
public type ResponseType = String

/**
 * OAuth2 常量
 */
public struct OAuthConsts {
    // CodeChallengeMethod
    public static const CODE_CHALLENGE_PLAIN: CodeChallengeMethod = "plain"
    public static const CODE_CHALLENGE_S256: CodeChallengeMethod = "S256"

    // GrantType
    public static const GRANT_TYPE_AUTHORIZATION_CODE: GrantType = "authorization_code"
    public static const GRANT_TYPE_PASSWORD_CREDENTIALS: GrantType = "password"
    public static const GRANT_TYPE_CLIENT_CREDENTIALS: GrantType = "client_credentials"
    public static const GRANT_TYPE_REFRESHING: GrantType = "refresh_token"
    public static const GRANT_TYPE_IMPLICIT: GrantType = "__implicit"

    // ResponseType
    public static const RESPONSE_TYPE_CODE: ResponseType = "code"
    public static const RESPONSE_TYPE_TOKEN: ResponseType = "token"
}
