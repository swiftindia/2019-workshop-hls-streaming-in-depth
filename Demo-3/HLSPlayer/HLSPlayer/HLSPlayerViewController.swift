//
//  HLSPlayerViewController.swift
//  HLSPlayer
//
//  Created by soaurabh on 16/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit
import AVFoundation

class HLSPlayerViewController: UIViewController {
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    private let playerView: HLSPlayerView
    private weak var timer: Timer?
    private var observer: NSKeyValueObservation?
    private let autoHideDuration = 5.0 // controlView autoHide duration
    @IBOutlet private weak var controlView: UIView! //hidden initially
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var videoLoadingIndicator: UIActivityIndicatorView!
    
    init(playerURL: URL) {
        let asset = AVURLAsset(url: playerURL)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer()
        playerView = HLSPlayerView(frame: UIApplication.shared.keyWindowFrame ?? .zero) // init player layer view with correct frame
        playerView.player = player //sets player on the playerLayer
        player.replaceCurrentItem(with: playerItem) //setup audio+video playback
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
        self.observeTimeControlStatus()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        timer?.invalidate()
        observer?.invalidate()
    }
}

//MARK:- Player Play/Pause
extension HLSPlayerViewController {
    @IBAction func togglePlay(_ sender: UIButton) {
        if player.timeControlStatus == .playing {
            self.pause()
        } else if player.timeControlStatus == .paused {
            self.play()
        }
    }
    
    private func syncPlayPauseButtonImages() {
        if player.timeControlStatus == .playing {
            self.playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        } else if player.timeControlStatus == .paused {
            self.playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        }
    }
    
    // Pauses playback of the current item, same as setting rate to 0.0
    func pause() {
        player.pause()
    }
    
    //Begins playback of the current item, same as setting rate to 1.0
    func play() {
        player.play()
    }
}

//MARK:- Observe TimeControlStatus
extension HLSPlayerViewController {
    //Show/Hide videoLoading Indicator based on timeControlStatus
    private func observeTimeControlStatus() {
        observer = player.observe(\.timeControlStatus) { [weak self] player, _ in
            guard let self = self else { return }
            switch player.timeControlStatus {
            case .waitingToPlayAtSpecifiedRate:
                self.videoLoadingIndicator.startAnimating()
                self.playPauseButton.isHidden = true
            case .paused, .playing:
                self.autoHideControlView(after: self.autoHideDuration)
                fallthrough
            @unknown default:
                self.videoLoadingIndicator.stopAnimating()
                self.syncPlayPauseButtonImages()
                self.playPauseButton.isHidden = false
            }
        }
    }
}

//MARK: - Toggle Show/Hide ControlView
extension HLSPlayerViewController {
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Make sure player is paused when the user leaves this screen
        self.pause()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup and add playerView
        playerView.backgroundColor = .black
        self.view.insertSubview(playerView, at: 0)
        self.setupConstraints(for: playerView)
        
        // Do any additional setup after loading the view.
        addTapGestureRecognizers() // adding gesture recognizers
    }
    
    func addTapGestureRecognizers() {
        //Add tap gesture to both playerView and controlView
        let playerViewTap = UITapGestureRecognizer(target: self, action: #selector(toggleHideControlView))
        //add the gesture recognizers to the playerView.
        self.playerView.addGestureRecognizer(playerViewTap)
        
        let controlsViewTap = UITapGestureRecognizer(target: self, action: #selector(toggleHideControlView))
        //add the gesture recognizers to the controlView.
        self.controlView.addGestureRecognizer(controlsViewTap)
    }
    
    @objc private func toggleHideControlView() {
        controlView.isHidden.toggle()
        self.autoHideControlView(after: autoHideDuration)
    }
}

//MARK: - AutoHide ControlView
extension HLSPlayerViewController {
    private func autoHideControlView(after timeInterval: TimeInterval) {
        timer?.invalidate() // invalidate any previous timer
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] timer in
            guard let self = self else { return }
            self.autoHideControlView()
        }
    }
    
    private func autoHideControlView() {
        //Return if video is not playing, controlView is hidden
        guard self.player.timeControlStatus == .playing else { return }
        guard !self.controlView.isHidden else { return }
        self.controlView.isHidden.toggle()
    }
}

//MARK:- Layout Constraints
extension HLSPlayerViewController {
    func setupConstraints(for playerView: HLSPlayerView) {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        playerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
}

//MARK:- Utility
extension UIApplication {
    var keyWindowFrame: CGRect? {
        return keyWindow?.frame
    }
}
