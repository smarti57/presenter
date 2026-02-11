#if os(iOS)
import QuartzCore

enum TransitionDirection {
    case forward
    case backward

    var subtypeValue: CATransitionSubtype {
        switch self {
        case .forward:  return .fromRight
        case .backward: return .fromLeft
        }
    }
}

enum TransitionStyle: String, CaseIterable, Identifiable {
    case fade
    case push
    case reveal
    case moveIn
    case cube
    case flip

    var id: String { rawValue }
    var displayName: String { rawValue }

    func makeTransition(direction: TransitionDirection) -> CATransition {
        let t = CATransition()
        t.duration = 0.6
        t.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        switch self {
        case .fade:
            t.type = .fade
        case .push:
            t.type = .push
            t.subtype = direction.subtypeValue
        case .reveal:
            t.type = .reveal
            t.subtype = direction.subtypeValue
        case .moveIn:
            t.type = .moveIn
            t.subtype = direction.subtypeValue
        case .cube:
            t.type = CATransitionType(rawValue: "cube")
            t.subtype = direction.subtypeValue
        case .flip:
            t.type = CATransitionType(rawValue: "oglFlip")
            t.subtype = direction.subtypeValue
        }

        return t
    }
}
#endif
