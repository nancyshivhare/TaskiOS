import CoreData
import UIKit

class CoreDataService {
    static let shared = CoreDataService()
    
    private init() {}
    
    private var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    // MARK: - Article Metadata Operations
    func saveArticleMetadata(_ metadata: ArticleMetadataResponse) {
        let request: NSFetchRequest<ArticleMetadata> = ArticleMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "articleId == %@", metadata.articleId)
        
        do {
            let existingMetadata = try context.fetch(request)
            let articleMetadata = existingMetadata.first ?? ArticleMetadata(context: context)
            
            articleMetadata.articleId = metadata.articleId
            articleMetadata.author = metadata.author
            articleMetadata.approveCount = Int32(metadata.approveCount)
            
            saveContext()
        } catch {
            print("Failed to save article metadata: \(error)")
        }
    }
    
    // MARK: - Article Details Operations
    func saveArticleDetails(_ details: ArticleDetailsResponse) {
        let request: NSFetchRequest<ArticleDetails> = ArticleDetails.fetchRequest()
        request.predicate = NSPredicate(format: "articleId == %@", details.articleId)
        
        do {
            let existingDetails = try context.fetch(request)
            let articleDetails = existingDetails.first ?? ArticleDetails(context: context)
            
            articleDetails.articleId = details.articleId
            articleDetails.name = details.name
            articleDetails.article = details.article
            articleDetails.createdAt = ISO8601DateFormatter().date(from: details.createdAt)
            articleDetails.updatedAt = ISO8601DateFormatter().date(from: details.updatedAt)
            articleDetails.approvedBy = details.approvedBy
            
            // Link to metadata if exists
            let metadataRequest: NSFetchRequest<ArticleMetadata> = ArticleMetadata.fetchRequest()
            metadataRequest.predicate = NSPredicate(format: "articleId == %@", details.articleId)
            
            if let metadata = try context.fetch(metadataRequest).first {
                articleDetails.metadata = metadata
            }
            
            saveContext()
        } catch {
            print("Failed to save article details: \(error)")
        }
    }
    
    // MARK: - Fetch Operations
    func fetchAllArticles() -> [ArticleDisplayModel] {
        let request: NSFetchRequest<ArticleMetadata> = ArticleMetadata.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "author", ascending: true)]
        
        do {
            let metadataList = try context.fetch(request)
            return metadataList.compactMap { metadata in
                guard let details = metadata.details else { return nil }
                
                return ArticleDisplayModel(
                    articleId: metadata.articleId ?? "",
                    name: details.name ?? "",
                    article: details.article ?? "",
                    author: metadata.author ?? "",
                    approveCount: Int(metadata.approveCount),
                    createdAt: details.createdAt ?? Date(),
                    updatedAt: details.updatedAt ?? Date(),
                    approvedBy: details.approvedBy ?? []
                )
            }
        } catch {
            print("Failed to fetch articles: \(error)")
            return []
        }
    }
    
    func fetchArticlesByAuthor(_ author: String) -> [ArticleDisplayModel] {
        let request: NSFetchRequest<ArticleMetadata> = ArticleMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "author == %@", author)
        request.sortDescriptors = [NSSortDescriptor(key: "articleId", ascending: true)]
        
        do {
            let metadataList = try context.fetch(request)
            return metadataList.compactMap { metadata in
                guard let details = metadata.details else { return nil }
                
                return ArticleDisplayModel(
                    articleId: metadata.articleId ?? "",
                    name: details.name ?? "",
                    article: details.article ?? "",
                    author: metadata.author ?? "",
                    approveCount: Int(metadata.approveCount),
                    createdAt: details.createdAt ?? Date(),
                    updatedAt: details.updatedAt ?? Date(),
                    approvedBy: details.approvedBy ?? []
                )
            }
        } catch {
            print("Failed to fetch articles by author: \(error)")
            return []
        }
    }
    
    func hasArticles() -> Bool {
        let request: NSFetchRequest<ArticleMetadata> = ArticleMetadata.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Failed to check for articles: \(error)")
            return false
        }
    }
    
    // MARK: - Approval Operations
    func addApprovalToArticle(articleId: String, reviewerName: String) {
        let request: NSFetchRequest<ArticleDetails> = ArticleDetails.fetchRequest()
        request.predicate = NSPredicate(format: "articleId == %@", articleId)
        
        do {
            guard let articleDetails = try context.fetch(request).first else { return }
            
            var approvedBy = articleDetails.approvedBy ?? []
            if !approvedBy.contains(reviewerName) {
                approvedBy.append(reviewerName)
                articleDetails.approvedBy = approvedBy
                
                // Update approve count in metadata
                if let metadata = articleDetails.metadata {
                    metadata.approveCount = Int32(approvedBy.count)
                }
                
                saveContext()
            }
        } catch {
            print("Failed to add approval: \(error)")
        }
    }
    
    // MARK: - Clear Data
    func clearAllData() {
        let metadataRequest: NSFetchRequest<NSFetchRequestResult> = ArticleMetadata.fetchRequest()
        let detailsRequest: NSFetchRequest<NSFetchRequestResult> = ArticleDetails.fetchRequest()
        
        let deleteMetadataRequest = NSBatchDeleteRequest(fetchRequest: metadataRequest)
        let deleteDetailsRequest = NSBatchDeleteRequest(fetchRequest: detailsRequest)
        
        do {
            try context.execute(deleteMetadataRequest)
            try context.execute(deleteDetailsRequest)
            saveContext()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}
