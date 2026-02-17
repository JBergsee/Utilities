//
//  ImagePickerDemoViewController.swift
//  Utilities-Example
//
//  Created by Johan Bergsee on 2026-02-16.
//

import UIKit
import Utilities

class ImagePickerDemoViewController: UIViewController {

    // MARK: - UI

    private let takePhotoButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Take / Choose Photo"
        config.image = UIImage(systemName: "camera")
        config.imagePadding = 8
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        return UIButton(configuration: config)
    }()

    private let fullImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.layer.cornerRadius = 8
        return iv
    }()

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.layer.cornerRadius = 8
        return iv
    }()

    private let fullSizeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "Original"
        return label
    }()

    private let thumbnailSizeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "Thumbnail (max 100 kB)"
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var imagePicker = ImagePicker(presentationController: self, delegate: nil)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ImagePicker Demo"
        view.backgroundColor = .systemBackground
        setupLayout()
        takePhotoButton.addAction(UIAction { [weak self] _ in
            self?.takePhoto()
        }, for: .touchUpInside)
    }

    // MARK: - Layout

    private func setupLayout() {
        let fullStack = UIStackView(arrangedSubviews: [fullSizeLabel, fullImageView])
        fullStack.axis = .vertical
        fullStack.spacing = 4

        let thumbStack = UIStackView(arrangedSubviews: [thumbnailSizeLabel, thumbnailImageView])
        thumbStack.axis = .vertical
        thumbStack.spacing = 4

        let imagesRow = UIStackView(arrangedSubviews: [fullStack, thumbStack])
        imagesRow.axis = .horizontal
        imagesRow.spacing = 12
        imagesRow.distribution = .fillEqually

        let mainStack = UIStackView(arrangedSubviews: [takePhotoButton, imagesRow, statusLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fullImageView.heightAnchor.constraint(equalToConstant: 200),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 200),
        ])
    }

    // MARK: - Actions

    private func takePhoto() {
        Task {
            do {
                statusLabel.text = "Picking image..."
                let image = try await imagePicker.selectImage(from: takePhotoButton)

                guard let image else {
                    statusLabel.text = "Cancelled"
                    return
                }

                // Show the original
                fullImageView.image = image
                let originalSize = image.jpegData(compressionQuality: 1.0)?.count ?? 0
                fullSizeLabel.text = "Original (\(originalSize / 1024) kB)"

                // Compress to thumbnail
                statusLabel.text = "Compressing..."
                let thumbnail = await ImageCompressor.compress(image: image, maxkByte: 100)
                thumbnailImageView.image = thumbnail

                if let thumbnail {
                    let thumbSize = thumbnail.jpegData(compressionQuality: 1.0)?.count ?? 0
                    thumbnailSizeLabel.text = "Thumbnail (\(thumbSize / 1024) kB)"
                    statusLabel.text = "Done — \(originalSize / 1024) kB → \(thumbSize / 1024) kB"
                } else {
                    thumbnailSizeLabel.text = "Thumbnail (failed)"
                    statusLabel.text = "Compression failed"
                }
            } catch PermissionError.denied {
                statusLabel.text = "Camera permission denied"
            } catch {
                statusLabel.text = "Error: \(error.localizedDescription)"
            }
        }
    }
}
