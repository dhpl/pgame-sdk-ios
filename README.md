# PGameSDK iOS

PGameSDK iOS duoc dong goi san duoi dang `PGameSDK.xcframework` va phan phoi qua Swift Package Manager. App tich hop chi can add GitHub package, link product `PGameSDK`, sau do `import PGameSDK`.

## Yeu cau

- iOS 13.0 tro len
- Xcode ho tro Swift Package Manager
- Swift tools 5.9 tro len neu muon build lai tu source

## Cai dat bang Swift Package Manager

Trong Xcode:

1. Chon `File > Add Package Dependencies...`
2. Nhap URL:

```text
git@github.com:dhpl/pgame-sdk-ios.git
```

3. Chon product `PGameSDK` va add vao app target.

Neu dung `Package.swift`:

```swift
.package(url: "git@github.com:dhpl/pgame-sdk-ios.git", from: "1.3.0")
```

va them dependency vao target:

```swift
.product(name: "PGameSDK", package: "pgame-sdk-ios")
```

## Cau hinh app

Them URL Scheme cho app trong `Info > URL Types`. Gia tri scheme phai trung voi `redirectScheme` khi configure SDK.

Vi du voi `redirectScheme = "mygame"`, redirect URI cua SDK se la:

```text
mygame://pgame-callback
```

## Su dung Swift

```swift
import UIKit
import PGameSDK

final class LoginViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let config = PGameConfig(
            environment: .sandbox,
            clientId: "YOUR_CLIENT_ID",
            gameCode: "YOUR_GAME_CODE",
            redirectScheme: "mygame"
        )

        PGameSDKClient.shared.configure(config)
    }

    func openLogin() {
        PGameSDKClient.shared.showLogin(from: self) { result in
            switch result {
            case .success(let login):
                print("code:", login.code)
                print("accessToken:", login.accessToken ?? "")
            case .failure(let error):
                print("PGameSDK error:", error.localizedDescription)
            }
        }
    }
}
```

## API chinh

- `configure(_:)`: cau hinh environment, client id, game code va redirect scheme.
- `showLogin(from:completion:)`: hien UI dang nhap PGame va tra ve authorization code/token.
- `refreshToken(_:completion:)`: refresh access token.
- `revoke(refreshToken:completion:)`: revoke refresh token.
- `userInfo(accessToken:completion:)`: lay thong tin user tu access token.

## Build lai xcframework

Repo nay co source package nam trong `SourcePackage/`. Chay script sau de build lai `PGameSDK.xcframework` cho iOS device va iOS Simulator:

```bash
./Scripts/build-xcframework.sh
```

Output se nam tai:

```text
PGameSDK.xcframework
```

Script build voi:

- `SKIP_INSTALL=NO`
- `BUILD_LIBRARY_FOR_DISTRIBUTION=YES`
- device destination: `generic/platform=iOS`
- simulator destination: `generic/platform=iOS Simulator`

Sau khi build lai, commit cac thay doi:

```bash
git add PGameSDK.xcframework SourcePackage Package.swift README.md Scripts/build-xcframework.sh
git commit -m "Release PGameSDK 1.3.0"
git tag 1.3.0
git push origin main --tags
```

## Ghi chu ve Objective-C

Swift entrypoint la `PGameSDKClient.shared`. Objective-C runtime name duoc giu la `PGameSDK`, nen Objective-C app co the import generated Swift header cua framework va goi class `PGameSDK`.
