import Foundation
import Vision
import UIKit

class OCRProcessor {
    func processImage(_ image: UIImage, completion: @escaping (Result<UtilityForm, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "OCR", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Image"])))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(NSError(domain: "OCR", code: 2, userInfo: [NSLocalizedDescriptionKey: "No text found"])))
                return
            }
            let extractedForm = self.mapObservationsToFields(observations)
            completion(.success(extractedForm))
        }

        // --- CRITICAL NATIVE OPTIMIZATIONS ---
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["hi-IN", "en-US"]
        request.usesLanguageCorrection = false // Stops "sepisnoy" style hallucinations
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func mapObservationsToFields(_ observations: [VNRecognizedTextObservation]) -> UtilityForm {
        var form = UtilityForm()
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            let box = observation.boundingBox // Coordinates are 0.0 to 1.0 (bottom-left origin)

            // 1. Consumer Name Zone (Top Middle)
            if box.minY > 0.80 && box.minX > 0.30 && box.minX < 0.70 {
                if !text.contains("नाम") && text.count > 3 {
                    form.consumerName = text
                }
            }
            
            // 2. Mobile Number Zone (Just below Name)
            if box.minY > 0.75 && box.minY < 0.80 && box.minX > 0.15 && box.minX < 0.50 {
                let digits = text.filter { $0.isNumber }
                if digits.count >= 10 { form.mobileNumber = digits }
            }
            
            // 3. New Meter Number (Center Table)
            if box.minY > 0.60 && box.minY < 0.70 && box.minX > 0.30 && box.minX < 0.55 {
                if text.range(of: "[A-Z0-9]{6,}", options: .regularExpression) != nil {
                    form.meterNumber = text
                }
            }
            
            // 4. Reading / KWH (Table Middle)
            if box.minY > 0.35 && box.minY < 0.55 && box.minX > 0.40 && box.minX < 0.60 {
                if text.allSatisfy({ $0.isNumber || $0 == "." }) {
                    form.reading = text
                }
            }
        }
        return form
    }
}