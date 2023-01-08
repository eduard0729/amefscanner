import Foundation
import Vision
import VisionKit

final class TextRecognizer{
    let cameraScan: VNDocumentCameraScan
    init(cameraScan:VNDocumentCameraScan) {
        self.cameraScan = cameraScan
    }
    private let queue = DispatchQueue(label: "scan-codes",qos: .default,attributes: [],autoreleaseFrequency: .workItem)
    func recognizeText(withCompletionHandler completionHandler:@escaping ([String])-> Void) {
        queue.async {
            let images = (0..<self.cameraScan.pageCount).compactMap({
                self.cameraScan.imageOfPage(at: $0).cgImage
            })
            let imagesAndRequests = images.map({(image: $0, request:VNRecognizeTextRequest())})
            let textPerPage = imagesAndRequests.map{image,request->String in
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do{
                    try handler.perform([request])
                    guard let observations = request.results as? [VNRecognizedTextObservation] else{return ""}
                    let text = observations.compactMap({$0.topCandidates(1).first?.string}).joined(separator: "\n")
                    
                    // Extract the 10-digit number from the recognized text
                    let pattern = "\\b\\d{10}\\b"
                    let regex = try! NSRegularExpression(pattern: pattern)
                    let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
                    if let match = matches.first {
                        let range = match.range(at: 0)
                        let extractedNumber = String(text[Range(range, in: text)!])
                        return extractedNumber
                    }
                    else {
                        return ""
                    }
                    
                    
                }
                catch{
                    print(error)
                    return ""
                }
            }
            DispatchQueue.main.async {
                completionHandler(textPerPage)
            }
        }
    }
}
