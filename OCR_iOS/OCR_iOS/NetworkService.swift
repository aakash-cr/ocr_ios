import Foundation
import UIKit

class NetworkService {
    static let shared = NetworkService()
    
    #if DEBUG
    private let baseURL = "http://192.168.1.100:8080" // TODO: Replace with your Mac's local IP
    #else
    private let baseURL = "https://your-production-url.run.app" // TODO: Replace with production URL
    #endif
    
    private init() {}
    
    func extractFromImage(_ image: UIImage) async throws -> ExtractionResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.invalidImage
        }
        
        guard let url = URL(string: "\(baseURL)/extract") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
            throw NetworkError.serverError(errorMessage)
        }
        
        do {
            return try JSONDecoder().decode(ExtractionResult.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
}

enum NetworkError: LocalizedError {
    case invalidImage
    case invalidURL
    case invalidResponse
    case serverError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to convert image to data"
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        }
    }
}

struct ExtractionResult: Codable {
    let consumer_number: FieldResult?
    let consumer_name: FieldResult?
    let meter_number: FieldResult?
    let date: FieldResult?
    let needs_review: [String]
}

struct FieldResult: Codable {
    let value: String
    let confidence: Double
}


