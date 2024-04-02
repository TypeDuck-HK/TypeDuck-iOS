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
    static let videoAspectRatio: CGFloat = 390 / 306
    static let stackViewInset = UIEdgeInsets(top: 10, left: 0, bottom: 15, right: 0)
    
    var option: Option!
    var stackView: UIStackView!
    var playerView: UIView?
    var playerLooper: AVPlayerLooper?
    
    convenience init(option: Option) {
        self.init()
        self.option = option
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissDescription))
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
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
            titleView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 40),
        ])
        
        if let videoUrl = option.videoUrl {
            let videoUrl = Bundle.main.url(forResource: "Guide/" + videoUrl, withExtension: "mp4")!
            
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
        
        let label = UILabel()
        label.attributedText = option.description?.toHKAttributedString
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        stackView = UIStackView(arrangedSubviews: [titleView, playerView, label].compactMap { $0 })
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20
        stackView.setCustomSpacing(10, after: titleView)
        view.addSubview(stackView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -15),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: -36),
            titleView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            label.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
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
                playerView.heightAnchor.constraint(lessThanOrEqualToConstant: 400),
            ])
        }
    }
    
    @objc func dismissDescription() {
        dismiss(animated: true, completion: nil)
    }
}
