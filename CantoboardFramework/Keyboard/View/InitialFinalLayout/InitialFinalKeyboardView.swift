//
//  InitialFinalKeyboardView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 19/2/25.
//

import Foundation
import UIKit

class InitialFinalKeyboardView: UIView, BaseKeyboardView {
    weak var delegate: KeyboardViewDelegate?
    
    enum LayoutSide {
        case left, right
    }
    
    enum KeyCapType {
        case initial, final, tone, punctuation
    }
    
    private let leftButtonLayout: [[String?]] = [
        ["b", "p", "m", "f"],
        ["d", "t", "n", "l"],
        ["z", "c", "s", "j"],
        ["g", "k", "N", "h"],
        ["G", "K", "w", "X"],
        ["。", "，", "？", "！"],
    ]
    
    private let rightButtonLayout: [[String?]] = [
        ["aa", "aai", "aau", "aam", "aan", "aang", "aap", "aat", "aak", "m"],
        [nil, "ai", "au", "am", "an", "ang", "ap", "at", "ak", "ng"],
        ["e", "ei", "eu", "em", nil, "eng", "ep", nil, "ek", "1"],
        ["i", nil, "iu", "im", "in", "ing", "ip", "it", "ik", "2"],
        ["o", "oi", "ou", nil, "on", "ong", nil, "ot", "ok", "3"],
        ["u", "ui", nil, nil, "un", "ung", nil, "ut", "uk", "4"],
        ["oe", "eoi", nil, nil, "eon", "oeng", nil, "eot", "oek", "5"],
        ["yu", nil, nil, nil, "yun", nil, nil, "yut", nil, "6"],
    ]
    
    private let bottomButtonLayout: [[KeyCap]] = [[.nextKeyboard, .toggleInputMode(.english, nil), .keyboardType(.numeric), .keyboardType(.emojis)], [.space(.space)], [.backspace, .returnKey(.default), .dismissKeyboard]]
    
    private weak var candidatePaneView: CandidatePaneView?
    public var layoutConstants: Reference<LayoutConstants> = Reference(LayoutConstants.forMainScreen)
    
    private var viewDidSetup = false
    private var touchHandler: TouchHandler?
    private var leftButtons: [[KeypadButton?]] = []
    private var rightButtons: [[KeypadButton?]] = []
    private var bottomKeyRow: KeyRowView?
    
    private weak var newLineKey: KeyView?
    private weak var spaceKey: KeyView?
    
    public var candidateOrganizer: CandidateOrganizer? {
        didSet {
            candidatePaneView?.candidateOrganizer = candidateOrganizer
        }
    }
    
    private var _state: KeyboardState
    var state: KeyboardState {
        get { _state }
        set { changeState(prevState: _state, newState: newValue) }
    }
    
    init(state: KeyboardState) {
        self._state = state
        super.init(frame: .zero)
        
        backgroundColor = .clearInteractable
        insetsLayoutMarginsFromSafeArea = false
        isMultipleTouchEnabled = true
        preservesSuperviewLayoutMargins = false
        
        initView()
    }
    
    override func didMoveToSuperview() {
        if superview == nil {
            touchHandler = nil
        } else {
            let touchHandler = TouchHandler(keyboardView: self, keyboardIdiom: state.keyboardIdiom)
            touchHandler.isInKeyboardMode = state.activeSchema != .jyutpingInitialFinal
            touchHandler.allowCaretMoving = state.activeSchema != .jyutpingInitialFinal // TODO FIXME
            self.touchHandler = touchHandler
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    private func initView() {
        let candidatePaneView = CandidatePaneView(keyboardState: state, layoutConstants: layoutConstants)
        candidatePaneView.candidateOrganizer = candidateOrganizer
        candidatePaneView.delegate = self
        addSubview(candidatePaneView)
        candidatePaneView.setupButtons()

        self.candidatePaneView = candidatePaneView
        
        if state.isKeyboardAppearing {
            setupView()
        }
    }
    
    private func initLeftRightButtons(side: LayoutSide, buttonLayouts: [[String?]], existingButtons: [[KeypadButton?]]) -> [[KeypadButton?]] {
        var existingButtons = existingButtons.flatMap { $0.compactMap { $0 } }
        var buttons: [[KeypadButton?]] = []
        var x: CGFloat = 0, y: CGFloat = 0
        
        for row in buttonLayouts {
            var buttonRow: [KeypadButton?] = []
            for c in row {
                guard let c = c else {
                    buttonRow.append(nil)
                    x += 1
                    continue
                }
                
                let button: KeypadButton
                if !existingButtons.isEmpty {
                    button = existingButtons.removeFirst()
                } else {
                    button = KeypadButton(layoutConstants: layoutConstants)
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                    addSubview(button)
                }
                
                let keyCapType: KeyCapType
                switch side {
                case .left where c.first!.isEnglishLetter: keyCapType = .initial
                case .left: keyCapType = .punctuation
                case .right where c.first!.isDigit: keyCapType = .tone
                case .right: keyCapType = .final
                }
                
                button.colRowOrigin = CGPoint(x: x, y: y)
                button.setKeyCap(.jyutPingInitialFinal(keyCapType, c), keyboardState: state)
                button.isKeyEnabled = state.enableState == .enabled
                buttonRow.append(button)
                x += 1
            }
            buttons.append(buttonRow)
            y += 1
        }
        existingButtons.forEach { $0.removeFromSuperview() }
        return buttons
    }
    
    private func setupView() {
        touchHandler?.isInKeyboardMode = state.activeSchema != .jyutpingInitialFinal
        touchHandler?.allowCaretMoving = state.activeSchema != .jyutpingInitialFinal // TODO FIXME
        
        leftButtons = initLeftRightButtons(side: .left, buttonLayouts: leftButtonLayout, existingButtons: leftButtons)
        rightButtons = initLeftRightButtons(side: .right, buttonLayouts: rightButtonLayout, existingButtons: rightButtons)
        
        bottomKeyRow?.removeFromSuperview()
        let bottomKeyRow = KeyRowView(layoutConstants: layoutConstants)
        addSubview(bottomKeyRow)
        self.bottomKeyRow = bottomKeyRow
        
        refreshKeys()
        viewDidSetup = true
    }
    
    private func refreshKeys() {
        var keyCaps = bottomButtonLayout
        configureLowerLeftSystemKeyCap(&keyCaps)
        bottomKeyRow?.setupRow(keyboardState: state, keyCaps, rowId: layoutConstants.ref.idiom.keyboardViewLayout.numOfRows - 1)
        refreshSpaceAndReturnKeys()
    }
    
    private func configureLowerLeftSystemKeyCap(_ keyCaps: inout [[KeyCap]]) {
        if layoutConstants.ref.idiom == .phone || Settings.cached.padLeftSysKeyAsKeyboardType {
            if let keyboardTypeKeyCapIndex = keyCaps[0].firstIndex(where: { $0.isKeyboardType }) {
                // Move keyboard type key cap to the left corner.
                keyCaps[0].insert(keyCaps[0].remove(at: keyboardTypeKeyCapIndex), at: 0)
            }
        }
        
        keyCaps[0] = keyCaps[0].compactMap { keyCap in
            switch keyCap {
            case .nextKeyboard where layoutConstants.ref.idiom == .phone && !state.needsInputModeSwitchKey: return nil
            case .toggleInputMode where !Settings.cached.showBottomLeftSwitchLangButton: return nil
            case .keyboardType(.numeric) where layoutConstants.ref.idiom.isPadFull: return .keyboardType(.numSymbolic)
            case .keyboardType(.emojis) where layoutConstants.ref.idiom == .phone && state.needsInputModeSwitchKey: return nil
            default: return keyCap
            }
        }
    }
    
    private func refreshSpaceAndReturnKeys() {
        if let lastRowRightKeys = bottomKeyRow?.rightKeys,
           let newLineKey = lastRowRightKeys[safe: lastRowRightKeys.count - 2],
           case .returnKey = newLineKey.keyCap {
            self.newLineKey = newLineKey
            newLineKey.setKeyCap(.returnKey(state.returnKeyType), keyboardState: state)
        }
        
        if let lastRowMiddleKeys = bottomKeyRow?.middleKeys,
           let spaceKey = lastRowMiddleKeys[safe: 0],
           case .space = spaceKey.keyCap {
            self.spaceKey = spaceKey
            spaceKey.setKeyCap(.space(state.spaceKeyMode), keyboardState: state)
        }
    }
    
    override func layoutSubviews() {
        let layoutConstants = layoutConstants.ref
        
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: layoutConstants.keyboardViewInsets.top,
                                                           leading: layoutConstants.keyboardViewInsets.left,
                                                           bottom: layoutConstants.keyboardViewInsets.bottom,
                                                           trailing: layoutConstants.keyboardViewInsets.right)
        
        super.layoutSubviews()
        
        layoutCandidateSubviews(layoutConstants)
        
        guard viewDidSetup, let candidatePaneView = candidatePaneView else { return }
        
        let leftButtonsMaxRowCount = CGFloat((leftButtons.max { a, b in a.count < b.count })!.count)
        let rightButtonsMaxRowCount = CGFloat((rightButtons.max { a, b in a.count < b.count })!.count)
        let totalMaxRowCount = leftButtonsMaxRowCount + rightButtonsMaxRowCount
        let availableWidth = bounds.width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing
        let totalAvailableButtonWidth = availableWidth - layoutConstants.initialFinalLayoutButtonGroupGap - layoutConstants.initialFinalLayoutButtonGap * (totalMaxRowCount - 2)
        let minButtonWidth = totalAvailableButtonWidth / totalMaxRowCount
        
        let leftButtonsAvailableWidth = minButtonWidth * leftButtonsMaxRowCount + layoutConstants.initialFinalLayoutButtonGap * (leftButtonsMaxRowCount - 1)
        let rightButtonsAvailableWidth = minButtonWidth * rightButtonsMaxRowCount + layoutConstants.initialFinalLayoutButtonGap * (rightButtonsMaxRowCount - 1)
        
        let initialY = LayoutConstants.keyboardViewTopInset + candidatePaneView.rowHeight
        let availableHeight = bounds.height - directionalLayoutMargins.top - directionalLayoutMargins.bottom - candidatePaneView.rowHeight - layoutConstants.keyHeight - layoutConstants.initialFinalLayoutButtonGroupGap
        
        layoutButtons(leftButtons,
                      initialX: layoutConstants.keyboardViewInsets.left,
                      availableWidth: leftButtonsAvailableWidth,
                      initialY: initialY,
                      availableHeight: availableHeight,
                      layoutConstants: layoutConstants)
        layoutButtons(rightButtons,
                      initialX: layoutConstants.keyboardViewInsets.left + leftButtonsAvailableWidth + layoutConstants.initialFinalLayoutButtonGroupGap,
                      availableWidth: rightButtonsAvailableWidth,
                      initialY: initialY,
                      availableHeight: availableHeight,
                      layoutConstants: layoutConstants)
        
        let keyRowMargin = NSDirectionalEdgeInsets(top: layoutConstants.initialFinalLayoutButtonGroupGap, leading: 0, bottom: directionalLayoutMargins.bottom, trailing: 0) // leading: directionalLayoutMargins.leading, trailing: leading: directionalLayoutMargins.trailing
        let keyRowHeight = keyRowMargin.top + layoutConstants.keyHeight + keyRowMargin.bottom
        bottomKeyRow?.frame = CGRect(x: 0, y: bounds.height - keyRowHeight, width: frame.width, height: keyRowHeight)
        bottomKeyRow?.directionalLayoutMargins = keyRowMargin
    }
    
    private func layoutButtons(_ buttons: [[KeypadButton?]], initialX: CGFloat, availableWidth: CGFloat, initialY: CGFloat, availableHeight: CGFloat, layoutConstants: LayoutConstants) {
        let numOfRows = CGFloat(buttons.count)
        let unitHeight = (availableHeight - layoutConstants.initialFinalLayoutButtonGap * (numOfRows - 1)) / numOfRows
        var x = initialX, y = initialY
        
        for row in buttons {
            let numOfButtonsInRow = CGFloat(row.count)
            let unitWidth = (availableWidth - layoutConstants.initialFinalLayoutButtonGap * (numOfButtonsInRow - 1)) / numOfButtonsInRow
            let buttonSize = CGSize(width: unitWidth, height: unitHeight)
            x = initialX
            for button in row {
                let origin = CGPoint(x: x, y: y)
                button?.frame = CGRect(origin: origin, size: buttonSize)
                x += buttonSize.width + layoutConstants.initialFinalLayoutButtonGap
            }
            y += unitHeight + layoutConstants.initialFinalLayoutButtonGap
        }
    }
    
    private func changeState(prevState: KeyboardState, newState: KeyboardState) {
        let isViewDirty = prevState.keyboardContextualType != newState.keyboardContextualType ||
            prevState.isKeyboardAppearing != newState.isKeyboardAppearing ||
            prevState.keyboardType != newState.keyboardType ||
            prevState.activeSchema != newState.activeSchema ||
            prevState.enableState != newState.enableState ||
            prevState.isComposing != newState.isComposing ||
            prevState.keyboardIdiom != newState.keyboardIdiom ||
            prevState.isPortrait != newState.isPortrait ||
            prevState.needsInputModeSwitchKey != newState.needsInputModeSwitchKey
        
        if prevState.returnKeyType != newState.returnKeyType {
            newLineKey?.setKeyCap(.returnKey(newState.returnKeyType), keyboardState: state)
        }
        
        if prevState.spaceKeyMode != newState.spaceKeyMode {
            spaceKey?.setKeyCap(.space(newState.spaceKeyMode), keyboardState: state)
        }
        
        if prevState.enableState != newState.enableState {
            let isButtonEnabled = newState.enableState == .enabled
            setButtonsEnabled(buttons: leftButtons, isButtonEnabled: isButtonEnabled)
            setButtonsEnabled(buttons: rightButtons, isButtonEnabled: isButtonEnabled)
            bottomKeyRow?.isEnabled = isButtonEnabled
        }
        
        if prevState.keyboardIdiom != newState.keyboardIdiom {
            touchHandler?.keyboardIdiom = newState.keyboardIdiom
        }
        
        touchHandler?.isComposing = newState.isComposing
        touchHandler?.hasForceTouchSupport = traitCollection.forceTouchCapability == .available
        
        _state = newState
        if isViewDirty { setupView() }
        
        candidatePaneView?.keyboardState = state
    }
    
    private func setButtonsEnabled(buttons: [[KeypadButton?]], isButtonEnabled: Bool) {
        buttons.forEach({
            $0.forEach({ b in
                b?.isEnabled = isButtonEnabled
            })
        })
    }
    
    private func layoutCandidateSubviews(_ layoutConstants: LayoutConstants) {
        guard let candidatePaneView = candidatePaneView else { return }
        let height = candidatePaneView.mode == .row ? candidatePaneView.rowHeight : bounds.height
        candidatePaneView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0,
                                                                             leading: layoutConstants.keyboardViewInsets.left,
                                                                             bottom: 0,
                                                                             trailing: layoutConstants.keyboardViewInsets.right)
        candidatePaneView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: bounds.width, height: height))
    }
    
    func scrollCandidatePaneToNextPageInRowMode() {
        candidatePaneView?.scrollRightToNextPageInRowMode()
    }
    
    func setPreserveCandidateOffset() {
        candidatePaneView?.setPreserveCandidateOffset()
    }
    
    func changeCandidatePaneMode(_ mode: CandidatePaneView.Mode) {
        candidatePaneView?.changeMode(mode)
    }
}

extension InitialFinalKeyboardView: CandidatePaneViewDelegate {
    func candidatePaneViewCandidateSelected(_ choice: IndexPath) {
        delegate?.handleKey(.selectCandidate(choice))
    }
    
    func candidatePaneViewExpanded() {
        candidatePaneViewToggled()
    }
    
    func candidatePaneViewCollapsed() {
        candidatePaneViewToggled()
    }
    
    private func candidatePaneViewToggled() {
        setNeedsLayout()
        let isButtonHidden = state.keyboardType == .emojis || candidatePaneView?.mode ?? .row == .table
        refreshButtonsVisibility(buttons: leftButtons, isButtonHidden: isButtonHidden)
        refreshButtonsVisibility(buttons: rightButtons, isButtonHidden: isButtonHidden)
        bottomKeyRow?.isHidden = isButtonHidden
    }
    
    private func refreshButtonsVisibility(buttons: [[KeypadButton?]], isButtonHidden: Bool) {
        buttons.forEach({
            $0.forEach({ b in
                b?.isHidden = isButtonHidden
            })
        })
    }
    
    func candidatePaneCandidateLoaded() {
    }
    
    func handleKey(_ action: KeyboardAction) {
        delegate?.handleKey(action)
    }
}

extension InitialFinalKeyboardView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first,
              let keypadButton = touch.view as? KeyView else { return }
        
        touchHandler?.touchBegan(touch, key: keypadButton, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first,
              let keypadButton = touch.view as? KeyView else { return }
        
        touchHandler?.touchMoved(touch, key: keypadButton, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first,
              let keypadButton = touch.view as? KeyView else { return }
        
        touchHandler?.touchEnded(touch, key: keypadButton, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard let touch = touches.first else { return }
        
        touchHandler?.touchCancelled(touch, with: event)
    }
}
