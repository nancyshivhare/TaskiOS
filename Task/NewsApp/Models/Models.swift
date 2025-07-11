import Foundation

// MARK: - User Role
enum UserRole: String, CaseIterable {
    case author = "Author"
    case reviewer = "Reviewer"
}

// MARK: - User Model
struct User {
    let username: String
    let role: UserRole
}

// MARK: - Article Metadata Response
struct ArticleMetadataResponse: Codable {
    let articleId: String
    let author: String
    let approveCount: Int
}

// MARK: - Article Details Response
struct ArticleDetailsResponse: Codable {
    let articleId: String
    let name: String
    let article: String
    let createdAt: String
    let updatedAt: String
    let approvedBy: [String]
}

// MARK: - Article Display Model
struct ArticleDisplayModel {
    let articleId: String
    let name: String
    let article: String
    let author: String
    let approveCount: Int
    let createdAt: Date
    let updatedAt: Date
    let approvedBy: [String]
    var isSelected: Bool = false
}

// MARK: - Section Model for Reviewer
struct ArticleSection {
    let author: String
    var articles: [ArticleDisplayModel]
}

// MARK: - Network Error
enum NetworkError: Error {
    case noConnection
    case invalidResponse
    case decodingError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// MARK: - Sync Status
enum SyncStatus {
    case idle
    case syncing
    case success
    case failure(Error)
}
