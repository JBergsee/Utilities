//
//  PhotoAdjustments.swift
//  Utilities
//
//  Created by Claude on 2026-09-11.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics

/// The set of user-adjustable document-photo edits.
///
/// A plain, `Equatable` value type with no UIKit/SwiftUI dependency, so it can
/// be passed to `DocumentPhotoFilterChain.apply(_:to:)` and unit-tested headlessly.
public struct PhotoAdjustments: Equatable, Sendable {
    public var autoEnhanceEnabled: Bool = true
    public var autoEnhanceAmount: Float = 1.0     // CIDocumentEnhancer inputAmount
    public var contrast: Float = 1.0              // CIColorControls inputContrast, 0.25...4
    public var brightness: Float = 0.0            // CIColorControls inputBrightness, -1...1
    public var temperature: CGFloat = 6500        // CITemperatureAndTint inputTargetNeutral.x (Kelvin), 2000...10000
    public var tint: CGFloat = 0.0                // CITemperatureAndTint inputTargetNeutral.y, -150...150
    public var whitePoint: Float = 1.0            // levels-style stretch, 0.5...1.5

    public init() {}

    public static let `default` = PhotoAdjustments()

    /// Whether any of the 5 manually-adjustable fields differs from its default.
    ///
    /// `autoEnhanceEnabled`/`autoEnhanceAmount` are intentionally excluded: the
    /// user's explicit Auto Enhance choice is not something Reset touches, so it
    /// must not factor into whether Reset is enabled either.
    public var hasManualChanges: Bool {
        contrast != Self.default.contrast
            || brightness != Self.default.brightness
            || temperature != Self.default.temperature
            || tint != Self.default.tint
            || whitePoint != Self.default.whitePoint
    }

    /// Restores the 5 manually-adjustable fields to their defaults, leaving
    /// `autoEnhanceEnabled`/`autoEnhanceAmount` untouched.
    public mutating func resetManualAdjustments() {
        contrast = Self.default.contrast
        brightness = Self.default.brightness
        temperature = Self.default.temperature
        tint = Self.default.tint
        whitePoint = Self.default.whitePoint
    }
}

/// Pure `CIImage -> CIImage` filter chain for `PhotoAdjustments`. No UIKit/SwiftUI
/// dependency — safe to call from a background thread and from unit tests.
public enum DocumentPhotoFilterChain {

    /// Applies the adjustments in a fixed order (do not reorder without checking
    /// with the caller — order changes the visual result):
    /// 1. `CIDocumentEnhancer` — only if `autoEnhanceEnabled`.
    /// 2. `CIColorControls` — contrast, brightness (saturation fixed at 1.0).
    /// 3. `CITemperatureAndTint` — inputNeutral fixed at (6500, 0).
    /// 4. A white-point/levels stretch (see `applyWhitePoint`).
    public static func apply(_ adjustments: PhotoAdjustments, to image: CIImage) -> CIImage {
        var output = image

        if adjustments.autoEnhanceEnabled {
            let enhancer = CIFilter.documentEnhancer()
            enhancer.inputImage = output
            enhancer.amount = adjustments.autoEnhanceAmount
            if let enhanced = enhancer.outputImage {
                output = enhanced
            }
        }

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = output
        colorControls.contrast = adjustments.contrast
        colorControls.brightness = adjustments.brightness
        colorControls.saturation = 1.0
        if let colorAdjusted = colorControls.outputImage {
            output = colorAdjusted
        }

        let temperatureAndTint = CIFilter.temperatureAndTint()
        temperatureAndTint.inputImage = output
        temperatureAndTint.neutral = CIVector(x: 6500, y: 0)
        temperatureAndTint.targetNeutral = CIVector(x: adjustments.temperature, y: adjustments.tint)
        if let temperatureAdjusted = temperatureAndTint.outputImage {
            output = temperatureAdjusted
        }

        output = applyWhitePoint(adjustments.whitePoint, to: output)
        return output
    }

    /// Levels-style highlight stretch: everything at normalized input level
    /// `whitePoint` is remapped to full white, values below stretched
    /// proportionally, values above clipped — implemented as a 5-point
    /// `CIToneCurve` sampling the clamped-linear function `y = min(x / whitePoint, 1)`.
    ///
    /// CIToneCurve was the filter actually used (chosen over `CIWhitePointAdjust`
    /// for the proper "levels" feel it gives); the spline it fits through these 5
    /// points only approximates the clamped-linear function, which can show as a
    /// slight softening right at the knee when `whitePoint` isn't ~1.0.
    /// `CIWhitePointAdjust` (`inputColor = CIColor(red: wp, green: wp, blue: wp)`)
    /// is a documented drop-in fallback with no spline artifact, if that softening
    /// ever proves objectionable in practice.
    private static func applyWhitePoint(_ whitePoint: Float, to image: CIImage) -> CIImage {
        let clampedWhitePoint = max(CGFloat(whitePoint), 0.01)
        func y(_ x: CGFloat) -> CGFloat {
            min(x / clampedWhitePoint, 1.0)
        }

        let curve = CIFilter.toneCurve()
        curve.inputImage = image
        curve.point0 = CGPoint(x: 0.00, y: y(0.00))
        curve.point1 = CGPoint(x: 0.25, y: y(0.25))
        curve.point2 = CGPoint(x: 0.50, y: y(0.50))
        curve.point3 = CGPoint(x: 0.75, y: y(0.75))
        curve.point4 = CGPoint(x: 1.00, y: y(1.00))
        return curve.outputImage ?? image
    }
}
