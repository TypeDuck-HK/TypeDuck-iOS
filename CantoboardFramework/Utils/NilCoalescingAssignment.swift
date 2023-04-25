//
//  NilCoalescingAssignment.swift
//  CantoboardFramework
//
//  Created by Alex Man on 22/4/23.
//

infix operator ??= : AssignmentPrecedence

func ??=<T>(lhs: inout T?, rhs: @autoclosure () -> T?) {
    if lhs == nil {
        lhs = rhs()
    }
}
