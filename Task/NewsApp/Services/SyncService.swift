import Foundation
import Combine

class SyncService {
    static let shared = SyncService()
    
    private let networkService = NetworkService.shared
    private let coreDataService = CoreDataService.shared
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncProgress: Float = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func syncArticles() async {
        await MainActor.run {
            syncStatus = .syncing
            syncProgress = 0.0
        }
        
        do {
            // Step 1: Fetch all article metadata (10% progress)
            let metadataList = try await networkService.fetchArticleMetadata()
            await MainActor.run {
                syncProgress = 0.1
            }
            
            // Step 2: Fetch details for each article (80% progress)
            let totalArticles = metadataList.count
            var processedArticles = 0
            
            for metadata in metadataList {
                do {
                    let details = try await networkService.fetchArticleDetails(articleId: metadata.articleId)
                    
                    // Merge with local data
                    let localArticles = coreDataService.fetchAllArticles()
                    let localArticle = localArticles.first { $0.articleId == metadata.articleId }
                    
                    // Keep local approvals if they exist
                    var mergedDetails = details
                    if let localArticle = localArticle {
                        // Merge approvals (keep both local and server)
                        var mergedApprovals = Set(details.approvedBy)
                        mergedApprovals.formUnion(localArticle.approvedBy)
                        mergedDetails = ArticleDetailsResponse(
                            articleId: details.articleId,
                            name: details.name,
                            article: details.article,
                            createdAt: details.createdAt,
                            updatedAt: details.updatedAt,
                            approvedBy: Array(mergedApprovals)
                        )
                    }
                    
                    // Save merged data
                    coreDataService.saveArticleMetadata(ArticleMetadataResponse(
                        articleId: metadata.articleId,
                        author: metadata.author,
                        approveCount: mergedDetails.approvedBy.count
                    ))
                    
                    coreDataService.saveArticleDetails(mergedDetails)
                    
                    processedArticles += 1
                    let progress = 0.1 + (Float(processedArticles) / Float(totalArticles) * 0.8)
                    await MainActor.run {
                        syncProgress = progress
                    }

                } catch {
                    print("Failed to sync article \(metadata.articleId): \(error)")
                }
            }
            
            // Step 3: Send merged data back to server (10% progress)
            let mergedArticles = coreDataService.fetchAllArticles()
            try await networkService.sendMergedData(mergedArticles)
            
            await MainActor.run {
                syncProgress = 1.0
                syncStatus = .success
            }
            
        } catch {
            await MainActor.run {
                syncStatus = .failure(error)
            }
        }
    }
}
