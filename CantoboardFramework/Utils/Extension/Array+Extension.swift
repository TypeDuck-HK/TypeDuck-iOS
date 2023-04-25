//
//  Array+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/7/21.
//

import Foundation

extension Array {
    func mapToSet<T: Hashable>(_ transform: (Element) -> T) -> Set<T> {
        var result = Set<T>()
        for item in self {
            result.insert(transform(item))
        }
        return result
    }
    
    subscript<T>(safe index: Index) -> T? where Element == T? {
        get { indices ~= index ? self[index] : nil }
        set {
            while !(indices ~= index) {
                self.append(nil)
            }
            self[index] = newValue
        }
    }
    
    subscript<T>(weak index: Index) -> T? where Element == Weak<T> {
        get { indices ~= index ? self[index].ref : nil }
        set {
            while !(indices ~= index) {
                self.append(Weak())
            }
            self[index].ref = newValue
        }
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
