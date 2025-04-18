//
//  UIColor+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation
import UIKit

extension UIColor {
    var alpha: CGFloat {
        var a: CGFloat = 1
        return getWhite(nil, alpha: &a) ? a : 1
    }
    
    static var clearInteractable: UIColor {
        UIColor(white: 1, alpha: 0.005)
    }
    
    // Backport of NSColor.blended: https://developer.apple.com/documentation/appkit/nscolor/blended(withfraction:of:)
    func blended(withFraction fraction: CGFloat, of color: UIColor) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(
            red: r1 * (1 - fraction) + r2 * fraction,
            green: g1 * (1 - fraction) + g2 * fraction,
            blue: b1 * (1 - fraction) + b2 * fraction,
            alpha: a1 * (1 - fraction) + a2 * fraction
        )
    }
}

// Make UIColor Codable, keeping the data size tiny by storing only RGBA components: https://stackoverflow.com/a/71927562
extension Decodable where Self: UIColor {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let components = try container.decode([CGFloat].self)
        self = Self.init(red: components[0], green: components[1], blue: components[2], alpha: components[3])
    }
}

extension Encodable where Self: UIColor {
    public func encode(to encoder: Encoder) throws {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        var container = encoder.singleValueContainer()
        try container.encode([r, g, b, a])
    }
}

extension UIColor: Codable {}

// Determine the foreground text color (white/black) from a background color: https://zenn.dev/mryhryki/articles/2020-11-12-hatena-background-color
extension UIColor {
    private static func getRGBForCalculatingLuminance(_ component: CGFloat) -> CGFloat {
        component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }

    private var relativeLuminance: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: nil)
        let R = Self.getRGBForCalculatingLuminance(r)
        let G = Self.getRGBForCalculatingLuminance(g)
        let B = Self.getRGBForCalculatingLuminance(b)
        return 0.2126 * R + 0.7152 * G + 0.0722 * B
    }

    private func getContrastRatio(to other: UIColor) -> CGFloat {
        let selfLuminance = relativeLuminance
        let otherLuminance = other.relativeLuminance
        let bright = max(selfLuminance, otherLuminance)
        let dark = min(selfLuminance, otherLuminance)
        return (bright + 0.05) / (dark + 0.05)
    }

    var fgColor: UIColor {
        getContrastRatio(to: .black) < getContrastRatio(to: .white) ? .white : .black
    }
}
