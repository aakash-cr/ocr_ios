import Foundation

/// Data model representing a utility form with extracted OCR data
struct UtilityForm: Codable, Identifiable, Equatable {
    var id = UUID()
    var consumerName: String
    var mobileNumber: String
    var meterNumber: String
    var reading: String
    
    init(consumerName: String = "", mobileNumber: String = "", meterNumber: String = "", reading: String = "") {
        self.consumerName = consumerName
        self.mobileNumber = mobileNumber
        self.meterNumber = meterNumber
        self.reading = reading
    }
}

