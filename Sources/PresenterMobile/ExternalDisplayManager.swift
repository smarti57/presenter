#if os(iOS)
import UIKit
import SwiftUI

@Observable
final class ExternalDisplayManager {
    var externalScene: UIWindowScene?
    private var externalWindow: UIWindow?
    private var observers: [NSObjectProtocol] = []

    init() {
        let connectObserver = NotificationCenter.default.addObserver(
            forName: UIScene.willConnectNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            guard let scene = notification.object as? UIWindowScene,
                  scene.session.role == .windowExternalDisplayNonInteractive else { return }
            self?.externalScene = scene
        }

        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            guard let scene = notification.object as? UIWindowScene,
                  scene == self?.externalScene else { return }
            self?.tearDown()
        }

        observers = [connectObserver, disconnectObserver]

        // Check for already-connected external scenes
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               windowScene.session.role == .windowExternalDisplayNonInteractive {
                externalScene = windowScene
                break
            }
        }
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var isExternalDisplayConnected: Bool {
        externalScene != nil
    }

    func showOnExternal(state: PresentationState) {
        guard let scene = externalScene else { return }

        let window = UIWindow(windowScene: scene)
        let hostingController = UIHostingController(
            rootView: ExternalSlideView()
                .environment(state)
        )
        window.rootViewController = hostingController
        window.isHidden = false
        self.externalWindow = window
    }

    func tearDown() {
        externalWindow?.isHidden = true
        externalWindow = nil
        externalScene = nil
    }
}

struct ExternalSlideView: View {
    @Environment(PresentationState.self) private var state

    var body: some View {
        ZStack {
            Color.black
            if let cache = state.cache,
               let image = cache.image(forPage: state.currentSlideIndex) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .ignoresSafeArea()
    }
}
#endif
