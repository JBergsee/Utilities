//
//  ImageCompressor.swift
//  Utilities
//
//  Created by Johan Bergsee on 2026-02-16.
//  
//

import UIKit
import JBLogging

public struct ImageCompressor: Sendable {

    /// Compresses an image to be below `maxkByte` kilobytes by iteratively scaling it down.
    @concurrent
    public static func compress(image: UIImage, maxkByte: Int) async -> UIImage? {
        guard let currentImageSize = image.jpegData(compressionQuality: 1.0)?.count else {
            return nil
        }
        let maxByte = maxkByte * 1024
        var iterationImage: UIImage? = image
        var iterationImageSize = currentImageSize
        var iterationCompression: CGFloat = 1.0

        while iterationImageSize > maxByte && iterationCompression > 0.01 {
            let percantageDecrease = getPercentageToDecreaseTo(forDataCount: iterationImageSize)

            let canvasSize = CGSize(width: image.size.width * iterationCompression,
                                    height: image.size.height * iterationCompression)
            let format = image.imageRendererFormat
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
            iterationImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: canvasSize))
            }

            guard let newImageSize = iterationImage?.jpegData(compressionQuality: 1.0)?.count else {
                return nil
            }

            Log.debug(message: "New image size: \(iterationImage?.prettyPrintedSize() ?? "0")", in: .functionality)
            Log.debug(message: "New data size: \(newImageSize/1024) kB", in: .functionality)

            iterationImageSize = newImageSize
            iterationCompression -= percantageDecrease
        }
        return iterationImage
    }

    @available(*, deprecated, message: "Use async compress(image:maxkByte:) instead")
    public static func compress(image: UIImage, maxkByte: Int,
                                completion: @escaping @Sendable (UIImage?) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let currentImageSize = image.jpegData(compressionQuality: 1.0)?.count else {
                return completion(nil)
            }
            let maxByte = maxkByte * 1024
            var iterationImage: UIImage? = image
            var iterationImageSize = currentImageSize
            var iterationCompression: CGFloat = 1.0

            while iterationImageSize > maxByte && iterationCompression > 0.01 {
                let percantageDecrease = getPercentageToDecreaseTo(forDataCount: iterationImageSize)

                let canvasSize = CGSize(width: image.size.width * iterationCompression,
                                        height: image.size.height * iterationCompression)
                let format = image.imageRendererFormat
                format.opaque = false
                let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
                iterationImage = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: canvasSize))
                }

                guard let newImageSize = iterationImage?.jpegData(compressionQuality: 1.0)?.count else {
                    return completion(nil)
                }

                Log.debug(message: "New image size: \(iterationImage?.prettyPrintedSize() ?? "0")", in: .functionality)
                Log.debug(message: "New data size: \(newImageSize/1024) kB", in: .functionality)

                iterationImageSize = newImageSize
                iterationCompression -= percantageDecrease
            }
            completion(iterationImage)
        }
    }

    private static func getPercentageToDecreaseTo(forDataCount dataCount: Int) -> CGFloat {
        switch dataCount {
        case 0..<3000000: return 0.05
        case 3000000..<10000000: return 0.1
        default: return 0.2
        }
    }
}
