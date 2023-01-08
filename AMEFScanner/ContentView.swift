//
//  ContentView.swift
//  AMEFScanner
//
//  Created by Eduard Mititelu on 08.01.2023.
//
import SwiftUI
import AVFoundation
import Vision

final class CameraViewWrapper: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let view: ReceiptScanView

    init(view: ReceiptScanView) {
        self.view = view
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        view.captureOutput(output, didOutput: sampleBuffer, from: connection)
    }
}

struct ReceiptScanView: View {
    @State private var image: Image?
    @State private var isScanning = false
    @State private var uniqueCode: String?
    @State private var apiResponse: String?

    var body: some View {
        VStack {
            image?
                .resizable()
                .scaledToFit()
            Text(uniqueCode ?? "")
                .font(.title)
                .padding()
            Text(apiResponse ?? "")
                .font(.body)
                .padding()
            HStack {
                Button(action: {
                    // Open the device's camera to scan a receipt
                    self.startScanning()
                }) {
                    Text("Scan Receipt")
                }
                .disabled(isScanning)
                .padding()
                Spacer()
                Button(action: {
                    // Make an API GET request to the specified endpoint
                    guard let uniqueCode = self.uniqueCode else { return }
                    let endpoint = "https://api.example.com/receipts/\(uniqueCode)"
                    self.makeAPIGETRequest(to: endpoint)
                }) {
                    Text("Get Receipt")
                }
                .disabled(uniqueCode == nil)
                                .padding()
            }
        }
        .onAppear(perform: startScanning)
    }

    func startScanning() {
        // Set up the camera session
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()

        // Set up the preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        addPreviewLayer(previewLayer)

        // Set up the data output
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(CameraViewWrapper(view: self), queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)

        isScanning = true
    }

    func addPreviewLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.frame = UIScreen.main.bounds
        UIApplication.shared.windows.first?.layer.addSublayer(previewLayer)
    }

    func makeAPIGETRequest(to endpoint: String) {
        // Make an API GET request to the specified endpoint
        let url = URL(string: endpoint)!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    // Handle the successful response
                    let responseString = String(data: data, encoding: .utf8)

                    // Update the API response in the UI
                    DispatchQueue.main.async {
                        self.apiResponse = responseString
                    }
                } else {
                    // Handle the error response
                    print("HTTP response code: \(response.statusCode)")
                }
            }
        }
        task.resume()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Convert the video frame to a UIImage
        guard let image = imageFromSampleBuffer(sampleBuffer) else { return }

        // Display the image in the UI
        DispatchQueue.main.async {
            self.image = Image(uiImage: image)
        }

        // Perform OCR on the image to extract the text
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            var recognizedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                recognizedText += topCandidate.string + "\n"
            }

            // Use a regular expression to search for a unique code of 10 numeric characters
            let pattern = "\\b\\d{10}\\b"
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: recognizedText.utf16.count)
            let matches = regex!.matches(in: recognizedText, options: [], range: range)

            if let match = matches.first {
                let uniqueCode = String(recognizedText[Range(match.range, in: recognizedText)!])
                print("Unique code:", uniqueCode)
                DispatchQueue.main.async {
                    self.uniqueCode = uniqueCode
                }
            } else {
                print("Unique code not found")
            }
        }

        // Process the image with the OCR request
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        try? handler.perform([request])
    }
}

// Convert a CMSampleBuffer to a UIImage
func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
    let context = CIContext()
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
    return UIImage(cgImage: cgImage)
}

struct ReceiptScanView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptScanView()
    }
}
