import UIKit
import AuthenticationServices

final class PGameNativeSocialProvider: NSObject {
    private let config: PGameConfig
    private var appleCompletion: ((Result<PGameAppleToken, PGameSDKError>) -> Void)?

    init(config: PGameConfig) {
        self.config = config
        super.init()
    }

    func loginGoogle(
        from viewController: UIViewController,
        completion: @escaping (Result<PGameGoogleToken, PGameSDKError>) -> Void
    ) {
//        guard !config.googleClientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            completion(.failure(.missingGoogleClientId))
//            return
//        }
//
//        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: config.googleClientId)
//
//        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
//            if let error = error {
//                completion(.failure(.social(error.localizedDescription)))
//                return
//            }
//
//            guard let user = result?.user,
//                  let idToken = user.idToken?.tokenString else {
//                completion(.failure(.social("Không lấy được Google idToken.")))
//                return
//            }
//
//            completion(.success(PGameGoogleToken(
//                idToken: idToken,
//                accessToken: user.accessToken.tokenString
//            )))
//        }
    }

    func loginApple(
        from viewController: UIViewController,
        completion: @escaping (Result<PGameAppleToken, PGameSDKError>) -> Void
    ) {
        appleCompletion = completion

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension PGameNativeSocialProvider: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            appleCompletion?(.failure(.social("Không lấy được Apple identityToken.")))
            appleCompletion = nil
            return
        }

        let authorizationCode: String?
        if let codeData = credential.authorizationCode {
            authorizationCode = String(data: codeData, encoding: .utf8)
        } else {
            authorizationCode = nil
        }

        var fullName: String? = nil
        if let name = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            fullName = formatter.string(from: name)
        }

        appleCompletion?(.success(PGameAppleToken(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            userIdentifier: credential.user,
            email: credential.email,
            fullName: fullName
        )))
        appleCompletion = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleCompletion?(.failure(.social(error.localizedDescription)))
        appleCompletion = nil
    }
}

extension PGameNativeSocialProvider: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
}
