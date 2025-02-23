//
//  RealTimeCameraView.swift
//  Coursework
//
//  Created by Leon Liao on 1/1/2025.
//

import UIKit
import AVFoundation
import Vision
import CoreML
import SwiftUI

/// A SwiftUI wrapper for a real-time camera view with Core ML-based landmark detection.
struct RealTimeCameraView: UIViewControllerRepresentable {
    @Binding var landmarkName: String // Binding to update the detected landmark name in real-time

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.landmarkName = $landmarkName
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // This can be used to update the view controller if needed (e.g., handling dynamic updates)
    }
}

/// The camera view controller that handles the camera feed and performs real-time landmark detection.
class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var landmarkName: Binding<String>?

    private let captureSession = AVCaptureSession() // Manages the camera session
    private let videoOutput = AVCaptureVideoDataOutput() // Handles video frame output

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the camera
        setupCamera()

        // Add a preview layer to display the camera feed
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Start the capture session on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    private func setupCamera() {
        // Attempt to access the camera
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Error: Unable to access the camera.")
            return
        }

        // Add the camera input to the capture session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        // Configure the video output
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }

    // Process each frame from the camera feed
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        do {
            // Create a configuration for the Core ML model
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all // Use all available compute units (CPU, GPU, Neural Engine)

            // Load the Core ML model with the configuration
            let model = try VNCoreMLModel(for: LandmarkClassifier(configuration: configuration).model)

            // Create a Vision request
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                guard error == nil else {
                    print("Error in Core ML request: \(error!.localizedDescription)")
                    return
                }

                if let results = request.results as? [VNClassificationObservation],
                   let firstResult = results.first {
                    DispatchQueue.main.async {
                        self?.landmarkName?.wrappedValue = "Detected Landmark: \(firstResult.identifier)"
                        print("Detected Landmark: \(firstResult.identifier)")
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.landmarkName?.wrappedValue = "No landmark detected."
                        print("No landmark detected.")
                    }
                }
            }

            // Perform the Vision request
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try handler.perform([request])
        } catch {
            print("Error performing landmark detection: \(error.localizedDescription)")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Stop the capture session on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }
}
