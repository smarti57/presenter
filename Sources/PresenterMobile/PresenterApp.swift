#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

@main
struct PresenterApp: App {
    @State private var state = PresentationState()
    @State private var showFilePicker = false

    var body: some Scene {
        WindowGroup {
            Group {
                if state.document != nil {
                    ReviewView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    showFilePicker = true
                                } label: {
                                    Label("Open", systemImage: "folder")
                                }
                            }
                        }
                } else {
                    LandingView {
                        showFilePicker = true
                    }
                }
            }
            .environment(state)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    state.openPDF(at: url)
                }
            }
        }
    }
}

#else
// Stub so this target compiles on macOS (no-op)
@main enum PresenterMobileStub {
    static func main() {
        print("PresenterMobile is an iOS app. Run on an iOS device or simulator.")
    }
}
#endif
