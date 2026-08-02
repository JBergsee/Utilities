//
//  ImageCropperDemoViewController.swift
//  Utilities-Example
//
//  Created by Claude on 2026-08-02.
//

import UIKit
import SwiftUI
import Utilities

// MARK: - Demo View Controller

/// Hosts the SwiftUI `ImageCropperDemoView` inside a `UIHostingController`.
class ImageCropperDemoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ImageCropper Demo"

        let hostingController = UIHostingController(rootView: ImageCropperDemoView())
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

private struct ImageCropperDemoView: View {

    private let sampleImage = ImageCropperDemoView.makeSampleImage()

    @State private var croppedImage: UIImage?
    @State private var isCropping = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Source")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(uiImage: sampleImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                isCropping = true
            } label: {
                Label("Crop image", systemImage: "crop")
            }
            .buttonStyle(.borderedProminent)

            if let croppedImage {
                VStack(spacing: 8) {
                    Text("Cropped result")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(uiImage: croppedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $isCropping) {
            ImageCropperView(
                image: sampleImage,
                onCrop: { image in
                    croppedImage = image
                    isCropping = false
                },
                onCancel: {
                    isCropping = false
                }
            )
        }
    }

    /// Builds a colourful gridded sample image so the cropped region is easy to verify.
    private static func makeSampleImage() -> UIImage {
        let size = CGSize(width: 600, height: 400)
        return UIGraphicsImageRenderer(size: size).image { context in
            let cg = context.cgContext

            let colors = [UIColor.systemIndigo.cgColor, UIColor.systemOrange.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray, locations: [0, 1])!
            cg.drawLinearGradient(gradient, start: .zero,
                                  end: CGPoint(x: size.width, y: size.height), options: [])

            UIColor.white.withAlphaComponent(0.4).setStroke()
            let path = UIBezierPath()
            let step: CGFloat = 50
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            path.lineWidth = 1
            path.stroke()
        }
    }
}
