//
//  HLSLooperViewController.swift
//  HLSPlayer
//
//  Created by soaurabh on 18/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit
import AVFoundation

class HLSLooperViewController: UIViewController {
    let playlistURLs: [URL]
    @IBOutlet private weak var playerView: HLSPlayerView!{
        didSet {
            playerView.player = player
            playerView.videoFillMode = .resizeAspectFill
        }
    }
    @objc private let player = AVQueuePlayer()
    private var observer: NSKeyValueObservation?
    
    init(playlistURLs: [URL]) {
        self.playlistURLs = playlistURLs
        
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
        //Set up the player
        initializePlayer()
        addGestureRecognizers()
    }
    
    
    // Set up player
    private func initializePlayer() {        
        addAllVideosToPlayer()
        
        player.volume = 0.0
        player.play()
        
        observer = player.observe(\.currentItem) { [weak self] player, _ in
            if player.items().count == 1 {
                self?.addAllVideosToPlayer()
            }
        }
    }
    
    // Create player items from playlistURLs and insert them into the player's list
    private func addAllVideosToPlayer() {
        for playlistURL in playlistURLs {
            let asset = AVURLAsset(url: playlistURL)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: nil) //preloading master playlist
            let item = AVPlayerItem(asset: asset)
            player.insert(item, after: player.items().last)
        }
    }
    
    // Add methods to pause and play
    func pause() {
        player.pause()
    }
    
    func play() {
        player.play()
    }
    
    // MARK:- Gestures
    
    // Add single and double tap gestures to the video looper
    func addGestureRecognizers() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(wasTapped))
        let doubleTap = UITapGestureRecognizer(target: self,
                                               action: #selector(wasDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        tap.require(toFail: doubleTap)
        
        self.view.addGestureRecognizer(tap)
        self.view.addGestureRecognizer(doubleTap)
    }
    
    //Single tapping should toggle the volume
    @objc func wasTapped() {
        player.volume = player.volume == 1.0 ? 0.0 : 1.0
    }
    
    // Double tapping should toggle the rate between 8x and 1x
    @objc func wasDoubleTapped() {
        player.rate = player.rate == 1.0 ? 2.0 : 1.0
    }

    // MARK - Unnecessary Code
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        observer?.invalidate()
    }
}
