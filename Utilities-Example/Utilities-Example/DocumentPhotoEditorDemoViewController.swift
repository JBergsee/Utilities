//
//  DocumentPhotoEditorDemoViewController.swift
//  Utilities-Example
//
//  Created by Claude on 2026-09-11.
//

import UIKit
import SwiftUI
import Utilities

/// Demonstrates `DocumentPhotoEditor.present(image:over:)` from both a UIKit
/// call site (this view controller, passing `self` directly) and a SwiftUI
/// call site (the embedded `SwiftUICallSiteView`, via `capturingHostingController`),
/// against the same source image — exercising both halves of the unified async API.
class DocumentPhotoEditorDemoViewController: UIViewController {

    // MARK: - UI

    private var sourceImage: UIImage = DocumentPhotoEditorDemoViewController.makeTestDocumentImage() {
        didSet {
            sourceImageView.image = sourceImage
        }
    }

    private let sourceImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.layer.cornerRadius = 8
        return iv
    }()

    private let resultImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.layer.cornerRadius = 8
        return iv
    }()

    private let sourceLabel = DocumentPhotoEditorDemoViewController.makeCaptionLabel(
        "Source (synthetic 12 MP test page)")
    private let resultLabel = DocumentPhotoEditorDemoViewController.makeCaptionLabel("Result")

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var pickPhotoButton = DocumentPhotoEditorDemoViewController.makeButton(
        title: "Pick Real Photo…", systemImage: "photo.on.rectangle")
    private lazy var uiKitEditButton = DocumentPhotoEditorDemoViewController.makeButton(
        title: "Edit (UIKit call site)", systemImage: "camera.filters")
    private lazy var imagePicker = ImagePicker(presentationController: self, allowsEditing: false)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "DocumentPhotoEditor Demo"
        view.backgroundColor = .systemBackground
        sourceImageView.image = sourceImage
        setupLayout()

        pickPhotoButton.addAction(UIAction { [weak self] _ in
            self?.pickPhoto()
        }, for: .touchUpInside)

        uiKitEditButton.addAction(UIAction { [weak self] _ in
            self?.editFromUIKit()
        }, for: .touchUpInside)
    }

    // MARK: - Layout

    private func setupLayout() {
        let sourceStack = UIStackView(arrangedSubviews: [sourceLabel, sourceImageView])
        sourceStack.axis = .vertical
        sourceStack.spacing = 4

        let resultStack = UIStackView(arrangedSubviews: [resultLabel, resultImageView])
        resultStack.axis = .vertical
        resultStack.spacing = 4

        let imagesRow = UIStackView(arrangedSubviews: [sourceStack, resultStack])
        imagesRow.axis = .horizontal
        imagesRow.spacing = 12
        imagesRow.distribution = .fillEqually

        let swiftUIButtonHost = makeSwiftUICallSiteHost()

        let mainStack = UIStackView(arrangedSubviews: [
            imagesRow,
            pickPhotoButton,
            uiKitEditButton,
            swiftUIButtonHost.view,
            statusLabel,
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        // The content is taller than an iPhone in landscape, so it lives in a
        // scroll view rather than being clipped off the bottom of the screen.
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(mainStack)

        let horizontalInset: CGFloat = 20

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Pinning all four edges to contentLayoutGuide gives the scroll view
            // its content height; matching frameLayoutGuide's width keeps the
            // stack from scrolling horizontally too.
            mainStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            mainStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            mainStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                                               constant: horizontalInset),
            mainStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                                                constant: -horizontalInset),
            mainStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                             constant: -2 * horizontalInset),

            sourceImageView.heightAnchor.constraint(equalToConstant: 200),
            resultImageView.heightAnchor.constraint(equalToConstant: 200),
        ])
    }

    /// Hosts the SwiftUI call-site button as a child view controller, so the
    /// SwiftUI half of the unified API is exercised from inside this same screen.
    /// `capturingHostingController` will walk up from this hosting controller's
    /// own `.parent` chain to find a presenter — a real test of that walk, since
    /// it passes through this addChild containment before reaching the nav stack.
    private func makeSwiftUICallSiteHost() -> UIHostingController<SwiftUICallSiteView> {
        let hosting = UIHostingController(rootView: SwiftUICallSiteView(
            image: { [weak self] in self?.sourceImage },
            onEdited: { [weak self] edited in self?.handleEdited(edited, source: "SwiftUI") }
        ))
        hosting.sizingOptions = .intrinsicContentSize
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.didMove(toParent: self)
        return hosting
    }

    // MARK: - Actions

    private func pickPhoto() {
        Task {
            do {
                statusLabel.text = "Picking photo..."
                guard let picked = try await imagePicker.selectImage(from: pickPhotoButton) else {
                    statusLabel.text = "Cancelled"
                    return
                }
                sourceImage = picked
                statusLabel.text = "Loaded a real photo — real orientation/EXIF now feeds the editor."
            } catch PermissionError.denied {
                statusLabel.text = "Camera permission denied"
            } catch {
                statusLabel.text = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func editFromUIKit() {
        Task {
            statusLabel.text = "Editing (UIKit)…"
            let edited = await DocumentPhotoEditor.present(image: sourceImage, over: self)
            handleEdited(edited, source: "UIKit")
        }
    }

    private func handleEdited(_ edited: UIImage?, source: String) {
        guard let edited else {
            statusLabel.text = "\(source) call site: cancelled"
            return
        }
        resultImageView.image = edited
        statusLabel.text = "\(source) call site done — \(Int(edited.size.width))x\(Int(edited.size.height)) px"
    }
}

// MARK: - SwiftUI call site

/// Exercises `DocumentPhotoEditor.present(image:over:)` from a SwiftUI call
/// site, obtaining a `UIViewController` via `capturingHostingController(_:)`
/// instead of one being passed in directly.
private struct SwiftUICallSiteView: View {
    let image: () -> UIImage?
    let onEdited: (UIImage?) -> Void

    @State private var hostingController: UIViewController?

    var body: some View {
        Button {
            guard let hostingController, let image = image() else {
                return
            }
            Task {
                let edited = await DocumentPhotoEditor.present(image: image, over: hostingController)
                onEdited(edited)
            }
        } label: {
            Label("Edit (SwiftUI call site)", systemImage: "wand.and.stars")
        }
        .buttonStyle(.borderedProminent)
        .padding(.vertical, 4)
        .capturingHostingController($hostingController)
    }
}

// MARK: - Test image / view helpers

private extension DocumentPhotoEditorDemoViewController {

    static func makeCaptionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = text
        return label
    }

    static func makeButton(title: String, systemImage: String) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePadding = 8
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        return UIButton(configuration: config)
    }

    /// Builds a synthetic 12 MP (3024x4032, portrait) "scanned document page"
    /// test image: a warm-tinted, unevenly lit page with text-like rules, so
    /// Auto Enhance, white balance, and levels adjustments all have a visible
    /// effect, and slider-drag performance can be exercised against a
    /// realistic document-photo resolution without needing a real photo.
    static func makeTestDocumentImage() -> UIImage {
        let size = CGSize(width: 3024, height: 4032)
        return UIGraphicsImageRenderer(size: size).image { context in
            let cg = context.cgContext

            // Desk background behind the page.
            UIColor(white: 0.15, alpha: 1.0).setFill()
            cg.fill(CGRect(origin: .zero, size: size))

            // Warm-tinted, slightly inset "page".
            let pageInset: CGFloat = 80
            let pageRect = CGRect(origin: .zero, size: size).insetBy(dx: pageInset, dy: pageInset)
            UIColor(red: 0.93, green: 0.88, blue: 0.74, alpha: 1.0).setFill()
            cg.fill(pageRect)

            // Uneven lighting: a radial falloff darkening the corners.
            let colors = [UIColor.white.withAlphaComponent(0.0).cgColor,
                          UIColor.black.withAlphaComponent(0.35).cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                             colors: colors as CFArray, locations: [0, 1]) else {
                return
            }
            cg.saveGState()
            cg.clip(to: pageRect)
            cg.drawRadialGradient(gradient,
                                   startCenter: CGPoint(x: pageRect.midX, y: pageRect.midY),
                                   startRadius: pageRect.width * 0.25,
                                   endCenter: CGPoint(x: pageRect.midX, y: pageRect.midY),
                                   endRadius: pageRect.width * 0.85,
                                   options: [.drawsAfterEndLocation])
            cg.restoreGState()

            // Text-like rules to make sharpening/contrast changes visible.
            UIColor(white: 0.2, alpha: 0.85).setStroke()
            let path = UIBezierPath()
            path.lineWidth = 10
            let lineInset: CGFloat = pageInset + 120
            var y = pageRect.minY + 200
            while y < pageRect.maxY - 200 {
                let lineWidth = CGFloat.random(in: 0.4...0.9) * (pageRect.width - 2 * lineInset)
                path.move(to: CGPoint(x: pageRect.minX + lineInset, y: y))
                path.addLine(to: CGPoint(x: pageRect.minX + lineInset + lineWidth, y: y))
                y += 90
            }
            path.stroke()
        }
    }
}
