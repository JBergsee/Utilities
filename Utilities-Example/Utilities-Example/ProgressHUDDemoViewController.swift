//
//  ProgressHUDDemoViewController.swift
//  Utilities-Example
//
//  Created for demonstrating ProgressHUD modes and options.
//

import UIKit
import Utilities

class ProgressHUDDemoViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private var progressTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ProgressHUD Demo"
        view.backgroundColor = .systemBackground
        setupLayout()
        addDemoButtons()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Demo Buttons

    private func addDemoButtons() {
        addSectionHeader("Modes")

        addButton("Indeterminate") { [weak self] in
            self?.showIndeterminate()
        }
        addButton("Annular Determinate (animated progress)") { [weak self] in
            self?.showAnnularDeterminate()
        }
        addButton("Horizontal Bar (animated progress)") { [weak self] in
            self?.showHorizontalBar()
        }
        addButton("Custom View — Checkmark") { [weak self] in
            self?.showCustomView(systemImage: "checkmark", label: "Done!")
        }
        addButton("Custom View — Error") { [weak self] in
            self?.showCustomView(systemImage: "xmark", label: "Failed")
        }

        addSectionHeader("Options")

        addButton("With Label") { [weak self] in
            self?.showWithLabel()
        }
        addButton("With Background Overlay") { [weak self] in
            self?.showWithBackground()
        }
        addButton("Square Shape") { [weak self] in
            self?.showSquare()
        }
        addButton("With Cancel Button") { [weak self] in
            self?.showWithButton()
        }

        addSectionHeader("Workflows")

        addButton("Simulated Download") { [weak self] in
            self?.showSimulatedDownload()
        }
        addButton("Mode Transition Sequence") { [weak self] in
            self?.showModeTransition()
        }
    }

    // MARK: - Mode Demos

    private func showIndeterminate() {
        let hud = ProgressHUD.show(in: view)
        hud.state.label = "Loading..."
        hideAfterDelay(2)
    }

    private func showAnnularDeterminate() {
        let hud = ProgressHUD.show(in: view)
        hud.state.mode = .annularDeterminate
        hud.state.label = "Uploading..."
        animateProgress(on: hud, duration: 3)
    }

    private func showHorizontalBar() {
        let hud = ProgressHUD.show(in: view)
        hud.state.mode = .horizontalBar
        hud.state.label = "Downloading..."
        animateProgress(on: hud, duration: 3)
    }

    private func showCustomView(systemImage: String, label: String) {
        let hud = ProgressHUD.show(in: view)
        hud.state.mode = .customView(systemImage: systemImage)
        hud.state.label = label
        hud.state.isSquare = true
        hideAfterDelay(2)
    }

    // MARK: - Option Demos

    private func showWithLabel() {
        let hud = ProgressHUD.show(in: view)
        hud.state.label = "Please wait..."
        hideAfterDelay(2)
    }

    private func showWithBackground() {
        let hud = ProgressHUD.show(in: view)
        hud.state.showsBackground = true
        hud.state.label = "Background overlay active"
        hideAfterDelay(2)
    }

    private func showSquare() {
        let hud = ProgressHUD.show(in: view)
        hud.state.isSquare = true
        hud.state.label = "Square"
        hideAfterDelay(2)
    }

    private func showWithButton() {
        let hud = ProgressHUD.show(in: view)
        hud.state.mode = .annularDeterminate
        hud.state.label = "Downloading..."
        hud.state.showsBackground = true
        hud.state.buttonTitle = "Cancel"
        hud.state.buttonAction = { [weak self] in
            guard let self else { return }
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            ProgressHUD.hide(for: self.view)
        }
        animateProgress(on: hud, duration: 10)
    }

    // MARK: - Workflow Demos

    private func showSimulatedDownload() {
        let hud = ProgressHUD.show(in: view)
        hud.state.showsBackground = true

        // Phase 1: Connecting
        hud.state.label = "Connecting..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Phase 2: Downloading with progress
            hud.state.mode = .horizontalBar
            hud.state.label = "Downloading..."
            self.animateProgress(on: hud, duration: 3) {
                // Phase 3: Done
                hud.state.mode = .customView(systemImage: "checkmark")
                hud.state.label = "Complete!"
                hud.state.isSquare = true
                self.hideAfterDelay(1.5)
            }
        }
    }

    private func showModeTransition() {
        let hud = ProgressHUD.show(in: view)
        hud.state.showsBackground = true
        hud.state.label = "Indeterminate"

        let modes: [(ProgressHUDMode, String)] = [
            (.annularDeterminate, "Annular Determinate"),
            (.horizontalBar, "Horizontal Bar"),
            (.customView(systemImage: "star.fill"), "Custom View"),
            (.indeterminate, "Back to Indeterminate"),
        ]

        for (index, (mode, label)) in modes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index + 1) * 1.5) {
                hud.state.mode = mode
                hud.state.label = label
                if mode == .annularDeterminate || mode == .horizontalBar {
                    hud.state.progress = 0.6
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(modes.count + 1) * 1.5) { [weak self] in
            guard let self else { return }
            ProgressHUD.hide(for: self.view)
        }
    }

    // MARK: - Helpers

    private func hideAfterDelay(_ delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            ProgressHUD.hide(for: self.view)
        }
    }

    private func animateProgress(on hud: ProgressHUD, duration: TimeInterval, completion: (() -> Void)? = nil) {
        progressTimer?.invalidate()
        hud.state.progress = 0

        let interval: TimeInterval = 0.05
        let increment = Float(interval / duration)

        progressTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            hud.state.progress += increment
            if hud.state.progress >= 1.0 {
                timer.invalidate()
                self?.progressTimer = nil
                if let completion {
                    completion()
                } else {
                    self?.hideAfterDelay(0.5)
                }
            }
        }
    }

    // MARK: - UI Factory

    private func addSectionHeader(_ title: String) {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel

        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        stackView.addArrangedSubview(spacer)
        stackView.addArrangedSubview(label)
    }

    private func addButton(_ title: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)

        var config = UIButton.Configuration.tinted()
        config.title = title
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        button.configuration = config

        stackView.addArrangedSubview(button)
    }
}
