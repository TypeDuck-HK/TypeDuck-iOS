//
//  WrappableStackView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 17/11/23.
//

import Foundation
import UIKit

class WrappableStackView: UIStackView {
    private var gap: CGFloat!
    private var smallGap: CGFloat!
    private var allViews: [UIView]!
    private var smallSpacingViews: Set<UIView>!
    private var lineContainers: [Weak<UIView>] = []
    
    init(spacingX: CGFloat = 0, spacingY: CGFloat = 0, arrangedSubviews: [UIView] = [], smallSpacingX: CGFloat = 0, smallSpacingAfter smallSpacingSubviews: Set<UIView> = []) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        gap = spacingX
        spacing = spacingY
        allViews = arrangedSubviews
        smallGap = smallSpacingX
        smallSpacingViews = smallSpacingSubviews
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let boundsWidth = bounds.width
        var groupedViews: [[UIView]] = []
        var currOffset: CGFloat = 0
        var currLineViews: [UIView] = []
        var lastIndentLabel: UILabel?
        
        for (i, view) in allViews.enumerated() {
            var width = view.intrinsicContentSize.width
            var shouldBreak = false
            if let label = view as? UILabel, label.numberOfLines == 0 {
                label.numberOfLines = 1
                width = view.intrinsicContentSize.width
                label.numberOfLines = 0
                let textWidth = min(boundsWidth / 6 + 50, width)
                shouldBreak = currOffset + textWidth > boundsWidth
                if !shouldBreak, label.numberOfLines(withWidth: boundsWidth - currOffset) > 2 {
                    shouldBreak = width <= boundsWidth
                    if !shouldBreak, i == allViews.endIndex - 1 {
                        lastIndentLabel = label
                        break
                    }
                }
                width = textWidth
            } else {
                shouldBreak = currOffset + width > boundsWidth
            }
            if !currLineViews.isEmpty, shouldBreak {
                currOffset = 0
                groupedViews.append(currLineViews)
                currLineViews = []
            }
            currLineViews.append(view)
            currOffset += width + (smallSpacingViews.contains(view) ? smallGap : gap)
        }
        if !currLineViews.isEmpty {
            groupedViews.append(currLineViews)
        }
        
        for (i, lineViews) in groupedViews.enumerated() {
            if let lineContainer = lineContainers[weak: i] {
                if let lineStack = lineContainer as? SidedStackView {
                    if !lineStack.arrangedSubviews.elementsEqual(lineViews) {
                        for view in lineStack.arrangedSubviews {
                            lineStack.removeArrangedSubview(view)
                        }
                        for view in lineViews {
                            lineStack.addArrangedSubview(view)
                        }
                        for view in smallSpacingViews.intersection(lineViews) {
                            lineStack.setCustomSpacing(smallGap, after: view)
                        }
                    }
                    addIndentLabel(lineStack)
                } else if let overlappedView = lineContainer as? OverlappedView,
                          i != groupedViews.endIndex - 1 || lastIndentLabel == nil {
                    lineContainers[weak: i]?.removeFromSuperview()
                    lineContainers[weak: i] = overlappedView.topView
                    addArrangedSubview(overlappedView.topView)
                }
            } else {
                let lineStack = SidedStackView(spacing: gap, alignment: .firstBaseline, arrangedSubviews: lineViews)
                if !addIndentLabel(lineStack) {
                    addArrangedSubview(lineStack)
                    lineContainers[weak: i] = lineStack
                }
                for view in smallSpacingViews.intersection(lineViews) {
                    lineStack.setCustomSpacing(smallGap, after: view)
                }
            }
            
            @inline(__always)
            @discardableResult
            func addIndentLabel(_ lineStack: UIStackView) -> Bool {
                if i == groupedViews.endIndex - 1, let label = lastIndentLabel {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.firstLineHeadIndent = currOffset
                    label.attributedText = (label.text ?? label.attributedText?.string)?.toHKAttributedString(withParagraphStyle: paragraphStyle)
                    lineStack.removeFromSuperview()
                    let overlappedView = OverlappedView(topView: lineStack, bottomView: label)
                    addArrangedSubview(overlappedView)
                    lineContainers[weak: i] = overlappedView
                    return true
                }
                return false
            }
        }
        if groupedViews.endIndex < lineContainers.endIndex {
            for i in groupedViews.endIndex..<lineContainers.endIndex {
                lineContainers[i].ref?.removeFromSuperview()
                lineContainers[i].ref = nil
            }
            lineContainers.removeLast(lineContainers.endIndex - groupedViews.endIndex)
        }
        
        if lastIndentLabel == nil, let label = allViews.last as? UILabel {
            label.attributedText = (label.text ?? label.attributedText?.string)?.toHKAttributedString
        }
    }
}

class OverlappedView: UIView {
    var topView: UIView!
    var bottomView: UIView!
    
    init(topView: UIView, bottomView: UIView) {
        super.init(frame: .zero)
        topView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomView)
        addSubview(topView)
        self.topView = topView
        self.bottomView = bottomView
        NSLayoutConstraint.activate([
            topView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            topView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: topView.trailingAnchor),
            
            topView.firstBaselineAnchor.constraint(equalTo: bottomView.firstBaselineAnchor),
            bottomView.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            topView.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: topView.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
