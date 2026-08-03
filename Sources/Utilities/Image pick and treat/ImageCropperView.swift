//
//  ImageCropperView.swift
//
//
//  Created by Claude on 2026-08-02.
//

import SwiftUI
import UIKit
import AVFoundation // For AVMakeRect aspect-fit math

/// A SwiftUI view that lets the user crop a `UIImage`.
///
/// The image can be zoomed with a standard pinch gesture and panned by dragging.
/// A rectangular crop overlay is drawn on top; each of its four corners can be
/// dragged independently, and the overlay always stays an axis-aligned rectangle
/// (dragging a corner keeps the opposite corner anchored).
///
/// Three actions are offered:
/// - **Cancel** — dismiss without producing an image (`onCancel`).
/// - **Reset** — restore the zoom, pan and full-image crop rectangle.
/// - **Use cropped image** — compute the crop and return it (`onCrop`).
///
/// The result is pixel-accurate: the on-screen crop rectangle is mapped back into
/// the source image's pixel space (see `ImageCropCalculator`) and cropped via
/// `CGImage.cropping(to:)`.
@MainActor
public struct ImageCropperView: View {

    private let image: UIImage
    private let onCrop: (UIImage) -> Void
    private let onCancel: () -> Void

    /// - Parameters:
    ///   - image: The image to crop.
    ///   - onCrop: Called with the cropped image when the user confirms.
    ///   - onCancel: Called when the user cancels.
    public init(image: UIImage,
                onCrop: @escaping (UIImage) -> Void,
                onCancel: @escaping () -> Void) {
        self.image = image
        self.onCrop = onCrop
        self.onCancel = onCancel
    }

    // Image transform (zoom + pan). `last*` hold the committed value between gestures.
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Crop rectangle in the container's view coordinates.
    @State private var cropRect: CGRect = .zero
    // The crop rectangle captured at the start of a corner drag, so the drag is
    // computed from a stable origin rather than accumulating rounding error.
    @State private var cornerDragStart: CGRect?
    // Whether `cropRect` has been seeded for the current container size.
    @State private var didInitialize = false
    // Remember the last container size so the crop math (invoked outside the
    // GeometryReader) can reconstruct the displayed image frame.
    @State private var lastLayoutSize: CGSize?

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 6
    private let minCropSize: CGFloat = 60
    private let handleSize: CGFloat = 26
    private let handleHitSize: CGFloat = 44

    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                cropArea(in: geometry.size)
                    .onAppear {
                        lastLayoutSize = geometry.size
                        if !didInitialize {
                            resetCrop(in: geometry.size)
                            didInitialize = true
                        }
                    }
                    // On rotation / size change, re-seed the crop to the new fit.
                    .onChange(of: geometry.size) { _, newSize in
                        lastLayoutSize = newSize
                        resetCrop(in: newSize)
                    }
            }
            buttonBar
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Crop area

    private func cropArea(in size: CGSize) -> some View {
        ZStack {
            // The image, zoomed and panned. Fills the container; the drawn image is
            // aspect-fit and centred inside it, so scaling about the container centre
            // scales the fitted image about its own centre.
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(panGesture)
                .simultaneousGesture(magnifyGesture)

            // Dim everything outside the crop rectangle. Driven by an animatable
            // shape so the overlay interpolates in step with the handles on reset.
            CropOverlayShape(rect: cropRect, role: .dimming)
                .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)

            // Crop border + rule-of-thirds grid.
            cropOutline
                .allowsHitTesting(false)

            // Draggable corner handles, on top so they win touches near the corners.
            ForEach(CropCorner.allCases, id: \.self) { corner in
                cornerHandle
                    .position(cropRect.point(for: corner))
                    .gesture(cornerGesture(for: corner, in: size))
            }
        }
        .contentShape(Rectangle())
        .clipped()
    }

    private var cropOutline: some View {
        ZStack {
            CropOverlayShape(rect: cropRect, role: .border)
                .stroke(Color.white, lineWidth: 1)

            CropOverlayShape(rect: cropRect, role: .thirds)
                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
        }
    }

    private var cornerHandle: some View {
        Circle()
            .fill(Color.white)
            .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 1))
            .frame(width: handleSize, height: handleSize)
            // A larger, transparent hit area makes the corners easy to grab.
            .frame(width: handleHitSize, height: handleHitSize)
            .contentShape(Rectangle())
    }

    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func cornerGesture(for corner: CropCorner, in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                updateCorner(corner, translation: value.translation, in: size)
            }
            .onEnded { _ in
                cornerDragStart = nil
            }
    }

    /// Moves `corner` by `translation`, keeping the opposite corner fixed so the
    /// crop stays an axis-aligned rectangle. Clamps the moved corner to the
    /// container bounds and enforces a minimum crop size.
    private func updateCorner(_ corner: CropCorner, translation: CGSize, in size: CGSize) {
        let start = cornerDragStart ?? cropRect
        if cornerDragStart == nil { cornerDragStart = start }

        let anchor = start.point(for: corner.opposite)
        var moving = start.point(for: corner)
        moving.x += translation.width
        moving.y += translation.height

        // Keep within the container.
        moving.x = min(max(moving.x, 0), size.width)
        moving.y = min(max(moving.y, 0), size.height)

        // Preserve which side of the anchor the corner is on, and keep it at least
        // `minCropSize` away so the rectangle can't collapse or flip.
        if moving.x < anchor.x {
            moving.x = min(moving.x, anchor.x - minCropSize)
        } else {
            moving.x = max(moving.x, anchor.x + minCropSize)
        }
        if moving.y < anchor.y {
            moving.y = min(moving.y, anchor.y - minCropSize)
        } else {
            moving.y = max(moving.y, anchor.y + minCropSize)
        }

        cropRect = CGRect(corner: anchor, opposite: moving)
    }

    // MARK: - Buttons

    private var buttonBar: some View {
        HStack {
            Button("Cancel", role: .cancel) {
                onCancel()
            }
            .foregroundStyle(.white)

            Spacer()

            Button("Reset") {
                if let size = lastLayoutSize {
                    withAnimation(.easeInOut) {
                        resetCrop(in: size)
                    }
                }
            }
            .foregroundStyle(.white)

            Spacer()

            Button("Use Photo") {
                guard let size = lastLayoutSize else { return }
                onCrop(ImageCropCalculator.crop(image: image,
                                                cropRect: cropRect,
                                                containerSize: size,
                                                scale: scale,
                                                offset: offset))
            }
            .fontWeight(.semibold)
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.black)
    }

    // MARK: - Reset

    private func resetCrop(in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
        cropRect = AVMakeRect(aspectRatio: image.size,
                              insideRect: CGRect(origin: .zero, size: size))
    }
}

// MARK: - Animatable overlay

/// Draws the crop overlay (dimming, border or rule-of-thirds grid) from a `CGRect`.
///
/// The rectangle is exposed through `animatableData`, so SwiftUI interpolates the
/// path frame-by-frame during an animated transaction. This lets the overlay glide
/// in step with the corner handles (`.position`) and the image (`.scaleEffect`/
/// `.offset`) when the crop is reset, instead of snapping.
private struct CropOverlayShape: Shape {

    enum Role {
        case dimming // Everything outside the crop rectangle (even-odd fill).
        case border  // The crop rectangle's outline.
        case thirds  // Rule-of-thirds guide lines inside the crop rectangle.
    }

    var rect: CGRect
    let role: Role

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>,
                                       AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(AnimatablePair(rect.minX, rect.minY),
                           AnimatablePair(rect.width, rect.height))
        }
        set {
            rect = CGRect(x: newValue.first.first,
                          y: newValue.first.second,
                          width: newValue.second.first,
                          height: newValue.second.second)
        }
    }

    func path(in bounds: CGRect) -> Path {
        var path = Path()
        switch role {
        case .dimming:
            // Filled even-odd: the full area minus the crop rectangle.
            path.addRect(bounds)
            path.addRect(rect)
        case .border:
            path.addRect(rect)
        case .thirds:
            let thirdW = rect.width / 3
            let thirdH = rect.height / 3
            for i in 1...2 {
                let x = rect.minX + thirdW * CGFloat(i)
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x, y: rect.maxY))
                let y = rect.minY + thirdH * CGFloat(i)
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
        }
        return path
    }
}

// MARK: - Preview

#Preview {
    // A colourful sample image so the crop region is easy to see.
    let sample = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300)).image { context in
        let cg = context.cgContext
        let colors = [UIColor.systemTeal.cgColor, UIColor.systemPurple.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray, locations: [0, 1])!
        cg.drawLinearGradient(gradient, start: .zero,
                              end: CGPoint(x: 400, y: 300), options: [])
    }
    return ImageCropperView(image: sample, onCrop: { _ in }, onCancel: {})
}
