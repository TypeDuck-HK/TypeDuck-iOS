//
//  DescriptionViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 23/11/21.
//

import UIKit
import AVFoundation
import AVKit

class DescriptionViewController: UIViewController {
    static let stackViewInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    
    private static let videoAspectRatio: CGFloat = 390 / 306
    private static let titleTrailingInset: CGFloat = 40
    private static let stackSpacing: CGFloat = 20
    private static let videoMaximumHeight: CGFloat = 400
    
    private var option: Option!
    private var stackView: UIStackView!
    private var titleLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var playerView: UIView?
    private var playerLooper: AVPlayerLooper?
    
    convenience init(option: Option) {
        self.init()
        self.option = option
    }
    
    deinit {
        // Clean up player resources
        if let player = (children.first as? AVPlayerViewController)?.player {
            player.pause()
        }
        playerLooper = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissDescription))
        view.backgroundColor = .systemBackground
        
        titleLabel = UILabel()
        titleLabel.attributedText = option.title.toHKAttributedString
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleView = UIView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            titleView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            titleView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: Self.titleTrailingInset),
        ])
        
        if let videoUrlName = option.videoUrl,
           let videoUrl = Bundle.main.url(forResource: "Guide/" + videoUrlName, withExtension: "mp4") {
            
            let playerController = AVPlayerViewController()
            let playerItem = AVPlayerItem(url: videoUrl)
            let player = AVQueuePlayer(playerItem: playerItem)
            player.isMuted = true
            player.rate = 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak player] in
                player?.rate = 1.3
            }
            playerController.player = player
            playerController.showsPlaybackControls = false
            addChild(playerController)
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
            playerView = playerController.view
            playerView?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        descriptionLabel = UILabel()
        descriptionLabel.attributedText = option.description?.toHKAttributedString
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stackView = UIStackView(arrangedSubviews: [titleView, playerView, descriptionLabel].compactMap { $0 })
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Self.stackSpacing
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Self.stackViewInset.top),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Self.stackViewInset.bottom),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Self.stackViewInset.left),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Self.stackViewInset.right),
            
            titleView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
        
        if let playerView = playerView {            
            let leadingConstraint = playerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)
            leadingConstraint.priority = .defaultLow
            
            let trailingConstraint = playerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            trailingConstraint.priority = .defaultLow
            
            NSLayoutConstraint.activate([
                leadingConstraint,
                trailingConstraint,
                playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: Self.videoAspectRatio),
                playerView.heightAnchor.constraint(lessThanOrEqualToConstant: Self.videoMaximumHeight),
            ])
        }
    }
    
    func stackViewHeight(fitting width: CGFloat) -> CGFloat {
        let titleWidth = max(0, width - Self.titleTrailingInset)
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: titleWidth, height: .greatestFiniteMagnitude)).height
        let descriptionHeight = descriptionLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        var height = titleHeight + Self.stackSpacing + descriptionHeight
        
        if playerView != nil {
            height += min(width / Self.videoAspectRatio, Self.videoMaximumHeight) + Self.stackSpacing
        }
        
        return ceil(height)
    }
    
    @objc func dismissDescription() {
        dismiss(animated: true, completion: nil)
    }
}
