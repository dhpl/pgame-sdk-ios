import UIKit

final class PGameLoginViewController: UIViewController {
    private let config: PGameConfig
    private let api: PGameAPIClient
    private let social: PGameNativeSocialProvider
    private let state: String
    private let completion: (Result<PGameLoginResult, PGameSDKError>) -> Void

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let registerButton = UIButton(type: .system)
    private let accountField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let forgotButton = UIButton(type: .system)
    private let socialTitle = UILabel()
    private let googleButton = UIButton(type: .system)
    private let appleButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    private let leftStack = UIStackView()
    private let rightStack = UIStackView()
    private let contentStack = UIStackView()

    private var cardWidthConstraint: NSLayoutConstraint?
    private var cardCenterYConstraint: NSLayoutConstraint?
    private var cardTopConstraint: NSLayoutConstraint?

    private var didSetupInitialLayout = false
    
    private var lastIsLandscape: Bool?

    init(
        config: PGameConfig,
        api: PGameAPIClient,
        social: PGameNativeSocialProvider,
        state: String,
        completion: @escaping (Result<PGameLoginResult, PGameSDKError>) -> Void
    ) {
        self.config = config
        self.api = api
        self.social = social
        self.state = state
        self.completion = completion
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateResponsiveLayout()

        if !didSetupInitialLayout {
            didSetupInitialLayout = true
            view.layoutIfNeeded()
        }
    }

    private func buildUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.65)

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 8
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .regular)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 16
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.white.cgColor
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        titleLabel.text = "Đăng nhập PGame"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .black

        registerButton.setTitle("Đăng ký", for: .normal)
        registerButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        registerButton.tintColor = UIColor(red: 1, green: 0.38, blue: 0.18, alpha: 1)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        accountField.placeholder = "Tên đăng nhập"
        accountField.borderStyle = .roundedRect
        accountField.autocapitalizationType = .none
        accountField.keyboardType = .emailAddress
        accountField.heightAnchor.constraint(equalToConstant: 52).isActive = true

        passwordField.placeholder = "Mật khẩu"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        passwordField.heightAnchor.constraint(equalToConstant: 52).isActive = true

        loginButton.setTitle("Đăng nhập", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = UIColor(red: 1, green: 0.40, blue: 0.20, alpha: 1)
        loginButton.layer.cornerRadius = 6
        loginButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        loginButton.addTarget(self, action: #selector(accountLoginTapped), for: .touchUpInside)

        forgotButton.setTitle("Quên mật khẩu?", for: .normal)
        forgotButton.tintColor = UIColor(red: 1, green: 0.38, blue: 0.18, alpha: 1)
        forgotButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        forgotButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        socialTitle.text = "Đăng nhập bằng"
        socialTitle.font = .systemFont(ofSize: 18, weight: .medium)
        socialTitle.textColor = .black
        socialTitle.textAlignment = .center

        setupSocialButton(
            googleButton,
            title: "G   Đăng nhập bằng Google",
            bg: .white,
            fg: .darkGray,
            border: true
        )

        setupSocialButton(
            appleButton,
            title: "   Đăng nhập bằng Apple",
            bg: .black,
            fg: .white
        )

        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(appleTapped), for: .touchUpInside)

        leftStack.axis = .vertical
        leftStack.spacing = 16
        leftStack.alignment = .fill
        leftStack.distribution = .fill
        leftStack.addArrangedSubview(headerRow())
        leftStack.addArrangedSubview(accountField)
        leftStack.addArrangedSubview(passwordField)
        leftStack.addArrangedSubview(loginButton)
        leftStack.addArrangedSubview(forgotButton)

        rightStack.axis = .vertical
        rightStack.spacing = 12
        rightStack.alignment = .fill
        rightStack.distribution = .fill
        rightStack.addArrangedSubview(socialTitle)
        rightStack.addArrangedSubview(googleButton)
        rightStack.addArrangedSubview(appleButton)

        leftStack.setContentHuggingPriority(.required, for: .vertical)
        rightStack.setContentHuggingPriority(.required, for: .vertical)
        leftStack.setContentCompressionResistancePriority(.required, for: .vertical)
        rightStack.setContentCompressionResistancePriority(.required, for: .vertical)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.spacing = 28
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        cardView.addSubview(contentStack)

        cardWidthConstraint = cardView.widthAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.widthAnchor,
            multiplier: 0.90
        )
        cardWidthConstraint?.priority = .defaultHigh
        cardWidthConstraint?.isActive = true

        cardCenterYConstraint = cardView.centerYAnchor.constraint(
            equalTo: view.centerYAnchor
        )

        cardTopConstraint = cardView.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: 36
        )

        cardCenterYConstraint?.isActive = true
        cardTopConstraint?.isActive = false

        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cardView.widthAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor,
                constant: -40
            ),

            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 920),

            cardView.heightAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                constant: -48
            ),

            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            closeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 12),
            closeButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: -12),

            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -28),
        ])

        updateResponsiveLayout()
    }

    private func updateResponsiveLayout() {
        updateCardSize()

        let isLandscape = view.bounds.width > view.bounds.height

        // Không rebuild stack nếu orientation không đổi.
        // Nếu rebuild liên tục, UITextField bị remove khỏi hierarchy => mất focus => đóng bàn phím.
        guard lastIsLandscape != isLandscape || contentStack.arrangedSubviews.isEmpty else {
            return
        }

        lastIsLandscape = isLandscape

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if isLandscape {
            contentStack.axis = .horizontal
            contentStack.distribution = .fillEqually
            contentStack.alignment = .top
            contentStack.spacing = 32

            leftStack.alignment = .fill
            rightStack.alignment = .fill

            socialTitle.textAlignment = .center

            contentStack.addArrangedSubview(leftStack)
            contentStack.addArrangedSubview(rightStack)

            leftStack.setContentHuggingPriority(.required, for: .vertical)
            rightStack.setContentHuggingPriority(.required, for: .vertical)

        } else {
            contentStack.axis = .vertical
            contentStack.distribution = .fill
            contentStack.alignment = .fill
            contentStack.spacing = 24

            leftStack.alignment = .fill
            rightStack.alignment = .fill

            socialTitle.textAlignment = .left

            contentStack.addArrangedSubview(leftStack)
            contentStack.addArrangedSubview(rightStack)
        }
    }

    private func updateCardSize() {
        let isLandscape = view.bounds.width > view.bounds.height

        cardWidthConstraint?.isActive = false
        cardCenterYConstraint?.isActive = false
        cardTopConstraint?.isActive = false

        if isLandscape {
            cardTopConstraint?.constant = 36
            cardTopConstraint?.isActive = true

            cardWidthConstraint = cardView.widthAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.widthAnchor,
                multiplier: 0.86
            )
        } else {
            cardCenterYConstraint?.isActive = true

            cardWidthConstraint = cardView.widthAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.widthAnchor,
                multiplier: 0.90
            )
        }

        cardWidthConstraint?.priority = .defaultHigh
        cardWidthConstraint?.isActive = true
    }

    private func headerRow() -> UIStackView {
        let spacer = UIView()
        let row = UIStackView(arrangedSubviews: [titleLabel, spacer, registerButton])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        row.distribution = .fill
        return row
    }

    private func setupSocialButton(
        _ button: UIButton,
        title: String,
        bg: UIColor,
        fg: UIColor,
        border: Bool = false
    ) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.setTitleColor(fg, for: .normal)
        button.backgroundColor = bg
        button.layer.cornerRadius = 6
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true

        if border {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(white: 0.82, alpha: 1).cgColor
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true) { [completion] in
            completion(.failure(.userCancelled))
        }
    }

    @objc private func registerTapped() {
        openWebPage(path: "sdk/register")
    }

    @objc private func forgotPasswordTapped() {
        openWebPage(path: "forgot")
    }

    private func openWebPage(path: String) {
        let redirectUri = config.redirectUri

        var components = URLComponents(
            url: config.current.webBaseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "game_code", value: config.gameCode),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "platform", value: "ios"),
            URLQueryItem(name: "state", value: state)
        ]

        guard let url = components?.url else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @objc private func accountLoginTapped() {
        let account = accountField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""

        guard !account.isEmpty, !password.isEmpty else {
            showAlert(message: "Vui lòng nhập tài khoản và mật khẩu.")
            return
        }

        setLoading(true)

        api.loginAccount(account: account, password: password, state: state) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                self.setLoading(false)
                self.finish(result)
            }
        }
    }

    @objc private func googleTapped() {
        showAlert(message: "Hiện tại chưa hỗ trợ.")
//        setLoading(true)
//
//        social.loginGoogle(from: self) { [weak self] tokenResult in
//            guard let self else { return }
//
//            DispatchQueue.main.async {
//                switch tokenResult {
//                case .success(let googleToken):
//                    self.api.loginGoogle(token: googleToken, state: self.state) { result in
//                        DispatchQueue.main.async {
//                            self.setLoading(false)
//                            self.finish(result)
//                        }
//                    }
//
//                case .failure(let error):
//                    self.setLoading(false)
//                    self.finish(.failure(error))
//                }
//            }
//        }
    }

    @objc private func appleTapped() {
        showAlert(message: "Hiện tại chưa hỗ trợ.")
//        setLoading(true)
//
//        social.loginApple(from: self) { [weak self] tokenResult in
//            guard let self else { return }
//
//            DispatchQueue.main.async {
//                switch tokenResult {
//                case .success(let appleToken):
//                    self.api.loginApple(token: appleToken, state: self.state) { result in
//                        DispatchQueue.main.async {
//                            self.setLoading(false)
//                            self.finish(result)
//                        }
//                    }
//
//                case .failure(let error):
//                    self.setLoading(false)
//                    self.finish(.failure(error))
//                }
//            }
//        }
    }

    private func setLoading(_ loading: Bool) {
        [
            loginButton,
            googleButton,
            appleButton,
            registerButton,
            forgotButton
        ].forEach {
            $0.isEnabled = !loading
        }

        loginButton.setTitle(loading ? "Đang xử lý..." : "Đăng nhập", for: .normal)
    }

    private func finish(_ result: Result<PGameLoginResult, PGameSDKError>) {
        switch result {
        case .success:
            dismiss(animated: true) { [completion] in
                completion(result)
            }

        case .failure(let error):
            showAlert(message: error.localizedDescription)
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "PGame",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "OK", style: .default)
        )

        present(alert, animated: true)
    }
}
