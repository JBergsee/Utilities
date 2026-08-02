//
//  NetworkMonitorDemoViewController.swift
//  Utilities-Example
//
//  Demonstrates the three ways to consume NetworkMonitor:
//  notifications, the async status stream, and a synchronous isOnline check.
//

import UIKit
import Utilities

class NetworkMonitorDemoViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let notificationStatusLabel = UILabel()
    private let streamStatusLabel = UILabel()

    private var streamTask: Task<Void, Never>?
    private var connectivityObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "NetworkMonitor Demo"
        view.backgroundColor = .systemBackground
        setupLayout()
        addSections()
        startObserving()
    }

    deinit {
        streamTask?.cancel()
        if let connectivityObserver {
            NotificationCenter.default.removeObserver(connectivityObserver)
        }
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

    // MARK: - Sections

    private func addSections() {
        addSectionHeader("Notifications")
        addDescription("Observes .ConnectivityDidChange and re-reads currentStatus.")
        stackView.addArrangedSubview(notificationStatusLabel)
        configureStatusLabel(notificationStatusLabel)

        addSectionHeader("Async Stream")
        addDescription("Iterates statusUpdates and updates live.")
        stackView.addArrangedSubview(streamStatusLabel)
        configureStatusLabel(streamStatusLabel)

        addSectionHeader("Synchronous check")
        addDescription("Reads isOnline on demand and shows the result in an alert.")
        addButton("Check isOnline") { [weak self] in
            self?.checkIsOnline()
        }

        addFooter("Network notifications are unreliable on the Simulator — test connectivity changes on a real device.")

        // Seed both labels with the current status on load.
        let status = NetworkMonitor.shared.currentStatus
        render(status, in: notificationStatusLabel)
        render(status, in: streamStatusLabel)
    }

    // MARK: - Consuming NetworkMonitor

    private func startObserving() {
        // 1) Notifications — posted from a background context, so observe on .main.
        connectivityObserver = NotificationCenter.default.addObserver(
            forName: .ConnectivityDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.render(NetworkMonitor.shared.currentStatus, in: self.notificationStatusLabel)
        }

        // 2) Async stream — replays the current status immediately, then yields on change.
        streamTask = Task { [weak self] in
            for await status in NetworkMonitor.shared.statusUpdates {
                await MainActor.run {
                    self?.render(status, in: self?.streamStatusLabel)
                }
            }
        }
    }

    // 3) Synchronous — read isOnline and present an alert.
    private func checkIsOnline() {
        let isOnline = NetworkMonitor.shared.isOnline
        showAlert(title: "Network Status",
                  message: isOnline ? "You are online." : "You are offline.",
                  buttonTitle: "OK")
    }

    // MARK: - Status Rendering

    private func render(_ status: ConnectivityStatus, in label: UILabel?) {
        guard let label else { return }
        label.text = "Current status: \(status.description)"
        switch status {
        case .connected:    label.textColor = .systemGreen
        case .notConnected: label.textColor = .systemRed
        case .unknown:      label.textColor = .secondaryLabel
        }
    }

    // MARK: - UI Factory

    private func configureStatusLabel(_ label: UILabel) {
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
    }

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

    private func addDescription(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
    }

    private func addFooter(_ text: String) {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
        stackView.addArrangedSubview(spacer)

        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
    }

    private func addButton(_ title: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
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
