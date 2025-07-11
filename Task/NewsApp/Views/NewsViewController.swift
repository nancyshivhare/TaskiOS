import UIKit
import Combine

class NewsViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let markApproveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Mark Approve", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let paginationLoadingView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let paginationSpinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let paginationLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading more articles..."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    private let viewModel = NewsViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupBindings()
        setupActions()
        setupNavigationBar()
        
        viewModel.loadArticles()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(markApproveButton)
        view.addSubview(loadingIndicator)
        
        // Setup pagination loading view
        paginationLoadingView.addSubview(paginationSpinner)
        paginationLoadingView.addSubview(paginationLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            markApproveButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
            markApproveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            markApproveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            markApproveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            markApproveButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Pagination loading view constraints
            paginationLoadingView.heightAnchor.constraint(equalToConstant: 60),
            paginationSpinner.leadingAnchor.constraint(equalTo: paginationLoadingView.leadingAnchor, constant: 16),
            paginationSpinner.centerYAnchor.constraint(equalTo: paginationLoadingView.centerYAnchor),
            paginationLabel.leadingAnchor.constraint(equalTo: paginationSpinner.trailingAnchor, constant: 8),
            paginationLabel.centerYAnchor.constraint(equalTo: paginationLoadingView.centerYAnchor),
            paginationLabel.trailingAnchor.constraint(equalTo: paginationLoadingView.trailingAnchor, constant: -16)
        ])
        
        // Hide mark approve button for authors
        markApproveButton.isHidden = viewModel.userRole == .author
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ArticleTableViewCell.self, forCellReuseIdentifier: ArticleTableViewCell.identifier)
    }
    
    private func setupBindings() {
        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$authorArticles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
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
        
        viewModel.$selectedArticleIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedIds in
                self?.updateMarkApproveButton(selectedCount: selectedIds.count)
            }
            .store(in: &cancellables)
        
        viewModel.$isPaginating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPaginating in
                self?.updatePaginationFooter(isPaginating: isPaginating)
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        markApproveButton.addTarget(self, action: #selector(markApproveButtonTapped), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        title = viewModel.userRole == .author ? "My Articles" : "All Articles"
        
        // Hide back button since user is logged in
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        
        // Add logout button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutButtonTapped)
        )
    }
    
    // MARK: - Actions
    @objc private func markApproveButtonTapped() {
        viewModel.markSelectedAsApproved()
    }
    
    @objc private func logoutButtonTapped() {
        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "userRole")
        
        // Navigate back to login
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    private func updateMarkApproveButton(selectedCount: Int) {
        if selectedCount > 0 {
            markApproveButton.setTitle("Mark Approve (\(selectedCount))", for: .normal)
            markApproveButton.alpha = 1.0
        } else {
            markApproveButton.setTitle("Mark Approve", for: .normal)
            markApproveButton.alpha = 0.6
        }
    }
    
    private func updatePaginationFooter(isPaginating: Bool) {
        if isPaginating && viewModel.userRole == .reviewer {
            paginationSpinner.startAnimating()
            tableView.tableFooterView = paginationLoadingView
        } else {
            paginationSpinner.stopAnimating()
            tableView.tableFooterView = nil
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.viewModel.clearErrorMessage()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension NewsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.userRole == .author ? 1 : viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.userRole == .author {
            return viewModel.authorArticles.count
        } else {
            return viewModel.sections[section].articles.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleTableViewCell.identifier, for: indexPath) as! ArticleTableViewCell
        
        let article: ArticleDisplayModel
        if viewModel.userRole == .author {
            article = viewModel.authorArticles[indexPath.row]
        } else {
            article = viewModel.sections[indexPath.section].articles[indexPath.row]
        }
        
        let isSelected = viewModel.isSelected(articleId: article.articleId)
        let isAuthorMode = viewModel.userRole == .author
        
        // Debug print
        print("Configuring cell for article: \(article.name), isSelected: \(isSelected), isAuthorMode: \(isAuthorMode)")
        
        cell.configure(
            with: article,
            isSelected: isSelected,
            isAuthorMode: isAuthorMode,
            onCheckboxToggle: { [weak self] articleId in
                print("Checkbox toggled for articleId: \(articleId)")
                self?.viewModel.toggleSelection(for: articleId)
            }
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if viewModel.userRole == .reviewer && !viewModel.sections.isEmpty {
            return viewModel.sections[section].author
        }
        return nil
    }
}

// MARK: - UITableViewDelegate
extension NewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Implement pagination for reviewers
        if viewModel.userRole == .reviewer && !viewModel.sections.isEmpty {
            let lastSectionIndex = viewModel.sections.count - 1
            let lastRowIndex = viewModel.sections[lastSectionIndex].articles.count - 1
            
            // Check if we're displaying the last cell
            if indexPath.section == lastSectionIndex && indexPath.row == lastRowIndex {
                if viewModel.hasMorePages {
                    print("Loading next page...")
                    viewModel.loadNextPage()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.userRole == .reviewer && !viewModel.sections.isEmpty {
            let headerView = UIView()
            headerView.backgroundColor = .systemGroupedBackground
            
            let label = UILabel()
            label.text = viewModel.sections[section].author
            label.font = .systemFont(ofSize: 18, weight: .semibold)
            label.textColor = .label
            label.translatesAutoresizingMaskIntoConstraints = false
            
            headerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
            ])
            
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.userRole == .reviewer && !viewModel.sections.isEmpty {
            return 40
        }
        return 0
    }
}
