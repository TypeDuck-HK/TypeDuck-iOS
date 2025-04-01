//
//  UIApplication+Extension.swift
//  Cantoboard
//
//  Created by Alex Man on 29/3/25.
//

import UIKit

extension UIApplication {
    @objc func openURL_backport(_ url: URL) async -> Bool {
        await open(url)
    }
}
