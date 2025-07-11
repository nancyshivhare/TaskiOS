import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    // MARK: - Mock Data
    private let mockMetadata = [
        ArticleMetadataResponse(articleId: "ART001", author: "Robert", approveCount: 5),
        ArticleMetadataResponse(articleId: "ART002", author: "Robert", approveCount: 3),
        ArticleMetadataResponse(articleId: "ART003", author: "Robert", approveCount: 7),
        ArticleMetadataResponse(articleId: "ART004", author: "Robert", approveCount: 2),
        ArticleMetadataResponse(articleId: "ART005", author: "Alice", approveCount: 8),
        ArticleMetadataResponse(articleId: "ART006", author: "Alice", approveCount: 4),
        ArticleMetadataResponse(articleId: "ART007", author: "Bob", approveCount: 6),
        ArticleMetadataResponse(articleId: "ART008", author: "Bob", approveCount: 1),
        ArticleMetadataResponse(articleId: "ART009", author: "Charlie", approveCount: 9),
        ArticleMetadataResponse(articleId: "ART010", author: "Charlie", approveCount: 3),
        ArticleMetadataResponse(articleId: "ART011", author: "Diana", approveCount: 5),
        ArticleMetadataResponse(articleId: "ART012", author: "Diana", approveCount: 7),
        ArticleMetadataResponse(articleId: "ART013", author: "Eve", approveCount: 2),
        ArticleMetadataResponse(articleId: "ART014", author: "Eve", approveCount: 8),
        ArticleMetadataResponse(articleId: "ART015", author: "Frank", approveCount: 4),
        ArticleMetadataResponse(articleId: "ART016", author: "Frank", approveCount: 6),
        ArticleMetadataResponse(articleId: "ART017", author: "Grace", approveCount: 1),
        ArticleMetadataResponse(articleId: "ART018", author: "Grace", approveCount: 9),
        ArticleMetadataResponse(articleId: "ART019", author: "Henry", approveCount: 3),
        ArticleMetadataResponse(articleId: "ART020", author: "Henry", approveCount: 5)
    ]
    
    private let mockDetails: [String: ArticleDetailsResponse] = [
        "ART001": ArticleDetailsResponse(articleId: "ART001", name: "Perfume", article: "Perfumes are made from essential oils and aroma compounds that give them their distinctive scent.", createdAt: "2024-12-01T10:30:00Z", updatedAt: "2025-06-25T09:15:00Z", approvedBy: ["Mark", "John"]),
        "ART002": ArticleDetailsResponse(articleId: "ART002", name: "Technology", article: "Technology continues to evolve rapidly, changing how we work and live in the modern world.", createdAt: "2024-11-15T14:20:00Z", updatedAt: "2025-06-20T11:30:00Z", approvedBy: ["Sarah"]),
        "ART003": ArticleDetailsResponse(articleId: "ART003", name: "Travel", article: "Travel broadens the mind and offers new perspectives on different cultures and ways of life.", createdAt: "2024-10-10T16:45:00Z", updatedAt: "2025-06-15T08:20:00Z", approvedBy: ["Mike", "Lisa", "Tom"]),
        "ART004": ArticleDetailsResponse(articleId: "ART004", name: "Food", article: "Food is not just sustenance but a way to connect with culture and create lasting memories.", createdAt: "2024-09-05T12:15:00Z", updatedAt: "2025-06-10T15:45:00Z", approvedBy: ["Anna"]),
        "ART005": ArticleDetailsResponse(articleId: "ART005", name: "Music", article: "Music has the power to transcend language barriers and connect people across different cultures.", createdAt: "2024-08-20T09:30:00Z", updatedAt: "2025-06-05T13:10:00Z", approvedBy: ["David", "Emma"]),
        "ART006": ArticleDetailsResponse(articleId: "ART006", name: "Sports", article: "Sports teach valuable life lessons about teamwork, perseverance, and healthy competition.", createdAt: "2024-07-15T11:00:00Z", updatedAt: "2025-06-01T10:25:00Z", approvedBy: ["Chris"]),
        "ART007": ArticleDetailsResponse(articleId: "ART007", name: "Art", article: "Art is a form of expression that allows artists to communicate emotions and ideas visually.", createdAt: "2024-06-10T15:30:00Z", updatedAt: "2025-05-28T14:15:00Z", approvedBy: ["Julia", "Kevin"]),
        "ART008": ArticleDetailsResponse(articleId: "ART008", name: "Science", article: "Science helps us understand the world around us through observation and experimentation.", createdAt: "2024-05-05T13:45:00Z", updatedAt: "2025-05-25T16:30:00Z", approvedBy: ["Rachel"]),
        "ART009": ArticleDetailsResponse(articleId: "ART009", name: "Nature", article: "Nature provides countless wonders and serves as a source of inspiration and tranquility.", createdAt: "2024-04-20T10:20:00Z", updatedAt: "2025-05-20T12:45:00Z", approvedBy: ["Steve", "Monica", "Peter"]),
        "ART010": ArticleDetailsResponse(articleId: "ART010", name: "History", article: "History teaches us about the past and helps us understand the present and future.", createdAt: "2024-03-15T08:15:00Z", updatedAt: "2025-05-15T09:30:00Z", approvedBy: ["Linda"]),
        "ART011": ArticleDetailsResponse(articleId: "ART011", name: "Literature", article: "Literature offers a window into different worlds and perspectives through storytelling.", createdAt: "2024-02-10T14:50:00Z", updatedAt: "2025-05-10T11:20:00Z", approvedBy: ["Robert", "Helen"]),
        "ART012": ArticleDetailsResponse(articleId: "ART012", name: "Fashion", article: "Fashion is a form of self-expression that reflects personality and cultural trends.", createdAt: "2024-01-25T12:35:00Z", updatedAt: "2025-05-05T15:10:00Z", approvedBy: ["Sophie"]),
        "ART013": ArticleDetailsResponse(articleId: "ART013", name: "Health", article: "Health is our most valuable asset and requires consistent care and attention.", createdAt: "2023-12-20T16:25:00Z", updatedAt: "2025-05-01T13:55:00Z", approvedBy: ["Doctor Smith"]),
        "ART014": ArticleDetailsResponse(articleId: "ART014", name: "Education", article: "Education is the foundation of personal growth and societal progress.", createdAt: "2023-11-15T11:40:00Z", updatedAt: "2025-04-28T10:40:00Z", approvedBy: ["Professor Johnson", "Ms. Williams"]),
        "ART015": ArticleDetailsResponse(articleId: "ART015", name: "Environment", article: "Environmental protection is crucial for the sustainability of our planet.", createdAt: "2023-10-30T09:55:00Z", updatedAt: "2025-04-25T14:25:00Z", approvedBy: ["Green Activist"]),
        "ART016": ArticleDetailsResponse(articleId: "ART016", name: "Innovation", article: "Innovation drives progress and creates solutions to complex problems.", createdAt: "2023-09-25T13:10:00Z", updatedAt: "2025-04-20T16:50:00Z", approvedBy: ["Tech Leader", "Innovator"]),
        "ART017": ArticleDetailsResponse(articleId: "ART017", name: "Community", article: "Community building strengthens social bonds and creates support networks.", createdAt: "2023-08-20T15:20:00Z", updatedAt: "2025-04-15T12:15:00Z", approvedBy: ["Community Leader"]),
        "ART018": ArticleDetailsResponse(articleId: "ART018", name: "Culture", article: "Culture shapes our identity and connects us to our heritage and traditions.", createdAt: "2023-07-15T10:45:00Z", updatedAt: "2025-04-10T09:35:00Z", approvedBy: ["Anthropologist", "Historian", "Cultural Expert"]),
        "ART019": ArticleDetailsResponse(articleId: "ART019", name: "Philosophy", article: "Philosophy encourages critical thinking and explores fundamental questions about existence.", createdAt: "2023-06-10T14:30:00Z", updatedAt: "2025-04-05T11:50:00Z", approvedBy: ["Philosopher"]),
        "ART020": ArticleDetailsResponse(articleId: "ART020", name: "Economics", article: "Economics studies how societies allocate resources and make decisions about production and consumption.", createdAt: "2023-05-05T12:05:00Z", updatedAt: "2025-04-01T15:25:00Z", approvedBy: ["Economist", "Policy Maker"])
    ]
    
    // MARK: - Network Methods
    func fetchArticleMetadata() async throws -> [ArticleMetadataResponse] {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noConnection
        }
        
        // Simulate 2-second delay
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        return mockMetadata
    }
    
    func fetchArticleDetails(articleId: String) async throws -> ArticleDetailsResponse {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noConnection
        }
        
        // Simulate 2-second delay
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        guard let details = mockDetails[articleId] else {
            throw NetworkError.invalidResponse
        }
        
        return details
    }
    
    func sendMergedData(_ articles: [ArticleDisplayModel]) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noConnection
        }
        
        // Simulate 2-second delay for PUT request
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // In a real app, this would send the merged data to the server
        print("Merged data sent to server: \(articles.count) articles")
    }
}
