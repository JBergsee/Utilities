//
//  DocumentPhotoEditorView.swift
//  Utilities
//
//  Created by Claude on 2026-09-11.
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal
import AVFoundation // For AVMakeRect aspect-fit math, as in ImageCropperView
import JBLogging

// MARK: - Orientation normalization

private extension UIImage.Orientation {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}

/// Builds a `CIImage` with orientation baked into the pixel data as a lazy
/// transform. `CIImage(cgImage:)` reads the raw pixel buffer top-left-origin
/// (unlike `CIImage(image:)`, whose orientation handling is ambiguous across
/// SDK versions), so orientation is applied explicitly here via `.oriented(_:)`
/// instead of relying on either initializer's implicit behavior.
private func normalizedCIImage(from image: UIImage) -> CIImage {
    guard let cgImage = image.cgImage else {
        let fallback = image.ciImage ?? CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        return fallback.oriented(image.imageOrientation.cgImagePropertyOrientation)
    }
    return CIImage(cgImage: cgImage).oriented(image.imageOrientation.cgImagePropertyOrientation)
}

/// Downsamples `image` so its longer edge is at most `longEdge`, never upscaling.
private func downsampled(_ image: CIImage, longEdge: CGFloat) -> CIImage {
    let extent = image.extent
    let currentLongEdge = max(extent.width, extent.height)
    guard currentLongEdge > longEdge, currentLongEdge > 0 else {
        return image
    }
    let scale = longEdge / currentLongEdge
    let lanczos = CIFilter.lanczosScaleTransform()
    lanczos.inputImage = image
    lanczos.scale = Float(scale)
    lanczos.aspectRatio = 1.0
    return lanczos.outputImage ?? image
}

enum DocumentPhotoEditorError: Error {
    case renderFailed
}

// MARK: - View Model

@Observable
@MainActor
final class DocumentPhotoEditorModel {
    var adjustments: PhotoAdjustments = .default
    private(set) var previewImage: UIImage?
    private(set) var originalPreviewImage: UIImage?
    var isShowingOriginal: Bool = false

    var canReset: Bool {
        adjustments.hasManualChanges
    }

    private var fullResolutionSource: CIImage?
    private var previewSource: CIImage?
    private let context: CIContext

    private var renderTask: Task<Void, Never>?
    private var pendingRender = false

    init(image: UIImage) {
        context = CIContext(
            mtlDevice: MTLCreateSystemDefaultDevice()!,
            options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
        let normalized = normalizedCIImage(from: image)
        fullResolutionSource = normalized
        previewSource = downsampled(normalized, longEdge: 1024)
        renderOriginalPreviewOnce()
        requestPreviewRender()
    }

    /// Coalesces render requests: at most one render in flight, at most one
    /// more pending — avoids synchronously re-rendering on every slider tick
    /// without needing a CADisplayLink.
    func requestPreviewRender() {
        guard renderTask == nil else {
            pendingRender = true
            return
        }
        renderTask = Task { [weak self] in
            await self?.performPreviewRender()
            guard let self else {
                return
            }
            self.renderTask = nil
            if self.pendingRender {
                self.pendingRender = false
                self.requestPreviewRender()
            }
        }
    }

    private func performPreviewRender() async {
        guard let source = previewSource else {
            return
        }
        let snapshot = adjustments
        let ciContext = context
        let cgImage = await Task.detached(priority: .userInitiated) { () -> CGImage? in
            let filtered = DocumentPhotoFilterChain.apply(snapshot, to: source)
            let extent = filtered.extent
            guard !extent.isInfinite, !extent.isEmpty else {
                return nil
            }
            return ciContext.createCGImage(filtered, from: extent)
        }.value
        // Resumes on the MainActor here (this class is @MainActor-isolated) —
        // this is the "hop back to MainActor" point; no explicit MainActor.run needed.
        guard let cgImage else {
            return
        }
        previewImage = UIImage(cgImage: cgImage)
    }

    private func renderOriginalPreviewOnce() {
        guard let source = previewSource else {
            return
        }
        let ciContext = context
        // Structured exactly like performPreviewRender: the detached task only
        // *returns* the CGImage, and the assignment happens back in this
        // MainActor-isolated context. Hopping with a nested MainActor.run closure
        // instead would capture the weak `self` binding a second time, across an
        // isolation boundary — an error in the Swift 6 language mode.
        Task { [weak self] in
            let cgImage = await Task.detached(priority: .utility) { () -> CGImage? in
                let extent = source.extent
                guard !extent.isInfinite, !extent.isEmpty else {
                    return nil
                }
                return ciContext.createCGImage(source, from: extent)
            }.value
            guard let cgImage else {
                return
            }
            self?.originalPreviewImage = UIImage(cgImage: cgImage)
        }
    }

    /// Renders the full-resolution result. Returns `nil` on failure (e.g. a
    /// degenerate source image), which the caller treats the same as Cancel.
    func renderFullResolution() async -> UIImage? {
        guard let source = fullResolutionSource else {
            return nil
        }
        let snapshot = adjustments
        let ciContext = context
        let cgImage = await Task.detached(priority: .userInitiated) { () -> CGImage? in
            let filtered = DocumentPhotoFilterChain.apply(snapshot, to: source)
            let extent = filtered.extent
            guard !extent.isInfinite, !extent.isEmpty else {
                return nil
            }
            return ciContext.createCGImage(filtered, from: extent)
        }.value
        guard let cgImage else {
            Log.error(DocumentPhotoEditorError.renderFailed,
                      message: "Full-resolution document photo render returned no image.",
                      in: .functionality)
            return nil
        }
        // Orientation was already baked into the pixel data by normalizedCIImage,
        // so the default .up orientation here is correct.
        return UIImage(cgImage: cgImage)
    }

    func reset() {
        adjustments.resetManualAdjustments()
        requestPreviewRender()
    }

    /// Releases the full-resolution/preview CIImage graphs and rendered images
    /// so they don't outlive the editor session.
    func releaseResources() {
        fullResolutionSource = nil
        previewSource = nil
        previewImage = nil
        originalPreviewImage = nil
        renderTask?.cancel()
        renderTask = nil
    }
}

// MARK: - Adjustment kinds

/// The five *manual* adjustments, and only those: `PhotoAdjustments.hasManualChanges`
/// and `resetManualAdjustments()` are defined over exactly this set, so Auto Enhance's
/// amount is deliberately not a case here — it is a separate `AdjustmentSliderSpec`
/// (see `AdjustmentSliderSpec.autoEnhanceAmount`) that Reset must not touch.
private enum AdjustmentKind: String, CaseIterable, Identifiable {
    case contrast, brightness, temperature, tint, whitePoint

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .contrast: "circle.lefthalf.filled"
        case .brightness: "sun.max"
        case .temperature: "thermometer"
        case .tint: "drop.halffull"
        case .whitePoint: "level"
        }
    }

    var displayName: String {
        switch self {
        case .contrast: "Contrast"
        case .brightness: "Brightness"
        case .temperature: "Warmth"
        case .tint: "Tint"
        case .whitePoint: "White Point"
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .contrast: 0.25...4
        case .brightness: -1...1
        case .temperature: 2000...10000
        case .tint: -150...150
        case .whitePoint: 0.5...1.5
        }
    }

    var neutralValue: Double {
        switch self {
        case .contrast: 1.0
        case .brightness: 0.0
        case .temperature: 6500
        case .tint: 0.0
        case .whitePoint: 1.0
        }
    }

    func formattedValue(_ value: Double) -> String {
        switch self {
        case .contrast, .whitePoint:
            String(format: "%.2f", value)
        case .brightness:
            String(format: "%+.2f", value)
        case .temperature:
            "\(Int(value.rounded()))K"
        case .tint:
            String(format: "%+.0f", value)
        }
    }

    var sliderSpec: AdjustmentSliderSpec {
        AdjustmentSliderSpec(
            title: displayName,
            range: range,
            neutralValue: neutralValue,
            format: { formattedValue($0) })
    }
}

// MARK: - Slider description

/// Everything `AdjustmentSliderView` needs to draw one slider, so the same view
/// serves both an `AdjustmentKind` and the Auto Enhance amount without either
/// having to know about the other.
/// `Sendable` (and so `format` is `@Sendable`) because `autoEnhanceAmount` below
/// is a static property: without it, that global is a Swift 6 concurrency error.
private struct AdjustmentSliderSpec: Sendable {
    let title: String
    let range: ClosedRange<Double>
    let neutralValue: Double
    let format: @Sendable (Double) -> String

    /// The `0...2` bounds and neutral value of `1` are `CIDocumentEnhancer`'s own
    /// documented `inputAmount` slider attributes, read off the filter rather than
    /// invented here. `0` is a visual no-op, which is acceptable only because this
    /// slider is on screen showing its value whenever Auto is on.
    static let autoEnhanceAmount = AdjustmentSliderSpec(
        title: "Auto Amount",
        range: 0...2,
        neutralValue: 1.0,
        format: { String(format: "%.2f", $0) })
}

/// Which slider the tray is currently showing. Auto Enhance has no selection of
/// its own: its amount slider is the tray's fallback whenever Auto is on and no
/// manual adjustment is selected, so one tap on Auto still just toggles it.
private enum TraySlider: Hashable {
    case autoEnhanceAmount
    case adjustment(AdjustmentKind)
}

private extension DocumentPhotoEditorModel {
    /// A `Binding<Double>` view onto one field of `adjustments`, uniform across
    /// the mixed `Float`/`CGFloat` field types so a single slider view can bind
    /// to any of them.
    func binding(for kind: AdjustmentKind) -> Binding<Double> {
        Binding(
            get: {
                switch kind {
                case .contrast: Double(self.adjustments.contrast)
                case .brightness: Double(self.adjustments.brightness)
                case .temperature: Double(self.adjustments.temperature)
                case .tint: Double(self.adjustments.tint)
                case .whitePoint: Double(self.adjustments.whitePoint)
                }
            },
            set: { newValue in
                switch kind {
                case .contrast: self.adjustments.contrast = Float(newValue)
                case .brightness: self.adjustments.brightness = Float(newValue)
                case .temperature: self.adjustments.temperature = CGFloat(newValue)
                case .tint: self.adjustments.tint = CGFloat(newValue)
                case .whitePoint: self.adjustments.whitePoint = Float(newValue)
                }
                self.requestPreviewRender()
            })
    }

    /// The `Binding<Double>` for `CIDocumentEnhancer`'s amount, routed through
    /// `requestPreviewRender()` like every other slider so amount drags get the
    /// same render coalescing.
    var autoEnhanceAmountBinding: Binding<Double> {
        Binding(
            get: { Double(self.adjustments.autoEnhanceAmount) },
            set: { newValue in
                self.adjustments.autoEnhanceAmount = Float(newValue)
                self.requestPreviewRender()
            })
    }

    /// Toggling Auto is a write that must also kick a re-render, so this can't
    /// just be `$model.adjustments.autoEnhanceEnabled`.
    var autoEnhanceEnabledBinding: Binding<Bool> {
        Binding(
            get: { self.adjustments.autoEnhanceEnabled },
            set: { newValue in
                self.adjustments.autoEnhanceEnabled = newValue
                self.requestPreviewRender()
            })
    }
}

// MARK: - SwiftUI View

public struct DocumentPhotoEditorView: View {
    @State private var model: DocumentPhotoEditorModel
    @State private var selectedAdjustment: AdjustmentKind?
    @State private var isSaving = false
    @State private var zoom = ZoomState()
    @State private var crop = CropState()
    /// The preview container's size, remembered so the crop math (run outside the
    /// preview's GeometryReader) can reconstruct the displayed image frame.
    @State private var previewLayoutSize: CGSize?

    let onDone: (UIImage) -> Void
    let onCancel: () -> Void

    init(image: UIImage, onDone: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        _model = State(initialValue: DocumentPhotoEditorModel(image: image))
        self.onDone = onDone
        self.onCancel = onCancel
    }

    /// Width of the landscape control column. The preview takes whatever is left.
    private static let landscapeTrayWidth: CGFloat = 240

    public var body: some View {
        // Landscape is decided from the proposed size rather than the vertical
        // size class: an iPad is regular/regular in both orientations, so a size
        // class check would never give it the side-by-side layout.
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            VStack(spacing: 0) {
                topBar
                if isLandscape {
                    HStack(spacing: 0) {
                        previewArea
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        ControlTray(model: model,
                                    selectedAdjustment: $selectedAdjustment,
                                    isCropping: $crop.isActive,
                                    axis: .vertical)
                            .frame(width: Self.landscapeTrayWidth)
                    }
                } else {
                    previewArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ControlTray(model: model,
                                selectedAdjustment: $selectedAdjustment,
                                isCropping: $crop.isActive,
                                axis: .horizontal)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Color.black)
        .onDisappear {
            model.releaseResources()
        }
    }

    private var topBar: some View {
        HStack {
            Button("Cancel") {
                onCancel()
            }
            Spacer()
            Button("Reset") {
                model.reset()
                withAnimation(.snappy(duration: 0.25)) {
                    zoom.reset()
                    if let full = fullCropRect() {
                        crop.rect = full
                    }
                }
            }
            .disabled(!canReset)
            Spacer()
            Button("Done") {
                guard !isSaving else {
                    return
                }
                isSaving = true
                Task {
                    if let result = await model.renderFullResolution() {
                        onDone(cropped(result))
                    } else {
                        onCancel()
                    }
                }
            }
            .fontWeight(.bold)
            .disabled(isSaving)
        }
        .padding()
    }

    /// Reset clears the photo adjustments, the pan/zoom *and* the crop, so it has
    /// to be enabled when any of the three has something to clear — cropping or
    /// zooming without touching a slider would otherwise leave the button greyed
    /// out and the edit stuck.
    private var canReset: Bool {
        model.canReset || zoom.isTransformed || isCropped
    }

    /// The crop rectangle covering the whole image, i.e. "not cropped".
    private func fullCropRect() -> CGRect? {
        guard let size = previewLayoutSize, let aspect = model.previewImage?.size else {
            return nil
        }
        return AVMakeRect(aspectRatio: aspect, insideRect: CropLayout.contentRect(in: size))
    }

    /// Whether the crop rectangle has been pulled in from the full image. The
    /// tolerance keeps sub-point drift from leaving Reset permanently enabled.
    private var isCropped: Bool {
        guard crop.rect != .zero, let full = fullCropRect() else {
            return false
        }
        return abs(crop.rect.minX - full.minX) > 0.5
            || abs(crop.rect.minY - full.minY) > 0.5
            || abs(crop.rect.width - full.width) > 0.5
            || abs(crop.rect.height - full.height) > 0.5
    }

    /// Applies the crop rectangle to the finished full-resolution render, using the
    /// same calculator as `ImageCropperView`. The full-resolution image shares the
    /// preview's aspect ratio, so the on-screen rectangle normalizes identically.
    private func cropped(_ image: UIImage) -> UIImage {
        guard isCropped, let size = previewLayoutSize else {
            return image
        }
        return ImageCropCalculator.crop(image: image,
                                        cropRect: crop.rect,
                                        containerRect: CropLayout.contentRect(in: size),
                                        scale: zoom.scale,
                                        offset: zoom.offset)
    }

    private var previewArea: some View {
        Group {
            if let image = displayedImage {
                PreviewArea(image: image,
                            zoom: $zoom,
                            crop: $crop,
                            layoutSize: $previewLayoutSize) { isPressing in
                    withAnimation(.easeOut(duration: 0.15)) {
                        model.isShowingOriginal = isPressing
                    }
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .accessibilityLabel("Photo preview")
        .accessibilityHint("Touch and hold to compare with the original. Pinch to zoom, drag to pan, double tap to fit.")
    }

    private var displayedImage: UIImage? {
        if model.isShowingOriginal {
            return model.originalPreviewImage ?? model.previewImage
        }
        return model.previewImage
    }
}

// MARK: - Zoomable preview

/// The preview's pan/zoom transform.
///
/// Deliberately not part of `PhotoAdjustments`: it is pure presentation and must
/// never influence the exported image, and `hasManualChanges` / Reset are defined
/// over the five photo adjustments only. It is owned by `DocumentPhotoEditorView`
/// rather than by `ZoomablePreview` so that Reset can clear it and so the Reset
/// button can tell whether there is a transform to clear.
private struct ZoomState: Equatable {
    var scale: CGFloat = 1
    var offset: CGSize = .zero
    /// Committed at the end of each gesture; the base the next gesture builds on.
    var committedScale: CGFloat = 1
    var committedOffset: CGSize = .zero

    static let minScale: CGFloat = 1
    static let maxScale: CGFloat = 6

    /// Whether the preview is zoomed or panned away from fit. The epsilon keeps
    /// a pinch that ends a hair above 1.0 from leaving Reset permanently enabled.
    var isTransformed: Bool {
        scale > Self.minScale + 0.001 || offset != .zero
    }

    mutating func reset() {
        self = ZoomState()
    }
}

/// The preview's crop rectangle, in the preview container's view coordinates.
///
/// Lives alongside `ZoomState` in the view layer for the same reasons, and is
/// mapped back into source pixels only at Done, by the same
/// `ImageCropCalculator` that `ImageCropperView` uses.
private struct CropState: Equatable {
    /// `.zero` until seeded to the full image on first layout.
    var rect: CGRect = .zero
    /// Whether the crop overlay and its corner handles are showing.
    var isActive = false
    /// The rectangle captured at the start of a corner drag, so the drag is
    /// computed from a stable origin rather than accumulating rounding error.
    var cornerDragStart: CGRect?
}

/// Pinch-to-zoom and drag-to-pan around the rendered preview, with double tap
/// to return to fit, plus the crop overlay when crop mode is on.
///
/// The transform and crop rect are bound from the parent rather than held here,
/// so Reset can clear them. They still have to survive `previewImage` being
/// replaced on every slider tick — which they do, because the state lives above
/// this view.
///
/// The image is fitted inside `CropLayout.contentRect` (the container inset by
/// half a handle's hit area) exactly as in `ImageCropperView`, for two reasons:
/// the corner handles stay fully on screen and grabbable, and the geometry
/// matches what `ImageCropCalculator` reconstructs from `containerRect`.
private struct PreviewArea: View {
    let image: UIImage
    @Binding var zoom: ZoomState
    @Binding var crop: CropState
    /// Reported upward so the parent can run the crop math and seed Reset.
    @Binding var layoutSize: CGSize?
    /// Forwarded from the touch-and-hold compare gesture.
    let onPressingChanged: (Bool) -> Void

    var body: some View {
        GeometryReader { proxy in
            let container = proxy.size
            let content = CropLayout.contentRect(in: container)
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: content.width, height: content.height)
                    .scaleEffect(zoom.scale)
                    .offset(zoom.offset)
                    // Keep the pan/zoom hit area covering the whole container, so
                    // gestures still work in the margin band outside the image.
                    .frame(width: container.width, height: container.height)
                    .contentShape(Rectangle())
                    .gesture(zoomAndPan(in: content))
                    .onTapGesture(count: 2) {
                        withAnimation(.snappy(duration: 0.25)) {
                            zoom.reset()
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.25,
                                        maximumDistance: 20,
                                        pressing: onPressingChanged,
                                        perform: {})

                if crop.isActive {
                    cropOverlay(within: content)
                }
            }
            .contentShape(Rectangle())
            .clipped()
            .onAppear {
                layoutSize = container
                if crop.rect == .zero {
                    crop.rect = fullCropRect(within: content)
                }
            }
            .onChange(of: container) { _, newSize in
                layoutSize = newSize
                let newContent = CropLayout.contentRect(in: newSize)
                // Rotating changes the container, which can strand a pan offset
                // outside the new bounds — pull it back in.
                zoom.offset = clampedOffset(zoom.offset, content: newContent)
                zoom.committedOffset = zoom.offset
                // A crop rect in view coordinates doesn't survive a resize, so
                // re-seed it to the full image, as ImageCropperView does.
                crop.rect = fullCropRect(within: newContent)
            }
        }
    }

    private func fullCropRect(within content: CGRect) -> CGRect {
        AVMakeRect(aspectRatio: image.size, insideRect: content)
    }

    // MARK: - Crop overlay

    @ViewBuilder
    private func cropOverlay(within bounds: CGRect) -> some View {
        // Dim everything outside the crop rectangle. Driven by an animatable
        // shape so the overlay interpolates in step with the handles on reset.
        CropOverlayShape(rect: crop.rect, role: .dimming)
            .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
            .allowsHitTesting(false)

        CropOverlayShape(rect: crop.rect, role: .border)
            .stroke(Color.white, lineWidth: 1)
            .allowsHitTesting(false)

        CropOverlayShape(rect: crop.rect, role: .thirds)
            .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
            .allowsHitTesting(false)

        // Handles last so they win touches near the corners, ahead of pan/zoom.
        ForEach(CropCorner.allCases, id: \.self) { corner in
            cornerHandle
                .position(crop.rect.point(for: corner))
                .gesture(cornerGesture(for: corner, within: bounds))
        }
    }

    private var cornerHandle: some View {
        Circle()
            .fill(Color.white)
            .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 1))
            .frame(width: CropLayout.handleSize, height: CropLayout.handleSize)
            // A larger, transparent hit area makes the corners easy to grab.
            .frame(width: CropLayout.handleHitSize, height: CropLayout.handleHitSize)
            .contentShape(Rectangle())
    }

    private func cornerGesture(for corner: CropCorner, within bounds: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let start = crop.cornerDragStart ?? crop.rect
                if crop.cornerDragStart == nil {
                    crop.cornerDragStart = start
                }
                crop.rect = CropLayout.rect(movingCorner: corner,
                                            of: start,
                                            by: value.translation,
                                            within: bounds)
            }
            .onEnded { _ in
                crop.cornerDragStart = nil
            }
    }

    // MARK: - Pan and zoom

    private func zoomAndPan(in content: CGRect) -> some Gesture {
        let magnify = MagnifyGesture()
            .onChanged { value in
                zoom.scale = min(max(zoom.committedScale * value.magnification,
                                     ZoomState.minScale),
                                 ZoomState.maxScale)
            }
            .onEnded { _ in
                zoom.committedScale = zoom.scale
                // Zooming back out can leave the image off-centre; settle it.
                withAnimation(.snappy(duration: 0.2)) {
                    zoom.offset = clampedOffset(zoom.offset, content: content)
                }
                zoom.committedOffset = zoom.offset
            }

        // A minimum distance leaves a stationary finger to the long-press
        // compare gesture instead of swallowing it as the start of a pan.
        let pan = DragGesture(minimumDistance: 10)
            .onChanged { value in
                let proposed = CGSize(width: zoom.committedOffset.width + value.translation.width,
                                      height: zoom.committedOffset.height + value.translation.height)
                zoom.offset = clampedOffset(proposed, content: content)
            }
            .onEnded { _ in
                zoom.committedOffset = zoom.offset
            }

        return magnify.simultaneously(with: pan)
    }

    /// On-screen size of the letterboxed image at scale 1.
    private func fittedImageSize(in container: CGSize) -> CGSize {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0,
              container.width > 0, container.height > 0 else {
            return container
        }
        let fit = min(container.width / imageSize.width, container.height / imageSize.height)
        return CGSize(width: imageSize.width * fit, height: imageSize.height * fit)
    }

    /// Limits panning to the image's overflow beyond the content area, so the
    /// preview can never be dragged away into empty space. An axis with no
    /// overflow (not zoomed past fit) is pinned to centre.
    private func clampedOffset(_ proposed: CGSize, content: CGRect) -> CGSize {
        let fitted = fittedImageSize(in: content.size)
        let maxX = max(0, (fitted.width * zoom.scale - content.width) / 2)
        let maxY = max(0, (fitted.height * zoom.scale - content.height) / 2)
        return CGSize(width: min(max(proposed.width, -maxX), maxX),
                      height: min(max(proposed.height, -maxY), maxY))
    }
}

// MARK: - Control Tray

private struct ControlTray: View {
    @Bindable var model: DocumentPhotoEditorModel
    @Binding var selectedAdjustment: AdjustmentKind?
    @Binding var isCropping: Bool
    /// `.horizontal` is the portrait tray across the bottom; `.vertical` is the
    /// landscape column down the trailing edge, where the icon strip stacks.
    let axis: Axis

    private let sliderAreaHeight: CGFloat = 64

    /// The selected manual adjustment if there is one, otherwise Auto's amount
    /// slider while Auto is on — so the tray is never empty while Auto is active,
    /// and Auto stops being the one strip control whose tap changes no layout.
    private var activeTraySlider: TraySlider? {
        if let selectedAdjustment {
            return .adjustment(selectedAdjustment)
        }
        return model.adjustments.autoEnhanceEnabled ? .autoEnhanceAmount : nil
    }

    private var activeSlider: (spec: AdjustmentSliderSpec, value: Binding<Double>)? {
        switch activeTraySlider {
        case .adjustment(let kind):
            (kind.sliderSpec, model.binding(for: kind))
        case .autoEnhanceAmount:
            (.autoEnhanceAmount, model.autoEnhanceAmountBinding)
        case nil:
            nil
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            sliderArea
            iconStrip
        }
        .padding(.top, 12)
        .background(.ultraThinMaterial)
    }

    private var sliderArea: some View {
        ZStack {
            if let activeSlider {
                AdjustmentSliderView(spec: activeSlider.spec, value: activeSlider.value)
                    // Identity must change when the tray swaps between two
                    // sliders, or SwiftUI updates in place and the transition
                    // never runs — which is now the common case, since
                    // selecting an adjustment replaces the Auto amount slider.
                    .id(activeTraySlider)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal)
        .frame(height: sliderAreaHeight)
        .animation(.snappy(duration: 0.22), value: activeTraySlider)
    }

    /// Same controls either way; only the stacking axis and the scroll
    /// direction differ, so the buttons themselves live in `stripContent`.
    @ViewBuilder
    private var iconStrip: some View {
        switch axis {
        case .horizontal:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    stripContent
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 8)
        case .vertical:
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    stripContent
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private var stripContent: some View {
        // Toggle chrome, not the strip's selection chrome: a filled capsule with
        // its own On/Off text, so "Auto is on" can never be misread as "Auto's
        // slider is showing".
        Toggle(isOn: model.autoEnhanceEnabledBinding) {
            Label(model.adjustments.autoEnhanceEnabled ? "Auto On" : "Auto Off",
                  systemImage: "wand.and.stars")
        }
        // No explicit buttonStyle: ButtonToggleStyle's own filled/unfilled
        // background is the second state signal alongside the On/Off text, and a
        // bordered style overrides it.
        .toggleStyle(.button)
        .tint(.accentColor)

        // Crop is a mode, not a value, so it gets the same capsule toggle chrome
        // as Auto rather than the circular selection chrome of the sliders.
        Toggle(isOn: $isCropping) {
            Label("Crop", systemImage: "crop")
        }
        .toggleStyle(.button)
        .tint(.accentColor)

        // A Divider spans the stack's cross axis, so it only needs an explicit
        // length when it is standing up inside the horizontal strip.
        switch axis {
        case .horizontal:
            Divider()
                .frame(height: 32)
        case .vertical:
            Divider()
                .padding(.horizontal, 24)
        }

        ForEach(AdjustmentKind.allCases) { kind in
            IconStripButton(
                systemImage: kind.systemImage,
                title: kind.displayName,
                isActive: selectedAdjustment == kind
            ) {
                withAnimation(.snappy(duration: 0.22)) {
                    selectedAdjustment = (selectedAdjustment == kind) ? nil : kind
                }
            }
        }
    }
}

/// A circular icon button for one adjustment in the icon strip. `isActive` means
/// "this adjustment's slider is the one showing in the tray" and fills the icon's
/// circular background with the accent color. Auto Enhance deliberately does *not*
/// use this chrome — it is a toggle, not a selection, and reusing the same accent
/// fill for both made its state unreadable.
private struct IconStripButton: View {
    let systemImage: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background {
                        Circle()
                            .fill(isActive ? Color.accentColor : Color.clear)
                    }
                    .foregroundStyle(isActive ? Color.white : Color.primary)
                    .animation(.snappy(duration: 0.18), value: isActive)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Adjustment Slider

private struct AdjustmentSliderView: View {
    let spec: AdjustmentSliderSpec
    @Binding var value: Double

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(spec.title)
                    .font(.caption)
                Spacer()
                Text(spec.format(value))
                    .font(.caption.monospacedDigit())
            }
            ZStack(alignment: .leading) {
                GeometryReader { proxy in
                    let range = spec.range
                    let fraction = (spec.neutralValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                    Capsule()
                        .fill(Color.primary.opacity(0.55))
                        .frame(width: 3, height: 16)
                        .position(x: proxy.size.width * fraction, y: proxy.size.height / 2)
                }
                .frame(height: 12)
                .allowsHitTesting(false)

                Slider(value: $value, in: spec.range)
                    .accessibilityLabel(spec.title)
                    .accessibilityValue(spec.format(value))
            }
        }
    }
}
