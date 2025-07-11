import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var shouldNavigateToNews: Bool = false
    @Published var autoSyncInProgress: Bool = false
    @Published var lastAutoSyncTime: Date?
    
    private let coreDataService = CoreDataService.shared
    private let syncService = SyncService.shared
    private var networkMonitor = NetworkMonitor.shared
    private var autoSyncTimer: Timer?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAutoSync()
        setupNetworkMonitoring()
    }
    
    private func setupAutoSync() {
        // Auto-sync setup (every 15 minutes)
        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            self?.performAutoSync()
        }
    }
    
    private func setupNetworkMonitoring() {
        // Monitor network connection changes
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected {
                    // Network is back, perform auto-sync
                    self?.performAutoSync()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performAutoSync() {
        guard networkMonitor.isConnected else { return }
        
        autoSyncInProgress = true
        
        Task {
            await syncService.syncArticles()
            
            await MainActor.run {
                self.autoSyncInProgress = false
                self.lastAutoSyncTime = Date()
            }
        }
    }
    
    func login() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a username"
            return
        }
        
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let userRole: UserRole = cleanUsername.lowercased() == "robert" ? .author : .reviewer
        
        // Store in UserDefaults
        UserDefaults.standard.set(cleanUsername, forKey: "username")
        UserDefaults.standard.set(userRole.rawValue, forKey: "userRole")
        
        // Check if database has articles
        if !coreDataService.hasArticles() {
            errorMessage = "Please sync the app."
            return
        }
        
        shouldNavigateToNews = true
    }
    
    func sync() {
        guard NetworkMonitor.shared.isConnected else {
            errorMessage = "No internet connection. Please check your network and try again."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            await syncService.syncArticles()
            
            await MainActor.run {
                isLoading = false
                
                switch syncService.syncStatus {
                case .success:
                    // Sync completed successfully
                    break
                case .failure(let error):
                    errorMessage = "Sync failed: \(error.localizedDescription)"
                default:
                    break
                }
            }
        }
    }
    
    func clearErrorMessage() {
        errorMessage = nil
    }
}
