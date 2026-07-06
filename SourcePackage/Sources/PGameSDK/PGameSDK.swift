import UIKit

@objc(PGameSDK)
public final class PGameSDKClient: NSObject {
    @objc public static let shared = PGameSDKClient()
    @objc public static let sdkVersion = "1.3.0"

    private var config: PGameConfig?

    private override init() {
        super.init()
    }

    @objc public func configure(_ config: PGameConfig) {
        self.config = config
    }

    public func showLogin(
        from viewController: UIViewController,
        completion: @escaping (Result<PGameLoginResult, PGameSDKError>) -> Void
    ) {
        guard let config else {
            completion(.failure(.notConfigured))
            return
        }

        let state = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let api = PGameAPIClient(config: config)
        let social = PGameNativeSocialProvider(config: config)

        let loginVC = PGameLoginViewController(
            config: config,
            api: api,
            social: social,
            state: state,
            completion: completion
        )

        viewController.present(loginVC, animated: true)
    }

    public func refreshToken(
        _ refreshToken: String,
        completion: @escaping (Result<PGameTokenResult, PGameSDKError>) -> Void
    ) {
        guard let config else {
            completion(.failure(.notConfigured))
            return
        }

        PGameAPIClient(config: config).refreshToken(refreshToken, completion: completion)
    }

    public func revoke(
        refreshToken: String,
        completion: @escaping (Result<Void, PGameSDKError>) -> Void
    ) {
        guard let config else {
            completion(.failure(.notConfigured))
            return
        }

        PGameAPIClient(config: config).revoke(refreshToken: refreshToken, completion: completion)
    }

    public func userInfo(
        accessToken: String,
        completion: @escaping (Result<[String: Any], PGameSDKError>) -> Void
    ) {
        guard let config else {
            completion(.failure(.notConfigured))
            return
        }

        PGameAPIClient(config: config).userInfo(accessToken: accessToken, completion: completion)
    }

    @objc public func showLogin(
        from viewController: UIViewController,
        completion: @escaping (PGameLoginResultObjC?, NSError?) -> Void
    ) {
        showLogin(from: viewController) { result in
            switch result {
            case .success(let login):
                completion(
                    PGameLoginResultObjC(
                        code: login.code,
                        state: login.state,
                        redirectUri: login.redirectUri,
                        user: login.user,
                        game: login.game,
                        token: login.token
                    ),
                    nil
                )
            case .failure(let error):
                completion(nil, error.nsError)
            }
        }
    }
}
