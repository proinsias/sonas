import SwiftUI

// MARK: - Accessibility convenience modifiers

// Applied to all interactive controls in every panel. Constitution §III requires
// .accessibilityLabel and .accessibilityHint on all interactive controls.

extension View {
    /// Attach a semantic accessibility label and optional hint to this view.
    /// - Parameters:
    ///   - label: Concise description of what this element is (read by VoiceOver).
    ///   - hint: Brief description of the result of activating this element (optional).
    func accessibilityInfo(_ label: String, hint: String? = nil) -> some View {
        accessibilityLabel(label)
            .modifier(OptionalHintModifier(hint: hint))
    }

    /// Mark a view as a panel container for accessibility grouping.
    func accessibilityPanel(label: String) -> some View {
        accessibilityElement(children: .contain)
            .accessibilityLabel(label)
    }

    /// Apply standard loading state accessibility label.
    func accessibilityLoading(_ panelName: String) -> some View {
        accessibilityLabel("\(panelName) panel is loading")
    }

    /// Apply standard error state accessibility label.
    func accessibilityError(_ panelName: String, message: String) -> some View {
        accessibilityLabel("\(panelName) panel error: \(message)")
    }
}

// MARK: - Private helpers

private struct OptionalHintModifier: ViewModifier {
    let hint: String?
    func body(content: Content) -> some View {
        if let hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}
