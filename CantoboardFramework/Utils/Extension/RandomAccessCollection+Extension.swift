//
//  RandomAccessCollection+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 19/4/23.
//

import Foundation

extension RandomAccessCollection where Element: Comparable {
    func binarySearch(element: Element) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
            if self[mid] < element {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}
