//
//  AlertController.swift
//  Cantoboard
//
//  Created by Alex Man on 31/3/25.
//

import UIKit

// A custom implementation replicating UIAlertController as its use is forbidden in extensions
class AlertController: UIViewController {
    
    // MARK: - Public Properties
    
    /// The style of the alert controller
    enum Style: Int {
        case alert
        // case actionSheet
    }
    
    /// The title of the alert
    let alertTitle: String?
    
    /// The message of the alert
    let message: String?
    
    /// The style of the alert
    let preferredStyle: Style
    
    /// The actions added to the alert controller (read-only)
    private(set) var actions = [AlertAction]()
    
    var preferredAction: AlertAction? = nil
    
    // MARK: - Private Properties
    private var alertView: UIView!
    private var buttonsContainerView: UIStackView!
    
    // MARK: - Initializers
    
    /// Creates a custom alert controller with the specified title, message, and style
    init(title: String?, message: String?, preferredStyle: Style) {
        self.alertTitle = title
        self.message = message
        self.preferredStyle = preferredStyle
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAlertView()
    }
    
    // MARK: - Public Methods
    
    /// Adds an action to the alert controller
    func addAction(_ action: AlertAction) {
        actions.append(action)
        
        if isViewLoaded {
            addActionButton(for: action, index: actions.endIndex - 1)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAlertView() {
        // Set up background
        view.backgroundColor = UIColor { .black.withAlphaComponent($0.userInterfaceStyle == .dark ? 0.5 : 0.25) }
        
        // Create alert view
        alertView = UIView()
        alertView.backgroundColor = .secondarySystemBackground
        alertView.layer.cornerRadius = 14
        alertView.layer.masksToBounds = true
        alertView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(alertView)
        
        NSLayoutConstraint.activate([
            alertView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alertView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            alertView.widthAnchor.constraint(equalToConstant: 270),
        ])
        
        // Set up main stack view
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 0
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        alertView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: alertView.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: alertView.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: alertView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: alertView.trailingAnchor),
        ])
        
        // Set up content stack view
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 6
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 22, leading: 24, bottom: 22, trailing: 24)
        contentStackView.isLayoutMarginsRelativeArrangement = true
        mainStackView.addArrangedSubview(contentStackView)
        
        // Add title if present
        if let title = alertTitle, !title.isEmpty {
            let titleLabel = UILabel()
            titleLabel.attributedText = title.toHKAttributedString
            titleLabel.font = .preferredFont(forTextStyle: .headline)
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            contentStackView.addArrangedSubview(titleLabel)
        }
        
        // Add message if present
        if let message = message, !message.isEmpty {
            let messageLabel = UILabel()
            messageLabel.attributedText = message.toHKAttributedString
            messageLabel.font = .preferredFont(forTextStyle: .footnote)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            contentStackView.addArrangedSubview(messageLabel)
        }
        
        // Add separator
        let separatorView = UIView()
        separatorView.backgroundColor = .separator
        separatorView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        mainStackView.addArrangedSubview(separatorView)
        
        // Add buttons container
        buttonsContainerView = UIStackView()
        buttonsContainerView.axis = .horizontal
        buttonsContainerView.spacing = 0
        mainStackView.addArrangedSubview(buttonsContainerView)
        
        // Add existing actions
        for (index, action) in actions.enumerated() {
            addActionButton(for: action, index: index)
            if index != actions.endIndex - 1 {
                let separatorView = UIView()
                separatorView.backgroundColor = .separator
                separatorView.widthAnchor.constraint(equalToConstant: 0.5).isActive = true
                buttonsContainerView.addArrangedSubview(separatorView)
            }
        }
    }
    
    private func addActionButton(for action: AlertAction, index: Int) {
        let button = createButton(for: action, index: index)
        buttonsContainerView.addArrangedSubview(button)
        if buttonsContainerView.arrangedSubviews.count > 1 {
            buttonsContainerView.arrangedSubviews[0].widthAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        }
    }
    
    private func createButton(for action: AlertAction, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setAttributedTitle(action.title?.toHKAttributedString, for: .normal)
        
        if #available(iOSApplicationExtension 15.0, *) {
            button.configuration = .plain()
            button.configuration?.baseForegroundColor = action.style == .destructive ? .systemRed : .systemBlue
            button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24)
            button.configurationUpdateHandler = { button in
                button.backgroundColor = button.isHighlighted ? .systemGray4 : .clear
            }
            button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: UIFont.buttonFontSize, weight: self.preferredAction == action || action.style == .cancel ? .semibold : .regular)
                return outgoing
            }
        } else {
            button.setTitleColor(action.style == .destructive ? .systemRed : .systemBlue, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
            button.titleLabel?.font = .systemFont(ofSize: UIFont.buttonFontSize, weight: preferredAction == action || action.style == .cancel ? .semibold : .regular)
        }
        
        // Add action handler
        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        button.tag = index  // Use tag to identify the action
        
        return button
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        guard sender.tag < actions.count else { return }
        let action = actions[sender.tag]
        dismiss(animated: true) {
            action.handler?(action)
        }
    }
}

// MARK: - AlertAction

class AlertAction: NSObject {
    /// The title of the action's button.
    let title: String?
    
    /// The style that is applied to the action's button.
    let style: Style
    
    /// A block to execute when the user selects the action.
    let handler: ((AlertAction) -> Void)?
    
    /// Constants indicating the available styles for action buttons in an alert.
    enum Style {
        case `default`
        case cancel
        case destructive
    }
    
    /// Creates and returns an action with the specified title, style, and handler.
    init(title: String?, style: Style, handler: ((AlertAction) -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}
