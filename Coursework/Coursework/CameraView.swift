//
//  CameraView.swift
//  Coursework
//
//  Created by Leon Liao on 23/2/2025.
//

import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIImagePickerController in camera mode.
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage? // Binding to store the captured image
    var onPhotoTaken: (UIImage?) -> Void // Callback when a photo is taken

    // Create the UIImagePickerController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera // Set the source to the camera
        picker.allowsEditing = false // Disable editing
        return picker
    }

    // Update the UIImagePickerController (not used here)
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // Create a Coordinator to handle delegate methods
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator to conform to UIImagePickerControllerDelegate and UINavigationControllerDelegate
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Retrieve the captured image
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onPhotoTaken(image) // Call the callback with the taken photo
            } else {
                parent.onPhotoTaken(nil) // Call the callback with nil if no image was taken
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onPhotoTaken(nil) // Handle cancellation
            picker.dismiss(animated: true)
        }
    }
}
