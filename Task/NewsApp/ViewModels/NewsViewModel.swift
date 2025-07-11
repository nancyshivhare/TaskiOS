import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var sections: [ArticleSection] = []
    @Published var authorArticles: [ArticleDisplayModel] = []
    @Published var isLoading: Bool = false
    @Published var isPaginating: Bool = false
    @Published var errorMessage: String?
    @Published var hasMorePages: Bool = true
    @Published var selectedArticleIds: Set<String> = []
    
    private let coreDataService = CoreDataService.shared
    private let itemsPerPage = 5
    private var currentPage = 0
    private var allArticles: [ArticleDisplayModel] = []
    
    var userRole: UserRole {
        let roleString = UserDefaults.standard.string(forKey: "userRole") ?? ""
        return UserRole(rawValue: roleString) ?? .reviewer
    }
    
    var username: String {
        return UserDefaults.standard.string(forKey: "username") ?? ""
    }
    
    func loadArticles() {
        currentPage = 0
        hasMorePages = true
        selectedArticleIds.removeAll()
        
        if userRole == .author {
            loadAuthorArticles()
        } else {
            loadReviewerArticles()
        }
    }
    
    private func loadAuthorArticles() {
        authorArticles = coreDataService.fetchArticlesByAuthor(username)
    }
    
    private func loadReviewerArticles() {
        allArticles = coreDataService.fetchAllArticles()
        print("Total articles available: \(allArticles.count)")
        
        // Reset sections for fresh load
        sections = []
        
        // Load first page
        loadNextPage()
    }
    
    func loadNextPage() {
        guard userRole == .reviewer && hasMorePages && !isPaginating else { return }
        
        isPaginating = true
        print("Loading next page: \(currentPage + 1)")
        
        // Add a small delay to show the loading indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let startIndex = self.currentPage * self.itemsPerPage
            let endIndex = min(startIndex + self.itemsPerPage, self.allArticles.count)
            
            if startIndex >= self.allArticles.count {
                self.hasMorePages = false
                self.isPaginating = false
                print("No more pages to load")
                return
            }
            
            let newArticles = Array(self.allArticles[startIndex..<endIndex])
            print("Loading \(newArticles.count) new articles")
            
            // Group by author
            var sectionDict: [String: [ArticleDisplayModel]] = [:]
            
            // Add existing articles from current sections
            for section in self.sections {
                sectionDict[section.author] = section.articles
            }
            
            // Add new articles
            for article in newArticles {
                if sectionDict[article.author] != nil {
                    sectionDict[article.author]?.append(article)
                } else {
                    sectionDict[article.author] = [article]
                }
            }
            
            // Convert back to sections and sort by author name
            self.sections = sectionDict.map { author, articles in
                ArticleSection(author: author, articles: articles.sorted { $0.name < $1.name })
            }.sorted { $0.author < $1.author }
            
            self.currentPage += 1
            self.hasMorePages = endIndex < self.allArticles.count
            self.isPaginating = false
            
            print("Current page: \(self.currentPage), Has more pages: \(self.hasMorePages)")
            print("Total sections: \(self.sections.count)")
        }
    }
    
    func toggleSelection(for articleId: String) {
        if selectedArticleIds.contains(articleId) {
            selectedArticleIds.remove(articleId)
        } else {
            selectedArticleIds.insert(articleId)
        }
    }
    
    func isSelected(articleId: String) -> Bool {
        return selectedArticleIds.contains(articleId)
    }
    
    func markSelectedAsApproved() {
        guard NetworkMonitor.shared.isConnected else {
            errorMessage = "No internet connection. Please check your network and try again."
            return
        }
        
        guard !selectedArticleIds.isEmpty else {
            errorMessage = "Please select at least one article to approve."
            return
        }
        
        for articleId in selectedArticleIds {
            coreDataService.addApprovalToArticle(articleId: articleId, reviewerName: username)
        }
        
        // Clear selections and reload
        selectedArticleIds.removeAll()
        loadArticles()
    }
    
    func clearErrorMessage() {
        errorMessage = nil
    }
}
