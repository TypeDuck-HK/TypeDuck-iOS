//
//  AboutTableViewCell.swift
//  Cantoboard
//
//  Created by Alex Man on 22/12/23.
//

import UIKit

class AboutTableViewCell: UITableViewCell, UITextViewDelegate {
    static let emailQuery = [
        URLQueryItem(name: "subject", value: "TypeDuck Enquiry / Issue Report | 打得粵語輸入法查詢／問題匯報"),
        URLQueryItem(name: "body", value: """
        
        
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        iOS Version: \(UIDevice.current.systemVersion)
        """)
    ]
    
    convenience init(tableView: UITableView) {
        self.init()
        
        let description = LocalizedStrings.about_description
        let attributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key(kCTLanguageAttributeName as String): "zh-HK",
            .font: UIFont.preferredFont(forTextStyle: .body)
        ]
        let attributedString = NSMutableAttributedString(string: description, attributes: attributes)
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            for match in detector.matches(in: description, range: NSRange(description.startIndex..<description.endIndex, in: description)) {
                guard var url = match.url, url.scheme == "mailto" else { continue }
                if #available(iOS 16.0, *) {
                    url.append(queryItems: Self.emailQuery)
                } else {
                    guard var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: true) else { continue }
                    urlComponent.queryItems = (urlComponent.queryItems ?? []) + Self.emailQuery
                    guard let newUrl = urlComponent.url else { continue }
                    url = newUrl
                }
                var attributesWithURL = attributes
                attributesWithURL[.link] = url
                attributedString.setAttributes(attributesWithURL, range: match.range)
            }
        }
        
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.attributedText = attributedString
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.delegate = self
        addSubview(textView)
        
        let image = UIImage(named: "CreditLogos")!
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white // Unfortunately the credit logos must have white background
        addSubview(imageView)
        
        let stackView = UIStackView(arrangedSubviews: [textView, imageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 12
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: image.size.width / image.size.height),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 400), // image.size.height * image.scale
        ])
        
        selectionStyle = .none
        // overrideUserInterfaceStyle = .light
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.delegate = nil
        textView.selectedTextRange = nil
        textView.delegate = self
    }
}
