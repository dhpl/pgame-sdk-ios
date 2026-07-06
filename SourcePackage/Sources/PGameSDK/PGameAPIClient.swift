import Foundation
import UIKit

final class PGameAPIClient {
    private let config: PGameConfig

    init(config: PGameConfig) {
        self.config = config
    }

    func loginAccount(
        account: String,
        password: String,
        state: String,
        completion: @escaping (Result<PGameLoginResult, PGameSDKError>) -> Void
    ) {
        var body = baseBody(state: state)
        body["account"] = account
        body["password"] = password

        requestAuthorizationCode(path: "/v1/sdk-auth/login", body: body) { [weak self] result in
            guard let self else { return }
            self.exchangeCodeResult(result, completion: completion)
        }
    }

    func loginGoogle(
        token: PGameGoogleToken,
        state: String,
        completion: @escaping (Result<PGameLoginResult, PGameSDKError>) -> Void
    ) {
//        var body = baseBody(state: state)
//        body["provider"] = "google"
//        body["idToken"] = token.idToken
//        body["googleClientId"] = config.googleClientId
//
//        if let accessToken = token.accessToken {
//            body["accessToken"] = accessToken
//        }
//
//        requestAuthorizationCode(path: "/v1/sdk-auth/social", body: body) { [weak self] result in
//            guard let self else { return }
//            self.exchangeCodeResult(result, completion: completion)
//        }
    }

    func loginApple(
        token: PGameAppleToken,
        state: String,
        completion: @escaping (Result<PGameLoginResult, PGameSDKError>) -> Void
    ) {
        var body = baseBody(state: state)
        body["provider"] = "apple"
        body["identityToken"] = token.identityToken

        if let authorizationCode = token.authorizationCode { body["authorizationCode"] = authorizationCode }
        if let userIdentifier = token.userIdentifier { body["appleUserId"] = userIdentifier }
        if let email = token.email { body["email"] = email }
        if let fullName = token.fullName { body["fullName"] = fullName }

        requestAuthorizationCode(path: "/v1/sdk-auth/social", body: body) { [weak self] result in
            guard let self else { return }
            self.exchangeCodeResult(result, completion: completion)
        }
    }

    func refreshToken(
        _ refreshToken: String,
        completion: @escaping (Result<PGameTokenResult, PGameSDKError>) -> Void
    ) {
        var body: [String: Any] = [
            "grantType": "refresh_token",
            "clientId": config.clientId,
            "gameCode": config.gameCode,
            "platform": "ios",
            "bundleId": Bundle.main.bundleIdentifier ?? "",
            "refreshToken": refreshToken
        ]

        if let deviceId = config.deviceId ?? UIDeviceId.valueIfAvailable {
            body["deviceId"] = deviceId
        }

        requestToken(body: body, completion: completion)
    }

    func revoke(
        refreshToken: String,
        completion: @escaping (Result<Void, PGameSDKError>) -> Void
    ) {
        let body: [String: Any] = [
            "clientId": config.clientId,
            "refreshToken": refreshToken
        ]

        post(path: "/v1/sdk-auth/revoke", body: body) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func userInfo(
        accessToken: String,
        completion: @escaping (Result<[String: Any], PGameSDKError>) -> Void
    ) {
        var request = URLRequest(url: makeURL(path: "/v1/sdk-auth/userinfo"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("PGameSDK-iOS/1.3.0", forHTTPHeaderField: "X-PGame-SDK")
        request.setValue(config.clientId, forHTTPHeaderField: "X-PGame-Client-Id")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.network(error.localizedDescription))) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                    return
                }

                let status = json["status"] as? Bool ?? false
                let message = json["message"] as? String ?? "Không lấy được thông tin user."

                guard status else {
                    DispatchQueue.main.async { completion(.failure(.server(message))) }
                    return
                }

                DispatchQueue.main.async { completion(.success(json)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
            }
        }.resume()
    }

    private func exchangeCodeResult(
        _ result: Result<PGameAuthorizationCodeResult, PGameSDKError>,
        completion: @escaping (Result<PGameLoginResult, PGameSDKError>) -> Void
    ) {
        switch result {
        case .success(let auth):
            exchangeAuthorizationCode(auth) { tokenResult in
                switch tokenResult {
                case .success(let token):
                    completion(.success(PGameLoginResult(
                        code: auth.code,
                        state: auth.state,
                        redirectUri: auth.redirectUri,
                        user: token.user ?? auth.user,
                        game: token.game ?? auth.game,
                        token: token.token
                    )))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    private func exchangeAuthorizationCode(
        _ auth: PGameAuthorizationCodeResult,
        completion: @escaping (Result<PGameTokenResult, PGameSDKError>) -> Void
    ) {
        var body: [String: Any] = [
            "grantType": "authorization_code",
            "clientId": config.clientId,
            "gameCode": config.gameCode,
            "platform": "ios",
            "bundleId": Bundle.main.bundleIdentifier ?? "",
            "redirectUri": auth.redirectUri ?? config.redirectUri,
            "code": auth.code
        ]

        if let deviceId = config.deviceId ?? UIDeviceId.valueIfAvailable {
            body["deviceId"] = deviceId
        }

        requestToken(body: body, completion: completion)
    }

    private func requestAuthorizationCode(
        path: String,
        body: [String: Any],
        completion: @escaping (Result<PGameAuthorizationCodeResult, PGameSDKError>) -> Void
    ) {
        post(path: path, body: body) { result in
            switch result {
            case .success(let payload):
                guard let code = payload["code"] as? String, !code.isEmpty else {
                    completion(.failure(.invalidResponse))
                    return
                }

                completion(.success(PGameAuthorizationCodeResult(
                    code: code,
                    state: payload["state"] as? String,
                    redirectUri: payload["redirectUri"] as? String,
                    scope: payload["scope"] as? String,
                    user: Self.parseUser(payload["user"] as? [String: Any]),
                    game: Self.parseGame(payload["game"] as? [String: Any])
                )))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func requestToken(
        body: [String: Any],
        completion: @escaping (Result<PGameTokenResult, PGameSDKError>) -> Void
    ) {
        post(path: "/v1/sdk-auth/token", body: body) { result in
            switch result {
            case .success(let payload):
                guard let accessToken = payload["accessToken"] as? String, !accessToken.isEmpty else {
                    completion(.failure(.invalidResponse))
                    return
                }

                let token = PGameTokenInfo(
                    accessToken: accessToken,
                    refreshToken: payload["refreshToken"] as? String,
                    tokenType: payload["tokenType"] as? String ?? "Bearer",
                    expiresIn: payload["expiresIn"] as? Int ?? 0,
                    refreshExpiresIn: payload["refreshExpiresIn"] as? Int ?? 0,
                    scope: payload["scope"] as? String
                )

                completion(.success(PGameTokenResult(
                    token: token,
                    user: Self.parseUser(payload["user"] as? [String: Any]),
                    game: Self.parseGame(payload["game"] as? [String: Any])
                )))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func post(
        path: String,
        body: [String: Any],
        completion: @escaping (Result<[String: Any], PGameSDKError>) -> Void
    ) {
        var request = URLRequest(url: makeURL(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("PGameSDK-iOS/1.3.0", forHTTPHeaderField: "X-PGame-SDK")
        request.setValue(config.clientId, forHTTPHeaderField: "X-PGame-Client-Id")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(.network(error.localizedDescription)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.network(error.localizedDescription))) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                    return
                }

                let status = json["status"] as? Bool ?? false
                let message = json["message"] as? String ?? "Đăng nhập thất bại."

                guard status, let payload = json["data"] as? [String: Any] else {
                    DispatchQueue.main.async { completion(.failure(.server(message))) }
                    return
                }

                DispatchQueue.main.async { completion(.success(payload)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
            }
        }.resume()
    }

    private func baseBody(state: String) -> [String: Any] {
        var body: [String: Any] = [
            "clientId": config.clientId,
            "gameCode": config.gameCode,
            "deviceId": config.deviceId ?? UIDeviceId.value,
            "state": state,
            "redirectUri": config.redirectUri,
            "platform": "ios",
            "bundleId": Bundle.main.bundleIdentifier ?? ""
        ]

        if let scope = config.scope, !scope.isEmpty {
            body["scope"] = scope
        }

        return body
    }

    private func makeURL(path: String) -> URL {
        config.current.apiBaseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    private static func parseUser(_ json: [String: Any]?) -> PGameUser? {
        guard let json else { return nil }
        return PGameUser(
            id: json["id"] as? String,
            username: json["username"] as? String,
            email: json["email"] as? String,
            phone: json["phone"] as? String
        )
    }

    private static func parseGame(_ json: [String: Any]?) -> PGameInfo? {
        guard let json else { return nil }
        return PGameInfo(
            id: json["id"] as? String,
            gameCode: json["gameCode"] as? String,
            name: json["name"] as? String
        )
    }
}

enum UIDeviceId {
    static var value: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    static var valueIfAvailable: String? {
        UIDevice.current.identifierForVendor?.uuidString
    }
}
