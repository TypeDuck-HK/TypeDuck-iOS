//
//  MainViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import UIKit
import CantoboardFramework

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {
    var tableView: UITableView!
    var settings: Settings {
        get { Settings.cached }
        set {
            Settings.save(newValue)
            
            if let inputCell = self.tableView.cellForRow(at: [2, 0]) as? InputTableViewCell {
                inputCell.hideKeyboard()
            }
        }
    }
    var sections: [Section] = Settings.buildSections()
    var aboutCells: [(title: String, image: UIImage, action: () -> ())]!
    
    static let languageNames: [Language: String] = [
        .eng: LocalizedStrings.displayLanguages_eng,
        .hin: LocalizedStrings.displayLanguages_hin,
        .ind: LocalizedStrings.displayLanguages_ind,
        .nep: LocalizedStrings.displayLanguages_nep,
        .urd: LocalizedStrings.displayLanguages_urd,
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "TypeDuck"
        navigationController?.navigationBar.largeTitleTextAttributes = String.HKAttribute
        navigationController?.navigationBar.titleTextAttributes = String.HKAttribute
        tableView = UITableView(frame: view.frame, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        aboutCells = [
            (LocalizedStrings.other_onboarding, CellImage.onboarding, {
                let onboarding = UINavigationController(rootViewController: OnboardingViewController())
                onboarding.modalPresentationStyle = .fullScreen
                onboarding.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                onboarding.navigationBar.shadowImage = UIImage()
                onboarding.navigationBar.isTranslucent = true
                self.present(onboarding, animated: true, completion: nil)
            }),
            // (LocalizedStrings.other_faq, CellImage.faq, { self.navigationController?.pushViewController(FaqViewController(), animated: true) }),
            (LocalizedStrings.other_about, CellImage.about, { self.navigationController?.pushViewController(AboutViewController(), animated: true) }),
        ]
        
        tableView.allowsSelectionDuringEditing = true
        tableView.setEditing(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "init") {
            aboutCells[0].action()
        }
    }
    
    @objc func appMovedToBackground() {
        settings = Settings.reload()
        sections = Settings.buildSections()
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { Keyboard.isEnabled ? sections.count + 5 : 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return aboutCells.count
        case 2: return 1
        case 3: return settings.languageState.selected.count
        case 4: return settings.languageState.deselected.count
        default:
            let sectionId = section - 5
            guard 0 <= sectionId && sectionId < sections.count else { return 0 }
            return sections[sectionId].options.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return LocalizedStrings.installTypeDuck
        case 1: return nil
        case 2: return LocalizedStrings.testKeyboard
        case 3: return LocalizedStrings.displayLanguages
        case 4: return settings.languageState.deselected.isEmpty ? nil : LocalizedStrings.moreLanguages
        default: return sections[section - 5].header
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            var installTypeDuck_description = LocalizedStrings.installTypeDuck_description
            if #available(iOS 15, *) {
                installTypeDuck_description = LocalizedStrings.installTypeDuck_ios15_description + installTypeDuck_description
            }
            return installTypeDuck_description
        case 3: return LocalizedStrings.displayLanguages_description
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return UITableViewCell(tintedTitle: LocalizedStrings.installTypeDuck_settings, image: CellImage.settings)
        case 1: return UITableViewCell(tintedTitle: aboutCells[indexPath.row].title, image: aboutCells[indexPath.row].image)
        case 2: return InputTableViewCell(tableView: tableView)
        case 3: return LanguageTableViewCell(languageName: Self.languageNames[settings.languageState.selected[indexPath.row]]!,
                                             checked: settings.languageState.selected[indexPath.row] == settings.languageState.main,
                                             isEnabled: settings.languageState.selected.count > 1)
        case 4: return LanguageTableViewCell(languageName: Self.languageNames[settings.languageState.deselected[indexPath.row]]!)
        default: return sections[indexPath.section - 5].options[indexPath.row].dequeueCell(with: self)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0: UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        case 1: aboutCells[indexPath.row].action()
        case 2: (tableView.cellForRow(at: indexPath) as? InputTableViewCell)?.showKeyboard()
        case 3:
            if let index = settings.languageState.selected.firstIndex(of: settings.languageState.main) {
                tableView.cellForRow(at: IndexPath(row: index, section: 3))?.editingAccessoryType = .none
            }
            tableView.cellForRow(at: indexPath)?.editingAccessoryType = .checkmark
            settings.languageState.main = settings.languageState.selected[indexPath.row]
            Settings.save(settings)
        case 4: break
        default: showDescription(of: sections[indexPath.section - 5].options[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.attributedText = self.tableView(tableView, titleForHeaderInSection: section)?.toHKAttributedString
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.attributedText = self.tableView(tableView, titleForFooterInSection: section)?.toHKAttributedString
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        // case 3: return settings.languageState.selected.count > 1
        case 3, 4: return true
        default: return false
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch indexPath.section {
        case 3: return .delete
        case 4: return .insert
        default: return .none
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let element = settings.languageState.selected[indexPath.row]
            let index = settings.languageState.delete(at: indexPath.row)
            tableView.cellForRow(at: indexPath)?.selectionStyle = .none
            let newIndexPath = IndexPath(row: index, section: 4)
            tableView.beginUpdates()
            tableView.moveRow(at: indexPath, to: newIndexPath)
            tableView.endUpdates()
            let firstSelectedCell = tableView.cellForRow(at: IndexPath(row: 0, section: 3))
            if settings.languageState.main == element {
                settings.languageState.main = settings.languageState.selected.first!
                tableView.cellForRow(at: newIndexPath)?.editingAccessoryType = .none
                firstSelectedCell?.editingAccessoryType = .checkmark
            }
            Settings.save(settings)
            (firstSelectedCell as? LanguageTableViewCell)?.isEnabled = settings.languageState.selected.count > 1
            tableView.headerView(forSection: 4)?.isHidden = settings.languageState.deselected.isEmpty
        case .insert:
            let index = settings.languageState.insert(at: indexPath.row)
            Settings.save(settings)
            tableView.cellForRow(at: indexPath)?.selectionStyle = .default
            (tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? LanguageTableViewCell)?.isEnabled = settings.languageState.selected.count > 1
            tableView.beginUpdates()
            tableView.moveRow(at: indexPath, to: IndexPath(row: index, section: 3))
            tableView.endUpdates()
            tableView.headerView(forSection: 4)?.isHidden = settings.languageState.deselected.isEmpty
        default: break
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DescriptionPresentationController(presentedViewController: presented, presenting: presentingViewController)
    }
    
    func showDescription(of option: Option) {
        guard option.videoUrl != nil || option.description != nil else { return }
        
        let description = UINavigationController(rootViewController: DescriptionViewController(option: option))
        description.modalPresentationStyle = .custom
        description.transitioningDelegate = self
        present(description, animated: true, completion: nil)
    }
}

class CellImage {
    private static let configuration = UIImage.SymbolConfiguration(pointSize: 20)
    private static let bundle = Bundle(for: CellImage.self)
    private static func imageAssets(_ key: String) -> UIImage {
        UIImage(systemName: key, withConfiguration: configuration) ?? UIImage(named: key, in: bundle, with: configuration)!
    }
    
    static let settings = imageAssets("gearshape")
    static let onboarding = imageAssets("arrow.uturn.right.circle")
    static let faq = imageAssets("questionmark.circle")
    static let about = imageAssets("info.circle")
    static let externalLink = imageAssets("arrow.up.right.circle")
    static let sourceCode = imageAssets("chevron.left.forwardslash.chevron.right")
    static let repository = imageAssets("book.closed")
    static let telegram = imageAssets("paperplane")
    static let email = imageAssets("envelope")
    static let rate = imageAssets("pencil")
}
