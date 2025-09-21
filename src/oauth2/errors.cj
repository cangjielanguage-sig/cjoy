/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.oauth2

import std.collection.HashMap

public class ErrorInfo {
    public ErrorInfo(
        public var statusCode!: UInt16 = 0,
        public var code!: String = "",
        public var description!: String = ""
    ) {}
}

public class OAuthException <: Exception {
    public OAuthException(public let errorInfo: ErrorInfo) {
        super(errorInfo.description)
    }

    public init(message: String) {
        this(ErrorInfo(statusCode: 401, description: message))
    }
}

/**
 * error response
 */
public class ErrorResponse {
    public ErrorResponse(
        public let errorInfo: ErrorInfo,
        public var uri!: String = "",
        public var error!: String = "",
        public let header!: HashMap<String, String> = HashMap()
    ) {
    }
}

public struct OAuthErrors {
    // inner error
    public static let INVALID_REDIRECT_URI = ErrorInfo(statusCode: 400, code: "invalid redirect uri")
    public static let INVALID_AUTHORIZE_CODE = ErrorInfo(statusCode: 400, code: "invalid authorize code")
    public static let INVALID_ACCESS_TOKEN = ErrorInfo(statusCode: 400, code: "invalid access token")
    public static let INVALID_REFRESH_TOKEN = ErrorInfo(statusCode: 400, code: "invalid refresh token")
    public static let EXPIRED_ACCESS_TOKEN = ErrorInfo(statusCode: 400, code: "iexpired access token")
    public static let EXPIRED_REFRESHT_OKEN = ErrorInfo(statusCode: 400, code: "expired refresh token")
    public static let MISSING_CODE_VERIFIER = ErrorInfo(statusCode: 400, code: "missing code verifier")
    public static let MISSING_CODE_CHALLENGE = ErrorInfo(statusCode: 400, code: "missing code challenge")
    public static let INVALID_CODE_CHALLENGE = ErrorInfo(statusCode: 400, code: "invalid code challenge")

    // response error rfc6749#section-5.2
    public static let INVALID_REQ = ErrorInfo(statusCode: 400, code: "invalid_request",
        description: "The request is missing a required parameter, includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed")
    public static let UNAUTHORIZED_CLIENT = ErrorInfo(statusCode: 401, code: "unauthorized_client",
        description: "The client is not authorized to request an authorization code using this method")
    public static let ACCESS_DENIED = ErrorInfo(statusCode: 403, code: "access_denied",
        description: "The resource owner or authorization server denied the request")
    public static let UNSUPPORTED_RESP_TYPE = ErrorInfo(statusCode: 401, code: "unsupported_response_type",
        description: "The authorization server does not support obtaining an authorization code using this method")
    public static let INVALID_SCOPE = ErrorInfo(statusCode: 400, code: "invalid_scope",
        description: "The requested scope is invalid, unknown, or malformed")
    public static let SERVER_ERROR = ErrorInfo(statusCode: 500, code: "server_error",
        description: "The authorization server encountered an unexpected condition that prevented it from fulfilling the request")
    public static let TEMP_UNAVAILABLE = ErrorInfo(statusCode: 503, code: "temporarily_unavailable",
        description: "The authorization server is currently unable to handle the request due to a temporary overloading or maintenance of the server")
    public static let INVALID_CLIENT = ErrorInfo(statusCode: 401, code: "invalid_client",
        description: "Client authentication failed")
    public static let INVALID_GRANT = ErrorInfo(statusCode: 401, code: "invalid_grant",
        description: "The provided authorization grant (e.g., authorization code, resource owner credentials) or refresh token is invalid, expired, revoked, does not match the redirection URI used in the authorization request, or was issued to another client")
    public static let UNSUPPORTED_GRANT_TYPE = ErrorInfo(statusCode: 401, code: "unsupported_grant_type",
        description: "The authorization grant type is not supported by the authorization server")
    public static let CODE_CHALLENG_ERQUIRED = ErrorInfo(statusCode: 400, code: "invalid_request",
        description: "PKCE is required. code_challenge is missing")
    public static let UNSUPPORTED_CODE_CHALLENGE_METHOD = ErrorInfo(statusCode: 400, code: "invalid_request",
        description: "Selected code_challenge_method not supported")
    public static let INVALID_CODE_CHALLENGE_LEN = ErrorInfo(statusCode: 400, code: "invalid_request",
        description: "Code challenge length must be between 43 and 128 charachters long")
}
