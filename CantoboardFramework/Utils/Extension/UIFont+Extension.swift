//
//  UIFont+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 7/27/23.
//

import UIKit

extension UIFont {
    func multiplyPointSizeBy(scale: CGFloat) -> UIFont {
        self.withSize(self.pointSize * scale)
    }
}
