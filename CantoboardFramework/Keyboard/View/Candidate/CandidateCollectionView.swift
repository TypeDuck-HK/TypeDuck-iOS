//
//  CandidateCollectionView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/25/21.
//

import Foundation
import UIKit

protocol CandidateCollectionViewDelegate: UICollectionViewDelegate {
    var mode: CandidatePaneView.Mode { get }
    func selectItem(_ collectionView: UICollectionView, at indexPath: IndexPath)
    func showDictionary(_ collectionView: UICollectionView, at indexPath: IndexPath)
    func longPressItem(_ collectionView: UICollectionView, at indexPath: IndexPath)
}

// This is the UICollectionView inside CandidatePaneView.
class CandidateCollectionView: UICollectionView {
    private let c = InstanceCounter<CandidateCollectionView>()
    
    private static let longPressDelay: Double = 1
    private static let swipeYThreshold: CGFloat = 200 / 3
    
    private var beginPoint: CGPoint?
    
    var scrollOnLayoutSubviews: (() -> Bool)?
    
    private var longPressTimer: Timer?
    private weak var cancelTouch: UITouch?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let candidatePaneView = superview as? CandidatePaneView {
            candidatePaneView.canExpand = contentSize.width > bounds.width
        }
        
        if scrollOnLayoutSubviews?() ?? false {
            scrollOnLayoutSubviews = nil
        }
    }
    
    @objc private func onLongPress(touch: UITouch) {
        let point = touch.location(in: self)
        if let indexPath = indexPathForItem(at: point),
           indexPath.section > 0,
           let cell = cellForItem(at: indexPath) as? CandidateCell,
           cell.isSelected,
           cell.frame.contains(point) {
            cell.isSelected = false
            self.beginPoint = nil
            if let delegate = delegate as? CandidateCollectionViewDelegate {
                delegate.longPressItem(self, at: indexPath)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        longPressTimer?.invalidate()
        
        guard let touch = touches.first else { return }
        beginPoint = touch.location(in: self)
        
        if let indexPath = indexPathForItem(at: beginPoint!),
           indexPath.section > 0,
           let cell = cellForItem(at: indexPath) as? CandidateCell {
            if cell.frame.contains(beginPoint!) {
                cell.isSelected = true
                longPressTimer = Timer.scheduledTimer(withTimeInterval: Self.longPressDelay, repeats: false) { [weak self] timer in
                    guard let self = self, self.longPressTimer == timer else { return }
                    self.onLongPress(touch: touch)
                    self.longPressTimer = nil
                    self.cancelTouch = touch
                }
            } else if let delegate = delegate as? CandidateCollectionViewDelegate,
                      delegate.mode == .table,
                      cell.info?.isDictionaryEntry ?? false,
                      cell.infoImageFrame.contains(beginPoint!) {
                cell.infoIsHighlighted = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        if let delegate = delegate as? CandidateCollectionViewDelegate,
           let beginPoint = beginPoint,
           let indexPath = indexPathForItem(at: beginPoint),
           indexPath.section > 0,
           let cell = cellForItem(at: indexPath) as? CandidateCell,
           let touch = touches.first {
            let point = touch.location(in: self)
            if delegate.mode == .row {
                if point.y - beginPoint.y > Self.swipeYThreshold {
                    cell.isSelected = false
                    cell.infoIsHighlighted = false
                    delegate.showDictionary(self, at: indexPath)
                    self.longPressTimer?.invalidate()
                    self.longPressTimer = nil
                    self.beginPoint = nil
                    self.cancelTouch = touch
                } else {
                    let frame = cell.frame
                    if point.x < frame.minX || point.x > frame.maxX || point.y < frame.minY {
                        cell.isSelected = false
                        cell.infoIsHighlighted = false
                        self.longPressTimer?.invalidate()
                        self.longPressTimer = nil
                        self.beginPoint = nil
                    } else if point.y > frame.maxY {
                        cell.infoIsHighlighted = true
                        self.longPressTimer?.invalidate()
                        self.longPressTimer = nil
                    } else {
                        cell.infoIsHighlighted = false
                    }
                }
            } else {
                if !cell.frame.contains(point) {
                    cell.isSelected = false
                }
                if cell.info?.isDictionaryEntry ?? false,
                   !cell.infoImageFrame.contains(point) {
                    cell.infoIsHighlighted = false
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        var touches = touches
        if let cancelTouch = cancelTouch {
            touches.remove(cancelTouch)
        }
        super.touchesEnded(touches, with: event)
        
        if let delegate = delegate as? CandidateCollectionViewDelegate,
           let beginPoint = beginPoint,
           let indexPath = indexPathForItem(at: beginPoint),
           indexPath.section > 0,
           let cell = cellForItem(at: indexPath) as? CandidateCell,
           let touch = touches.first {
            let point = touch.location(in: self)
            if cell.isSelected {
                cell.isSelected = false
                cell.infoIsHighlighted = false
                if cell.frame.contains(point) {
                    delegate.selectItem(self, at: indexPath)
                }
            } else if cell.infoIsHighlighted {
                cell.infoIsHighlighted = false
                if delegate.mode == .table,
                   cell.info?.isDictionaryEntry ?? false,
                   cell.infoImageFrame.contains(point) {
                    delegate.showDictionary(self, at: indexPath)
                }
            }
        }
        
        longPressTimer?.invalidate()
        longPressTimer = nil
        beginPoint = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        if let beginPoint = beginPoint,
           let indexPath = indexPathForItem(at: beginPoint),
           indexPath.section > 0,
           let cell = cellForItem(at: indexPath) as? CandidateCell {
            cell.isSelected = false
            cell.infoIsHighlighted = false
        }
        
        longPressTimer?.invalidate()
        longPressTimer = nil
        beginPoint = nil
    }
    
    func reloadCandidates() {
        reloadData()
        
        guard numberOfSections > 1 else { return }
        
        let visibleCellCounts = min(indexPathsForVisibleItems.count, dataSource?.collectionView(self, numberOfItemsInSection: 1) ?? 0)
        // For some reason, sometimes willDisplayCell isn't called for the first few visible cells.
        // Manually refreshing them to workaround the bug.
        reloadItems(at: (0..<visibleCellCounts).map({ [1, $0] }))
    }
}
