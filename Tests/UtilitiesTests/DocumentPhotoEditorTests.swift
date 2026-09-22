//
//  DocumentPhotoEditorTests.swift
//  UtilitiesTests
//
//  Created by Claude on 2026-09-11.
//

import Testing
import CoreImage
@testable import Utilities

struct PhotoAdjustmentsTests {

    @Test func defaultHasNoManualChanges() {
        #expect(PhotoAdjustments.default.hasManualChanges == false)
    }

    @Test func togglingAutoEnhanceAloneIsNotAManualChange() {
        var adjustments = PhotoAdjustments.default
        adjustments.autoEnhanceEnabled = false
        #expect(adjustments.hasManualChanges == false)
        adjustments.autoEnhanceAmount = 5
        #expect(adjustments.hasManualChanges == false)
    }

    @Test func contrastChangeIsDetected() {
        var adjustments = PhotoAdjustments.default
        adjustments.contrast = 2.0
        #expect(adjustments.hasManualChanges)
    }

    @Test func brightnessChangeIsDetected() {
        var adjustments = PhotoAdjustments.default
        adjustments.brightness = 0.5
        #expect(adjustments.hasManualChanges)
    }

    @Test func temperatureChangeIsDetected() {
        var adjustments = PhotoAdjustments.default
        adjustments.temperature = 4000
        #expect(adjustments.hasManualChanges)
    }

    @Test func tintChangeIsDetected() {
        var adjustments = PhotoAdjustments.default
        adjustments.tint = 20
        #expect(adjustments.hasManualChanges)
    }

    @Test func whitePointChangeIsDetected() {
        var adjustments = PhotoAdjustments.default
        adjustments.whitePoint = 0.8
        #expect(adjustments.hasManualChanges)
    }

    @Test func resetRestoresManualFieldsPreservingAutoEnhance() {
        var adjustments = PhotoAdjustments.default
        adjustments.autoEnhanceEnabled = false
        adjustments.contrast = 2.0
        adjustments.brightness = 0.5
        adjustments.temperature = 4000
        adjustments.tint = 20
        adjustments.whitePoint = 0.8

        adjustments.resetManualAdjustments()

        #expect(adjustments.contrast == PhotoAdjustments.default.contrast)
        #expect(adjustments.brightness == PhotoAdjustments.default.brightness)
        #expect(adjustments.temperature == PhotoAdjustments.default.temperature)
        #expect(adjustments.tint == PhotoAdjustments.default.tint)
        #expect(adjustments.whitePoint == PhotoAdjustments.default.whitePoint)
        #expect(adjustments.autoEnhanceEnabled == false)
    }
}

struct DocumentPhotoFilterChainTests {
    // A plain, non-Metal CIContext keeps this pure module testable headlessly.
    private let context = CIContext(options: [.useSoftwareRenderer: true])

    private func solidImage(_ size: CGSize, red: CGFloat, green: CGFloat, blue: CGFloat) -> CIImage {
        CIImage(color: CIColor(red: red, green: green, blue: blue))
            .cropped(to: CGRect(origin: .zero, size: size))
    }

    private func samplePixel(_ image: CIImage) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8)? {
        let extent = image.extent
        guard !extent.isInfinite, !extent.isEmpty else {
            return nil
        }
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(image,
                        toBitmap: &pixel,
                        rowBytes: 4,
                        bounds: CGRect(x: extent.midX, y: extent.midY, width: 1, height: 1),
                        format: .RGBA8,
                        colorSpace: CGColorSpaceCreateDeviceRGB())
        return (pixel[0], pixel[1], pixel[2], pixel[3])
    }

    @Test func defaultAdjustmentsWithoutAutoEnhancePreservesExtent() {
        var adjustments = PhotoAdjustments.default
        adjustments.autoEnhanceEnabled = false
        let input = solidImage(CGSize(width: 64, height: 64), red: 0.5, green: 0.5, blue: 0.5)
        let output = DocumentPhotoFilterChain.apply(adjustments, to: input)
        #expect(output.extent == input.extent)
    }

    @Test func increasedBrightnessLightensSampledPixel() {
        var brighter = PhotoAdjustments.default
        brighter.autoEnhanceEnabled = false
        brighter.brightness = 0.3

        var neutral = PhotoAdjustments.default
        neutral.autoEnhanceEnabled = false

        let input = solidImage(CGSize(width: 8, height: 8), red: 0.4, green: 0.4, blue: 0.4)
        let brighterOutput = DocumentPhotoFilterChain.apply(brighter, to: input)
        let neutralOutput = DocumentPhotoFilterChain.apply(neutral, to: input)

        let brighterPixel = samplePixel(brighterOutput)
        let neutralPixel = samplePixel(neutralOutput)
        #expect(brighterPixel != nil)
        #expect(neutralPixel != nil)
        #expect((brighterPixel?.r ?? 0) > (neutralPixel?.r ?? 0))
    }

    @Test func tinyImageDoesNotCrashRender() {
        let input = solidImage(CGSize(width: 40, height: 40), red: 0.6, green: 0.6, blue: 0.6)
        let output = DocumentPhotoFilterChain.apply(.default, to: input)
        let cgImage = context.createCGImage(output, from: output.extent)
        #expect(cgImage != nil)
    }

    @Test(arguments: [Float(0.5), 1.0, 1.5])
    func whitePointStretchProducesValidPixelValues(whitePoint: Float) {
        var adjustments = PhotoAdjustments.default
        adjustments.autoEnhanceEnabled = false
        adjustments.whitePoint = whitePoint

        let input = solidImage(CGSize(width: 8, height: 8), red: 0.7, green: 0.7, blue: 0.7)
        let output = DocumentPhotoFilterChain.apply(adjustments, to: input)
        let pixel = samplePixel(output)
        #expect(pixel != nil)
    }
}
