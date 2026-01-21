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
 * the return token base info when invoke /token path
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
 * the token information
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
 * the client information
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
 * provide the basis of the generated token data
 */
public class GenerateBasic {
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
 * provide to generate the token request parameters
 */
public class TokenGenerateRequest {
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
 * authorization configuration parameters
 */
public class GrantConfig {
    public GrantConfig(
        // access token expiration time, 0 means it doesn't expire
        public let accessTokenExp: Duration,
        // refresh token expiration time, 0 means it doesn't expire
        public let refreshTokenExp: Duration,
        // whether to generate the refreshing token
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
 * refreshing token config
 */
public class RefreshingConfig {
    public RefreshingConfig(
        // access token expiration time, 0 means it doesn't expire
        public let accessTokenExp: Duration,
        // refresh token expiration time, 0 means it doesn't expire
        public let refreshTokenExp: Duration,
        // whether to generate the refreshing token
        public let isGenerateRefresh: Bool,
        // whether to reset the refreshing create time
        public let isResetRefreshTime: Bool,
        // whether to remove access token
        public let isRemoveAccess: Bool,
        // whether to remove refreshing token
        public let isRemoveRefreshing: Bool
    ) {
    }
}

/**
 * the server configuration parameters
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
 * authorization request
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
 * PCKE method
 */
public type CodeChallengeMethod = String

extend CodeChallengeMethod {
    /**
     * validate PKCE code challenge
     *
     * @param cc: the code challenge
     * @param ver: the code verifier
     * @return: true if valid, false otherwise
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
 * authorization model
 */
public type GrantType = String

public type ResponseType = String

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
