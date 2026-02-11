#if os(iOS)
import SwiftUI
import QuartzCore

struct SlidePresenterView: View {
    @Environment(PresentationState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SlideHostViewRepresentable(state: state, onDismiss: { dismiss() })
            .ignoresSafeArea()
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
    }
}

// MARK: - UIViewRepresentable

struct SlideHostViewRepresentable: UIViewRepresentable {
    let state: PresentationState
    let onDismiss: () -> Void

    func makeUIView(context: Context) -> SlideHostView {
        let view = SlideHostView()
        view.onDismiss = onDismiss
        view.state = state
        view.showSlide(at: state.currentSlideIndex, transition: nil)
        return view
    }

    func updateUIView(_ uiView: SlideHostView, context: Context) {}
}

// MARK: - SlideHostView (UIView with CALayer transitions)

final class SlideHostView: UIView {
    var state: PresentationState?
    var onDismiss: (() -> Void)?
    private let imageLayer = CALayer()
    private var currentIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .black

        imageLayer.contentsGravity = .resizeAspect
        imageLayer.frame = bounds
        layer.addSublayer(imageLayer)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown(_:)))
        swipeDown.direction = .down
        addGestureRecognizer(swipeDown)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.require(toFail: swipeLeft)
        tap.require(toFail: swipeRight)
        tap.require(toFail: swipeDown)
        addGestureRecognizer(tap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageLayer.frame = bounds
    }

    func showSlide(at index: Int, transition: CATransition?) {
        guard let state = state, let cache = state.cache else { return }
        guard index >= 0, index < state.pageCount else { return }

        currentIndex = index
        state.currentSlideIndex = index

        cache.updateRenderSize(bounds.size)

        if let image = cache.image(forPage: index) {
            if let transition = transition {
                imageLayer.add(transition, forKey: kCATransition)
            }
            imageLayer.contents = image.cgImage
        }

        DispatchQueue.global(qos: .userInitiated).async {
            cache.preloadNeighbors(of: index)
        }
    }

    private func nextSlide() {
        guard let state = state else { return }
        if currentIndex < state.pageCount - 1 {
            let transition = state.selectedTransition.makeTransition(direction: .forward)
            showSlide(at: currentIndex + 1, transition: transition)
        }
    }

    private func previousSlide() {
        if currentIndex > 0 {
            guard let state = state else { return }
            let transition = state.selectedTransition.makeTransition(direction: .backward)
            showSlide(at: currentIndex - 1, transition: transition)
        }
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:  nextSlide()
        case .right: previousSlide()
        default: break
        }
    }

    @objc private func handleSwipeDown(_ gesture: UISwipeGestureRecognizer) {
        onDismiss?()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        nextSlide()
    }
}
#endif
