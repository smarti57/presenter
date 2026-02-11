#if os(iOS)
import SwiftUI

struct LandingView: View {
    let onOpenTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            Text("Presenter")
                .font(.largeTitle.bold())

            Text("Open a PDF to start presenting")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onOpenTapped) {
                Label("Open PDF", systemImage: "folder")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
#endif
