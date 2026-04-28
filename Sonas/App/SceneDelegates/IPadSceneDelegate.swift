import UIKit

/// Scene delegate for iPad-specific window management.
class IPadSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Stage Manager compatibility: set minimum window size (FR-010)
        // 320pt is the minimum Slide Over width, 400pt is a reasonable minimum height.
        #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                windowScene.sizeRestrictions?.minimumSize = CGSize(width: 320, height: 400)
            }
        #endif
    }
}
