//
//  AIDetectView.swift
//  Coursework
//
//  Created by Leon Liao on 1/1/2025.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML

struct AIDetectView: View {
    @State private var image: UIImage?
    @State private var landmarkName: String = "Upload an image or use the camera to detect landmarks."
    @State private var isPickerPresented = false
    @State private var isCameraPresented = false

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }

            Text(landmarkName)
                .font(.title2)
                .padding()

            HStack {
                Button("Upload Image") {
                    isPickerPresented = true
                }
                .buttonStyle(.borderedProminent)

                Button("Take Photo") { // New button to take a photo
                    isCameraPresented = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            ImagePicker(image: $image, onImagePicked: detectLandmark)
        }
        .sheet(isPresented: $isCameraPresented) {
            CameraView(image: $image, onPhotoTaken: detectLandmark)
        }
    }

    private func detectLandmark(_ image: UIImage?) {
        guard let image = image,
              let cgImage = image.cgImage else {
            landmarkName = "Error: Unable to process image."
            return
        }

        do {
            // Load the Core ML model
            let configuration = MLModelConfiguration() // Create a configuration object
            configuration.computeUnits = .all // Use all available compute units (CPU, GPU, or Neural Engine)

            let model = try VNCoreMLModel(for: LandmarkClassifier(configuration: configuration).model)

            // Create a Vision request
            let request = VNCoreMLRequest(model: model) { request, error in
                guard error == nil else {
                    DispatchQueue.main.async {
                        self.landmarkName = "Error: \(error!.localizedDescription)"
                    }
                    return
                }

                if let results = request.results as? [VNClassificationObservation],
                   let firstResult = results.first {
                    DispatchQueue.main.async {
                        self.landmarkName = "Detected Landmark: \(firstResult.identifier)"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.landmarkName = "No landmark detected."
                    }
                }
            }

            // Perform the request using a Vision image handler
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
        } catch {
            self.landmarkName = "Error loading ML model: \(error.localizedDescription)"
        }
    }
}
