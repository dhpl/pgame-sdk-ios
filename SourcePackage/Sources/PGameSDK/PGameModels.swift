import Foundation

@objc(PGameEnvironment)
public enum PGameEnvironment: Int {
    case sandbox = 0
    case production = 1
}

@objc(PGameProvider)
public enum PGameProvider: Int {
    case account = 0
    case google = 1
    case apple = 2
}

struct PGameEnvironmentConfig {
    let webBaseURL: URL
    let apiBaseURL: URL
}

enum PGameInternalConfig {
    static let sandbox = PGameEnvironmentConfig(
        webBaseURL: URL(string: "https://staging.pgame.vn")!,
        apiBaseURL: URL(string: "https://api-staging.pgame.vn/api")!
    )

    static let production = PGameEnvironmentConfig(
        webBaseURL: URL(string: "https://pgame.vn")!,
        apiBaseURL: URL(string: "https://api.pgame.vn/api")!
    )

    static func config(for environment: PGameEnvironment) -> PGameEnvironmentConfig {
        environment == .sandbox ? sandbox : production
    }
}

@objc(PGameConfig)
public final class PGameConfig: NSObject {
    @objc public let environment: PGameEnvironment
    @objc public let clientId: String
    @objc public let gameCode: String
    @objc public let redirectScheme: String
    @objc public let deviceId: String?
    @objc public let scope: String?

    /// redirectUri dùng để bind OAuth authorization code.
    /// Backend /token phải nhận đúng redirectUri này.
    @objc public var redirectUri: String { "\(redirectScheme)://pgame-callback" }

    @objc public init(
        environment: PGameEnvironment,
        clientId: String,
        gameCode: String,
        redirectScheme: String,
        deviceId: String? = nil,
        scope: String? = "openid profile email phone"
    ) {
        self.environment = environment
        self.clientId = clientId
        self.gameCode = gameCode
        self.redirectScheme = redirectScheme
        self.deviceId = deviceId
        self.scope = scope
        super.init()
    }

    var current: PGameEnvironmentConfig {
        PGameInternalConfig.config(for: environment)
    }
}

@objc(PGameUser)
public final class PGameUser: NSObject {
    @objc public let id: String?
    @objc public let username: String?
    @objc public let email: String?
    @objc public let phone: String?

    @objc public init(id: String?, username: String?, email: String? = nil, phone: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.phone = phone
        super.init()
    }
}

@objc(PGameInfo)
public final class PGameInfo: NSObject {
    @objc public let id: String?
    @objc public let gameCode: String?
    @objc public let name: String?

    @objc public init(id: String?, gameCode: String?, name: String?) {
        self.id = id
        self.gameCode = gameCode
        self.name = name
        super.init()
    }
}

@objc(PGameTokenInfo)
public final class PGameTokenInfo: NSObject {
    @objc public let accessToken: String
    @objc public let refreshToken: String?
    @objc public let tokenType: String
    @objc public let expiresIn: Int
    @objc public let refreshExpiresIn: Int
    @objc public let scope: String?

    @objc public init(
        accessToken: String,
        refreshToken: String?,
        tokenType: String,
        expiresIn: Int,
        refreshExpiresIn: Int,
        scope: String?
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.refreshExpiresIn = refreshExpiresIn
        self.scope = scope
        super.init()
    }
}

@objc(PGameLoginResultObjC)
public final class PGameLoginResultObjC: NSObject {
    @objc public let code: String
    @objc public let state: String?
    @objc public let redirectUri: String?
    @objc public let user: PGameUser?
    @objc public let game: PGameInfo?
    @objc public let token: PGameTokenInfo?

    @objc public init(
        code: String,
        state: String?,
        redirectUri: String?,
        user: PGameUser?,
        game: PGameInfo?,
        token: PGameTokenInfo?
    ) {
        self.code = code
        self.state = state
        self.redirectUri = redirectUri
        self.user = user
        self.game = game
        self.token = token
        super.init()
    }
}

public struct PGameLoginResult {
    public let code: String
    public let state: String?
    public let redirectUri: String?
    public let user: PGameUser?
    public let game: PGameInfo?
    public let token: PGameTokenInfo?

    public var accessToken: String? { token?.accessToken }
    public var refreshToken: String? { token?.refreshToken }
}

public struct PGameTokenResult {
    public let token: PGameTokenInfo
    public let user: PGameUser?
    public let game: PGameInfo?
}

struct PGameAuthorizationCodeResult {
    let code: String
    let state: String?
    let redirectUri: String?
    let scope: String?
    let user: PGameUser?
    let game: PGameInfo?
}

struct PGameGoogleToken {
    let idToken: String
    let accessToken: String?
}

struct PGameAppleToken {
    let identityToken: String
    let authorizationCode: String?
    let userIdentifier: String?
    let email: String?
    let fullName: String?
}

public enum PGameSDKError: LocalizedError {
    case notConfigured
    case invalidResponse
    case missingGoogleClientId
    case missingViewController
    case userCancelled
    case network(String)
    case social(String)
    case server(String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "PGameSDK chưa được configure."
        case .invalidResponse:
            return "Response không hợp lệ."
        case .missingGoogleClientId:
            return "Thiếu googleClientId."
        case .missingViewController:
            return "Không tìm thấy view controller hiện tại."
        case .userCancelled:
            return "Người dùng đã hủy đăng nhập."
        case .network(let message):
            return message
        case .social(let message):
            return message
        case .server(let message):
            return message
        }
    }

    var nsError: NSError {
        NSError(
            domain: "PGameSDK",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: errorDescription ?? "PGameSDK error"]
        )
    }
}
