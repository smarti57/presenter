#if os(iOS)
import SwiftUI

struct ReviewView: View {
    @Environment(PresentationState.self) private var state
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            ThumbnailSidebar()
                .frame(width: 200)

            Divider()

            VStack(spacing: 0) {
                reviewToolbar
                SlideImageView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fullScreenCover(isPresented: Bindable(state).isPresenting) {
            SlidePresenterView()
                .environment(state)
        }
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            SlideImageView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            reviewToolbar

            ThumbnailStrip()
                .frame(height: 100)
        }
        .fullScreenCover(isPresented: Bindable(state).isPresenting) {
            SlidePresenterView()
                .environment(state)
        }
    }

    // MARK: - Toolbar

    private var reviewToolbar: some View {
        HStack(spacing: 12) {
            Text("Slide \(state.currentSlideIndex + 1) of \(state.pageCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Transition", selection: Bindable(state).selectedTransition) {
                ForEach(TransitionStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            Button {
                state.isPresenting = true
            } label: {
                Label("Present", systemImage: "play.fill")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - Thumbnail Sidebar (iPad)

struct ThumbnailSidebar: View {
    @Environment(PresentationState.self) private var state

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(0..<state.pageCount, id: \.self) { index in
                        ThumbnailCell(index: index)
                            .id(index)
                    }
                }
                .padding(8)
            }
            .onChange(of: state.currentSlideIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Thumbnail Strip (iPhone)

struct ThumbnailStrip: View {
    @Environment(PresentationState.self) private var state

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(0..<state.pageCount, id: \.self) { index in
                        ThumbnailCell(index: index, compact: true)
                            .id(index)
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(.bar)
            .onChange(of: state.currentSlideIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Thumbnail Cell

struct ThumbnailCell: View {
    @Environment(PresentationState.self) private var state
    let index: Int
    var compact: Bool = false

    var body: some View {
        let isSelected = state.currentSlideIndex == index
        let aspect = state.cache?.pageAspectRatio ?? (16.0 / 9.0)

        Button {
            state.selectSlide(index)
        } label: {
            VStack(spacing: 2) {
                if let image = state.thumbnailImage(for: index, fitting: CGSize(width: 360, height: 360)) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(aspect, contentMode: .fit)
                }

                if !compact {
                    Text("\(index + 1)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slide Image View

struct SlideImageView: View {
    @Environment(PresentationState.self) private var state

    var body: some View {
        GeometryReader { geo in
            let aspect = state.cache?.pageAspectRatio ?? (16.0 / 9.0)
            let fitSize = fitRect(aspect: aspect, in: geo.size)

            ZStack {
                Color(uiColor: .systemGray6)

                if let image = state.cache?.image(forPage: state.currentSlideIndex) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: fitSize.width, height: fitSize.height)
                }
            }
        }
    }

    private func fitRect(aspect: CGFloat, in container: CGSize) -> CGSize {
        let containerAspect = container.width / max(container.height, 1)
        if aspect > containerAspect {
            let w = container.width
            return CGSize(width: w, height: w / aspect)
        } else {
            let h = container.height
            return CGSize(width: h * aspect, height: h)
        }
    }
}
#endif
