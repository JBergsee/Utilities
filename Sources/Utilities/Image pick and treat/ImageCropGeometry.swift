//
//  ImageCropGeometry.swift
//
//
//  Created by Claude on 2026-08-02.
//

import CoreGraphics

/// The four corners of the crop rectangle used by `ImageCropperView`.
enum CropCorner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight

    /// The diagonally opposite corner, which stays anchored while this one is dragged.
    var opposite: CropCorner {
        switch self {
        case .topLeft: return .bottomRight
        case .topRight: return .bottomLeft
        case .bottomLeft: return .topRight
        case .bottomRight: return .topLeft
        }
    }
}

extension CGRect {
    /// The point at the given corner of this rectangle.
    func point(for corner: CropCorner) -> CGPoint {
        switch corner {
        case .topLeft: return CGPoint(x: minX, y: minY)
        case .topRight: return CGPoint(x: maxX, y: minY)
        case .bottomLeft: return CGPoint(x: minX, y: maxY)
        case .bottomRight: return CGPoint(x: maxX, y: maxY)
        }
    }

    /// Builds an axis-aligned rectangle spanning two opposite corner points.
    init(corner: CGPoint, opposite: CGPoint) {
        self.init(x: min(corner.x, opposite.x),
                  y: min(corner.y, opposite.y),
                  width: abs(corner.x - opposite.x),
                  height: abs(corner.y - opposite.y))
    }
}

/// Layout constants and corner math for a draggable crop rectangle, shared by
/// `ImageCropperView` and the document photo editor's crop mode so the two
/// behave identically and `ImageCropCalculator` can reconstruct either one.
enum CropLayout {

    /// Visible handle diameter.
    static let handleSize: CGFloat = 26
    /// Transparent hit area around each handle, so corners are easy to grab.
    static let handleHitSize: CGFloat = 44
    /// Smallest allowed crop edge, so the rectangle can't collapse.
    static let minCropSize: CGFloat = 60
    /// Half the handle hit area, so a corner handle's whole hit rect stays in the view.
    static var contentMargin: CGFloat { handleHitSize / 2 }

    /// The area the image and crop rectangle are confined to: the container inset on
    /// all sides so the corner handles stay inside the view and remain draggable.
    /// The inset is capped for very small containers so the rect can't go degenerate.
    static func contentRect(in size: CGSize) -> CGRect {
        let inset = min(contentMargin, min(size.width, size.height) / 4)
        return CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
    }

    /// Moves `corner` of `start` by `translation`, keeping the opposite corner fixed
    /// so the crop stays an axis-aligned rectangle.
    ///
    /// The moved corner is clamped into `bounds` while preserving which side of the
    /// anchor it is on and staying at least `minCropSize` away, so the rectangle
    /// can't collapse, flip, or drift into the margin.
    static func rect(movingCorner corner: CropCorner,
                     of start: CGRect,
                     by translation: CGSize,
                     within bounds: CGRect) -> CGRect {
        let anchor = start.point(for: corner.opposite)
        var moving = start.point(for: corner)
        moving.x += translation.width
        moving.y += translation.height

        if moving.x < anchor.x {
            moving.x = min(max(moving.x, bounds.minX), anchor.x - minCropSize)
        } else {
            moving.x = max(min(moving.x, bounds.maxX), anchor.x + minCropSize)
        }
        if moving.y < anchor.y {
            moving.y = min(max(moving.y, bounds.minY), anchor.y - minCropSize)
        } else {
            moving.y = max(min(moving.y, bounds.maxY), anchor.y + minCropSize)
        }

        return CGRect(corner: anchor, opposite: moving)
    }
}
