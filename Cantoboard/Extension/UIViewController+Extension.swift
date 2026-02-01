//
//  UIViewController+Extension.swift
//  Cantoboard
//
//  Created by Cantoboard on 2026/01/31.
//

import UIKit

extension UIViewController {
    /// Configure navigation bar with Hong Kong text attributes
    func configureNavigationBarWithHKAttributes() {
        navigationController?.navigationBar.largeTitleTextAttributes = String.HKAttribute
        navigationController?.navigationBar.titleTextAttributes = String.HKAttribute
    }
    
    /// Create and configure a full-screen table view with standard constraints
    func createFullScreenTableView(style: UITableView.Style = .grouped, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) -> UITableView {
        let tableView = UITableView(frame: view.frame, style: style)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = delegate
        tableView.dataSource = dataSource
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        return tableView
    }
}
