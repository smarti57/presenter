import AppKit

protocol ReviewToolbarDelegate: AnyObject {
    func reviewToolbarDidPresent(_ toolbar: ReviewToolbarView)
    func reviewToolbar(_ toolbar: ReviewToolbarView, didSelectTransition style: TransitionStyle)
    func reviewToolbar(_ toolbar: ReviewToolbarView, didSelectMonitor index: Int)
}

final class ReviewToolbarView: NSView {
    weak var delegate: ReviewToolbarDelegate?

    private let slideCounterLabel = NSTextField(labelWithString: "")
    private let transitionPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let monitorPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let presentButton = NSButton(title: "Present", target: nil, action: nil)
    private var screenObserver: NSObjectProtocol?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        if let obs = screenObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9).cgColor

        slideCounterLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        slideCounterLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let transitionLabel = NSTextField(labelWithString: "Transition:")
        transitionLabel.font = NSFont.systemFont(ofSize: 12)
        transitionLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        for style in TransitionStyle.allCases {
            transitionPopup.addItem(withTitle: style.displayName)
        }
        transitionPopup.target = self
        transitionPopup.action = #selector(transitionChanged(_:))

        let monitorLabel = NSTextField(labelWithString: "Monitor:")
        monitorLabel.font = NSFont.systemFont(ofSize: 12)
        monitorLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        refreshMonitorPopup()

        monitorPopup.target = self
        monitorPopup.action = #selector(monitorChanged(_:))

        presentButton.bezelStyle = .rounded
        presentButton.controlSize = .large
        presentButton.keyEquivalent = "\r"
        presentButton.target = self
        presentButton.action = #selector(presentClicked(_:))

        let stack = NSStackView(views: [
            slideCounterLabel,
            spacerView(),
            transitionLabel, transitionPopup,
            monitorLabel, monitorPopup,
            spacerView(),
            presentButton,
        ])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 44),
        ])

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshMonitorPopup()
        }
    }

    func updateSlideCounter(current: Int, total: Int) {
        slideCounterLabel.stringValue = "Slide \(current + 1) of \(total)"
    }

    var selectedTransition: TransitionStyle {
        let index = transitionPopup.indexOfSelectedItem
        return TransitionStyle.allCases[index]
    }

    var selectedMonitorIndex: Int {
        return monitorPopup.indexOfSelectedItem
    }

    private func refreshMonitorPopup() {
        let previousSelection = monitorPopup.indexOfSelectedItem
        monitorPopup.removeAllItems()
        monitorPopup.addItem(withTitle: "Automatic")
        for screen in NSScreen.screens {
            monitorPopup.addItem(withTitle: screen.localizedName)
        }
        if previousSelection >= 0 && previousSelection < monitorPopup.numberOfItems {
            monitorPopup.selectItem(at: previousSelection)
        }
    }

    private func spacerView() -> NSView {
        let v = NSView()
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return v
    }

    @objc private func transitionChanged(_ sender: NSPopUpButton) {
        delegate?.reviewToolbar(self, didSelectTransition: selectedTransition)
    }

    @objc private func monitorChanged(_ sender: NSPopUpButton) {
        delegate?.reviewToolbar(self, didSelectMonitor: selectedMonitorIndex)
    }

    @objc private func presentClicked(_ sender: NSButton) {
        delegate?.reviewToolbarDidPresent(self)
    }
}
