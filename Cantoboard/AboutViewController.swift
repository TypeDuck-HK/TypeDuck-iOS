//
//  AboutViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 23/11/21.
//

import UIKit

class AboutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let sections: [[(image: UIImage, title: String, url: String)]] = [
        [
            (CellImage.externalLink, LocalizedStrings.about_typeduckSite, "https://typeduck.hk"),
            (CellImage.externalLink, LocalizedStrings.about_learnduckSite, "https://learn.typeduck.hk"),
            (CellImage.externalLink, LocalizedStrings.about_jyutpingSite, "https://lshk.org/jyutping-scheme/"),
            (CellImage.sourceCode, LocalizedStrings.about_sourceCode, "https://github.com/TypeDuck-HK/TypeDuck-iOS"),
            (CellImage.sourceCode, LocalizedStrings.about_engine, "https://github.com/TypeDuck-HK/librime"),
            (CellImage.repository, LocalizedStrings.about_schema, "https://github.com/TypeDuck-HK/schema"),
        ],
        [
            (CellImage.sourceCode, "Cantoboard", "https://github.com/CanCLID/Cantoboard"),
            (CellImage.sourceCode, "ISEmojiView", "https://github.com/isaced/ISEmojiView"),
        ],
        /*
        [
            (CellImage.email, LocalizedStrings.about_email, "mailto:info@typeduck.hk"),
            (CellImage.rate, LocalizedStrings.about_appStore, "https://apps.apple.com/us/app/typeduck/id0000000000"),
        ],
        */
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizedStrings.other_about
        configureNavigationBarWithHKAttributes()
        view.backgroundColor = .systemBackground
        _ = createFullScreenTableView(delegate: self, dataSource: self)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { sections.count + 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        default: return sections[section - 1].count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return LocalizedStrings.about_links
        case 2: return LocalizedStrings.about_credit
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return LocalizedStrings.about_schema_description
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.attributedText = self.tableView(tableView, titleForHeaderInSection: section)?.toHKAttributedString
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.attributedText = self.tableView(tableView, titleForFooterInSection: section)?.toHKAttributedString
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return AboutTableViewCell(tableView: tableView)
        default:
            let row = sections[indexPath.section - 1][indexPath.row]
            return UITableViewCell(title: row.title, image: row.image)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section > 0, var url = URL(string: sections[indexPath.section - 1][indexPath.row].url) {
            /*
            if url.scheme == "mailto" {
                if #available(iOS 16.0, *) {
                    url.append(queryItems: AboutTableViewCell.emailQuery)
                } else if var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                    urlComponent.queryItems = (urlComponent.queryItems ?? []) + AboutTableViewCell.emailQuery
                    if let newUrl = urlComponent.url {
                        url = newUrl
                    }
                }
            }
            */
            UIApplication.shared.open(url)
        }
    }
}
