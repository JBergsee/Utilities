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
