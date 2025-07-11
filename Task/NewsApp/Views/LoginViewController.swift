import UIKit
import Combine

class LoginViewController: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "News App"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter username"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let syncButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sync", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.isHidden = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .systemBlue
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let autoSyncIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let lastSyncLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset navigation if coming back from news screen
        viewModel.shouldNavigateToNews = false
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(usernameTextField)
        view.addSubview(loginButton)
        view.addSubview(syncButton)
        view.addSubview(progressView)
        view.addSubview(statusLabel)
        view.addSubview(autoSyncIndicator)
        view.addSubview(lastSyncLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            usernameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            syncButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            syncButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            syncButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            syncButton.heightAnchor.constraint(equalToConstant: 50),
            
            progressView.bottomAnchor.constraint(equalTo: syncButton.topAnchor, constant: -20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statusLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            autoSyncIndicator.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            autoSyncIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            lastSyncLabel.topAnchor.constraint(equalTo: autoSyncIndicator.bottomAnchor, constant: 10),
            lastSyncLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            lastSyncLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupBindings() {
        // Bind username text field
        usernameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // Bind view model properties
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateUI(isLoading: isLoading)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.showError(errorMessage)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$shouldNavigateToNews
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldNavigate in
                if shouldNavigate {
                    self?.navigateToNews()
                }
            }
            .store(in: &cancellables)
        
        // Bind sync progress
        SyncService.shared.$syncProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressView.progress = progress
            }
            .store(in: &cancellables)
        
        SyncService.shared.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateSyncStatus(status)
            }
            .store(in: &cancellables)
        
        // Bind auto-sync progress
        viewModel.$autoSyncInProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isInProgress in
                if isInProgress {
                    self?.autoSyncIndicator.startAnimating()
                } else {
                    self?.autoSyncIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        // Bind last sync time
        viewModel.$lastAutoSyncTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lastSyncTime in
                self?.updateLastSyncLabel(lastSyncTime)
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        syncButton.addTarget(self, action: #selector(syncButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange() {
        viewModel.username = usernameTextField.text ?? ""
    }
    
    @objc private func loginButtonTapped() {
        viewModel.login()
    }
    
    @objc private func syncButtonTapped() {
        viewModel.sync()
    }
    
    // MARK: - Helper Methods
    private func updateUI(isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        syncButton.isEnabled = !isLoading
        usernameTextField.isEnabled = !isLoading
        
        if isLoading {
            progressView.isHidden = false
            statusLabel.text = "Syncing..."
            statusLabel.textColor = .systemBlue
        }
    }
    
    private func updateSyncStatus(_ status: SyncStatus) {
        switch status {
        case .idle:
            progressView.isHidden = true
            statusLabel.text = ""
        case .syncing:
            progressView.isHidden = false
            statusLabel.text = "Syncing..."
            statusLabel.textColor = .systemBlue
        case .success:
            progressView.isHidden = true
            statusLabel.text = "Sync completed successfully!"
            statusLabel.textColor = .systemGreen
            
            // Clear status after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.statusLabel.text = ""
            }
        case .failure(let error):
            progressView.isHidden = true
            statusLabel.text = "Sync failed: \(error.localizedDescription)"
            statusLabel.textColor = .systemRed
        }
    }
    
    private func updateLastSyncLabel(_ lastSyncTime: Date?) {
        if let lastSyncTime = lastSyncTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            lastSyncLabel.text = "Last auto-sync: \(formatter.string(from: lastSyncTime))"
        } else {
            lastSyncLabel.text = ""
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.viewModel.clearErrorMessage()
        })
        present(alert, animated: true)
    }
    
    private func navigateToNews() {
        let newsViewController = NewsViewController()
        navigationController?.pushViewController(newsViewController, animated: true)
    }
}
