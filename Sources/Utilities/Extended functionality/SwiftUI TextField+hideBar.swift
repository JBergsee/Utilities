//
//  SwiftUI TextField+hideBar.swift
//
//
//  Created by Johan Nyman on 2026-07-20.
//

import SwiftUI
import UIKit

public extension View {

    /// Hides the bar above the keyboard (the input assistant bar with shortcuts and typing suggestions)
    /// for a SwiftUI `TextField`, mirroring `UITextField.hideBar()`.
    ///
    /// The bar only exists on iPad, so this has no visible effect on iPhone.
    /// Apply it to each text field individually.
    ///
    /// - Note: SwiftUI has no native access to `inputAssistantItem`, so this finds the
    ///   `UITextField` backing the SwiftUI field and configures it. If a future iOS version
    ///   stops backing `TextField` with `UITextField`, this degrades to a no-op.
    func hideBar() -> some View {
        modifier(HideBarModifier())
    }
}

private struct HideBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Removes the typing suggestions in the middle of the bar,
            // the declarative equivalent of autocorrectionType = .no in UITextField.hideBar().
            .autocorrectionDisabled()
            .background(TextFieldIntrospector { $0.hideBar() })
    }
}

/// An invisible view that locates the `UITextField` backing the SwiftUI field
/// it is attached to (as a background) and configures it.
private struct TextFieldIntrospector: UIViewRepresentable {

    let configure: (UITextField) -> Void

    func makeUIView(context: Context) -> IntrospectionView {
        let view = IntrospectionView()
        view.configure = configure
        return view
    }

    func updateUIView(_ uiView: IntrospectionView, context: Context) {
        // SwiftUI may reconfigure or replace the backing text field on state changes,
        // so reapply the configuration on every update.
        uiView.configureTextField()
    }

    final class IntrospectionView: UIView {

        var configure: ((UITextField) -> Void)?

        init() {
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            accessibilityElementsHidden = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            configureTextField()
        }

        func configureTextField() {
            // The backing text field may not exist until the current layout pass has finished,
            // and configuring must not happen during a SwiftUI view update.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil,
                      let textField = self.nearestTextField() else { return }
                self.configure?(textField)
            }
        }

        /// Walks up a bounded number of ancestors, searching each subtree breadth-first,
        /// and returns the nearest `UITextField`. Starting from the closest ancestor
        /// avoids grabbing another text field elsewhere on screen.
        private func nearestTextField() -> UITextField? {
            var ancestor = superview
            for _ in 0..<5 {
                guard let root = ancestor else { return nil }
                if let textField = root.firstTextFieldInSubtree() {
                    return textField
                }
                ancestor = root.superview
            }
            return nil
        }
    }
}

private extension UIView {
    func firstTextFieldInSubtree() -> UITextField? {
        var queue: [UIView] = [self]
        while !queue.isEmpty {
            let view = queue.removeFirst()
            if let textField = view as? UITextField {
                return textField
            }
            queue.append(contentsOf: view.subviews)
        }
        return nil
    }
}

#Preview {
    struct HideBarPreview: View {
        @State private var hidden = ""
        @State private var standard = ""

        var body: some View {
            Form {
                TextField("Bar hidden", text: $hidden)
                    .hideBar()
                TextField("Standard bar", text: $standard)
            }
        }
    }
    return HideBarPreview()
}
