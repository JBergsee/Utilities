//
//  ImageCropCalculator.swift
//
//
//  Created by Claude on 2026-08-02.
//

import UIKit
import AVFoundation // For AVMakeRect aspect-fit math

/// Maps an on-screen crop rectangle back into a source image's pixel space and
/// produces the cropped image. Kept as a pure calculator so `ImageCropperView`
/// can keep its transform state private and this math stays independently testable.
enum ImageCropCalculator {

    /// Crops `image` to `cropRect`.
    ///
    /// - Parameters:
    ///   - image: The source image, displayed aspect-fit and centred in `containerRect`,
    ///     then transformed by `scale` (about the centre) and `offset`.
    ///   - cropRect: The crop rectangle in the container's view coordinates.
    ///   - containerRect: The rect the image is aspect-fit and centred in, which the
    ///     crop rectangle is measured against. Both are in the same coordinate space.
    ///   - scale: The zoom applied to the displayed image.
    ///   - offset: The pan applied to the displayed image.
    /// - Returns: The cropped image, or the original if the crop can't be produced
    ///   (e.g. the rectangle lands entirely outside the image).
    static func crop(image: UIImage,
                     cropRect: CGRect,
                     containerRect: CGRect,
                     scale: CGFloat,
                     offset: CGSize) -> UIImage {
        // Reconstruct the displayed image frame from the committed zoom/pan. The image
        // is aspect-fit and centred, so scaling about the container centre scales the
        // fitted rect about its own centre.
        let fitted = AVMakeRect(aspectRatio: image.size, insideRect: containerRect)
        let center = CGPoint(x: containerRect.midX + offset.width,
                             y: containerRect.midY + offset.height)
        let displayedSize = CGSize(width: fitted.width * scale, height: fitted.height * scale)
        let displayed = CGRect(x: center.x - displayedSize.width / 2,
                               y: center.y - displayedSize.height / 2,
                               width: displayedSize.width,
                               height: displayedSize.height)
        guard displayed.width > 0, displayed.height > 0 else { return image }

        // Normalize the crop rectangle to the displayed image [0, 1] and clamp so it
        // never reaches outside the image.
        let nx0 = max((cropRect.minX - displayed.minX) / displayed.width, 0)
        let ny0 = max((cropRect.minY - displayed.minY) / displayed.height, 0)
        let nx1 = min((cropRect.maxX - displayed.minX) / displayed.width, 1)
        let ny1 = min((cropRect.maxY - displayed.minY) / displayed.height, 1)
        guard nx1 > nx0, ny1 > ny0 else { return image }

        // Work on an orientation-normalized image so pixel coordinates line up.
        let normalized = image.normalizedUp()
        guard let cg = normalized.cgImage else { return image }
        let pw = CGFloat(cg.width)
        let ph = CGFloat(cg.height)
        let pixelRect = CGRect(x: nx0 * pw,
                               y: ny0 * ph,
                               width: (nx1 - nx0) * pw,
                               height: (ny1 - ny0) * ph).integral
        guard let cropped = cg.cropping(to: pixelRect) else { return image }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }
}

private extension UIImage {
    /// Returns a copy whose `imageOrientation` is `.up` by redrawing, so that
    /// `cgImage` pixel coordinates match the on-screen orientation.
    func normalizedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = imageRendererFormat
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
