import UIKit

class ArticleTableViewCell: UITableViewCell {
    static let identifier = "ArticleTableViewCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let checkboxButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        button.tintColor = .systemBlue
        button.contentMode = .scaleAspectFit
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let approveCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    private var article: ArticleDisplayModel?
    private var onCheckboxToggle: ((String) -> Void)?
    private var isAuthorMode = false
    private var titleLeadingConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(checkboxButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(approveCountLabel)
        
        // Create flexible title leading constraint
        titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 12)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            checkboxButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            checkboxButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLeadingConstraint!,
            titleLabel.trailingAnchor.constraint(equalTo: approveCountLabel.leadingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            approveCountLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            approveCountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            approveCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }
    
    private func setupActions() {
        checkboxButton.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func checkboxTapped() {
        guard let article = article else { return }
        
        // Toggle the button state immediately for visual feedback
        checkboxButton.isSelected.toggle()
        
        // Debug print
        print("Checkbox tapped for article: \(article.name), isSelected: \(checkboxButton.isSelected)")
        
        onCheckboxToggle?(article.articleId)
    }
    
    // MARK: - Configuration
    func configure(with article: ArticleDisplayModel, 
                  isSelected: Bool = false, 
                  isAuthorMode: Bool = false,
                  onCheckboxToggle: ((String) -> Void)? = nil) {
        self.article = article
        self.onCheckboxToggle = onCheckboxToggle
        self.isAuthorMode = isAuthorMode
        
        titleLabel.text = article.name
        descriptionLabel.text = article.article
        
        // Update leading constraint based on mode
        titleLeadingConstraint?.isActive = false
        
        if isAuthorMode {
            checkboxButton.isHidden = true
            approveCountLabel.isHidden = false
            approveCountLabel.text = "\(article.approveCount) approvals"
            
            // Adjust constraint for author mode
            titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12)
        } else {
            checkboxButton.isHidden = false
            approveCountLabel.isHidden = true
            
            // Ensure checkbox images are set properly
            checkboxButton.setImage(UIImage(systemName: "square"), for: .normal)
            checkboxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
            checkboxButton.tintColor = .systemBlue
            checkboxButton.isSelected = isSelected
            
            // Force update the button appearance
            checkboxButton.setNeedsDisplay()
            checkboxButton.layoutIfNeeded()
            
            // Adjust constraint for reviewer mode
            titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 12)
        }
        
        titleLeadingConstraint?.isActive = true
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        article = nil
        onCheckboxToggle = nil
        checkboxButton.isSelected = false
        checkboxButton.isHidden = false
        approveCountLabel.isHidden = true
        titleLabel.text = nil
        descriptionLabel.text = nil
        approveCountLabel.text = nil
    }
}
