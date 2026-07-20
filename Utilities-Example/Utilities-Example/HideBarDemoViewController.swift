//
//  HideBarDemoViewController.swift
//  Utilities-Example
//
//  Created by Claude on 2026-07-20.
//

import UIKit
import SwiftUI
import Utilities

// MARK: - Demo View Controller

/// Hosts the SwiftUI `HideBarDemoView` inside a `UIHostingController`.
class HideBarDemoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hide Keyboard Bar Demo"

        let hostingController = UIHostingController(rootView: HideBarDemoView())
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
    }
}

// MARK: - Demo SwiftUI View

private struct HideBarDemoView: View {

    @State private var hidden = ""
    @State private var standard = ""
    @State private var uiKitText = ""

    var body: some View {
        Form {
            Section {
                TextField("Tap here — no bar above the keyboard", text: $hidden)
                    .hideBar()
            } header: {
                Text("SwiftUI TextField with .hideBar()")
            } footer: {
                Text("The input assistant bar only exists on iPad, so run this demo on an iPad. Disconnect the hardware keyboard in the simulator (⇧⌘K) to show the software keyboard.")
            }

            Section("Standard SwiftUI TextField") {
                TextField("Tap here — shortcuts bar appears", text: $standard)
            }

            Section("UITextField with hideBar()") {
                HideBarUITextField(text: $uiKitText)
            }
        }
    }
}

/// A plain `UITextField` using the original UIKit `hideBar()` extension, for comparison.
private struct HideBarUITextField: UIViewRepresentable {

    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = "Tap here — no bar above the keyboard"
        textField.hideBar()
        textField.addTarget(context.coordinator,
                            action: #selector(Coordinator.textChanged(_:)),
                            for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func textChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }
    }
}
