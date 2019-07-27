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
    private var perfMeasurements: PerfMeasurements? // performance measurements
    private weak var timer: Timer?
    private var observer: NSKeyValueObservation?
    private var timeObserver: Any?
    private var restoreAfterScrubbingRate: Float?
    private let autoHideDuration = 5.0 // controlView autoHide duration
    private let seekInterval = Double(10) // for fast forward/backward
    @IBOutlet private weak var controlView: UIView! //hidden initially
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var videoLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var videoScrubber: UISlider!
    @IBOutlet private weak var currentTime: UILabel!
    @IBOutlet private weak var videoDuration: UILabel!
    private lazy var playbackControlView = PlaybackControlView(volume: player.volume, brightness: UIScreen.main.brightness, rate: player.rate, quality: HLSQualityVarient.auto.rawValue)
    private lazy var slideInViewLauncher = SlideInViewLauncher(slideInView: playbackControlView)
    
    init(playerURL: URL) {
        let asset = AVURLAsset(url: playerURL)
        asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: nil) //preloading master playlist
        playerItem = AVPlayerItem(asset: asset)
        playerItem.audioTimePitchAlgorithm = .spectral // highest audio quality
        player = AVPlayer()
        playerView = HLSPlayerView(frame: UIApplication.shared.keyWindowFrame ?? .zero) // init player layer view with correct frame
        playerView.player = player //sets player on the playerLayer
        playerView.layerContentsScale = UIScreen.main.scale // set the contentsScale(for retina devices)
        player.replaceCurrentItem(with: playerItem) //setup audio+video playback
        perfMeasurements = PerfMeasurements(playerItem: playerItem) // init performance measurements
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
        self.observeTimeControlStatus()
        self.registerNotifications()
    }
    
    //Use this init for precaching
    init?(player: AVPlayer, playerView: HLSPlayerView) {
        //guard if the player has set currentItem, player on playerView and playerOnView is same as the passed player
        guard let playerItem = player.currentItem, let playerOnView = playerView.player, player == playerOnView else { return nil}
        self.playerItem = playerItem
        self.player  = player
        self.playerView = playerView
        self.perfMeasurements = PerfMeasurements(playerItem: playerItem) // init performance measurements
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
        self.observeTimeControlStatus()
        self.registerNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removePlayerTimeObserver()
        // Remove all notifications explicitly, maybe not required now
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: .TimebaseEffectiveRateChangedNotification, object: playerItem.timebase)
        notificationCenter.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: playerItem)
        notificationCenter.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        timer?.invalidate()
        observer?.invalidate()
    }
    
    @IBAction func dismissViewController(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK:- Video Scrubbing/Seeking
extension HLSPlayerViewController {
    // updates the video scrubber control repeatedly during playback
    func initializeScrubberTimer() {
        var interval = Double(0.1)
        
        //get playerItem duration
        guard let playerDuration = self.playerItemDuration else { return }
        let duration = CGFloat(CMTimeGetSeconds(playerDuration))
        
        //set duration label
        videoDuration.text = self.format(duration: TimeInterval(duration))
        
        // check if the duration is finite greater than 0.0 then update interval
        if duration.isFinite && duration > 0.0 {
            let width = self.videoScrubber.bounds.width
            interval = min(Double(0.5 * duration / width), 1.0)
        }
        
        //Update the scrubber during normal playback.
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(interval, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil, using: { [weak self] (time) in
            guard let self = self else { return }
            self.syncScrubber()
        })
    }
    
    //Set the scrubber based on the player current time.
    func syncScrubber() {
        guard let playerDuration = self.playerItemDuration else {
            videoScrubber.minimumValue = 0.0
            return
        }
        let duration = Float(CMTimeGetSeconds(playerDuration))
        
        //Calculate and set scrubber value based currentTime and duration.
        if duration.isFinite && duration > 0.0 {
            let minValue = videoScrubber.minimumValue
            let maxValue = videoScrubber.maximumValue
            let time = Float(CMTimeGetSeconds(player.currentTime()))
            currentTime.text = self.format(duration: TimeInterval(time))
            videoScrubber.setValue((maxValue - minValue) * time / duration + minValue, animated: true)
        }
    }
    
    //The user is dragging the thumb to scrub through the video.
    @IBAction func beginScrubbing(_ sender: UISlider) {
        restoreAfterScrubbingRate = player.rate // storing rate so that we can restore it after scrubbing
        player.rate = 0.0 // pause the playback
        
        //remove previous timeObserver
        self.removePlayerTimeObserver()
    }
    
    //Set the player current time to match the scrubber position.
    @IBAction func scrub(_ sender: UISlider) {
        guard let playerDuration = self.playerItemDuration else { return }
        let duration = Float(CMTimeGetSeconds(playerDuration))
        
        guard duration.isFinite && duration > 0.0 else { return }
        let minValue = sender.minimumValue
        let maxValue = sender.maximumValue
        let value = sender.value
        let time = Double(duration * (value - minValue) / (maxValue - minValue))
        player.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
    
    //The user has released the thumb control to stop scrubbing through the video
    @IBAction func endScrubbing(_ sender: UISlider) {
        //timeObserver is removed during the start/begin of scrubbing
        if timeObserver == nil {
            guard let playerDuration = self.playerItemDuration else { return }
            let duration = CGFloat(CMTimeGetSeconds(playerDuration))
            
            if duration.isFinite && duration > 0.0 {
                let width = videoScrubber.bounds.width
                let tolerance = min(Double(0.5 * duration / width), 1.0)
                
                //Update the scrubber during normal playback.
                timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(tolerance, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil, using: { [weak self] (time) in
                    guard let self = self else { return }
                    self.syncScrubber()
                })
            }
        }
        //Restore player at rate before scrubbing
        if let restoreRate = restoreAfterScrubbingRate {
            player.rate = restoreRate
            restoreAfterScrubbingRate = 0.0
        }
    }
    
    func enableScrubber() {
        videoScrubber.isEnabled = true
    }
    
    func disableScrubber() {
        videoScrubber.isEnabled = false
    }
}

//MARK:- Adjusting Volume, Brightness, PlaybackRate, Quality
extension HLSPlayerViewController: PlaybackControlViewDelegate {
    
    @IBAction func showPlaybackControlView(_ sender: UIButton) {
        slideInViewLauncher.show()
    }
    
    func adjustVolume(_ volume: Float) {
        player.volume = volume
    }
    
    func adjustBrightness(_ brightness: CGFloat) {
        UIScreen.main.brightness = brightness
    }
    
    func adjustPlaybackRate(_ rate: Float) {
        player.rate = rate
    }
    
    func adjustQuality(_ quality: Int) {
        //set the preferredPeakBitRate to adjust quality for iOS 10
        //But actually bitRate heavily depends on the audio/video codec and whether the video is HDR. So, starting iOS 11 we have preferredMaximumResolution
        if #available(iOS 11.0, *) {
            player.currentItem?.preferredMaximumResolution = HLSQualityVarient(rawValue: quality)?.resolution ?? HLSQualityVarient.auto.resolution
        } else {
            player.currentItem?.preferredPeakBitRate = HLSQualityVarient(rawValue: quality)?.bitrate ?? HLSQualityVarient.auto.bitrate
        }
    }
    
    func dismissView() {
        slideInViewLauncher.dismiss()
    }
}

//MARK:- Forward/Backward
extension HLSPlayerViewController {
    @IBAction func fastBackward(_ sender: UIButton) {
        guard let playerDuration = self.playerItemDuration else { return }
        let duration = CMTimeGetSeconds(playerDuration)
        guard duration.isFinite && duration > 0.0 else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var fastBackwardTime = currentTime - seekInterval
        if fastBackwardTime < 0.0 {
            fastBackwardTime = 0.0
        }
        player.seek(to: CMTimeMakeWithSeconds(fastBackwardTime, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
    
    @IBAction func fastForward(_ sender: UIButton) {
        guard let playerDuration = self.playerItemDuration else { return }
        let duration = CMTimeGetSeconds(playerDuration)
        guard duration.isFinite && duration > 0.0 else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var fastForwardTime = currentTime + seekInterval
        if fastForwardTime > duration {
            fastForwardTime = duration - 0.1  // rounding off, for player to seek
        }
        player.seek(to: CMTimeMakeWithSeconds(fastForwardTime, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
}

//MARK:- Player Item
extension HLSPlayerViewController {
    var playerItemDuration: CMTime? {
        // Check if the current playerItem exists and is readyToPlay
        guard let playerItem = self.player.currentItem else { return nil }
        guard playerItem.status == .readyToPlay else { return nil }
        return playerItem.duration
    }
    
    //Cancels the previously registered time observer
    func removePlayerTimeObserver() {
        if timeObserver != nil {
            player.removeTimeObserver(timeObserver!)
            timeObserver = nil;
        }
    }
}


//MARK:- Player Play/Pause
extension HLSPlayerViewController {
    @IBAction func togglePlay(_ sender: UIButton) {
        self.togglePlay()
    }
    
    private func togglePlay() {
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
            case .playing:
                self.playerItem.preferredForwardBufferDuration = TimeInterval(0.0) // as soon as playback begins, reset it to default
                fallthrough
            case .paused:
                self.autoHideControlView(after: self.autoHideDuration)
                self.playbackControlView.playbackRate = player.rate
                fallthrough
            @unknown default:
                self.videoLoadingIndicator.stopAnimating()
                self.syncPlayPauseButtonImages()
                self.playPauseButton.isHidden = false
                self.initializeScrubberTimer()
            }
        }
    }
    
    private func registerNotifications() {
        let notificationCenter = NotificationCenter.default
        // Register for AVPlayerItemDidPlayToEndTime i.e. the player item has played to its end time
        notificationCenter.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        //Register for timebase rate change and playback stalled notifications
        notificationCenter.addObserver(self,
                                       selector: #selector(handleTimebaseRateChanged(_:)),
                                       name: .TimebaseEffectiveRateChangedNotification, object: playerItem.timebase)
        notificationCenter.addObserver(self,
                                       selector: #selector(handlePlaybackStalled(_:)), name: .AVPlayerItemPlaybackStalled, object: playerItem)
    }
    
    @objc func playerItemDidReachEnd(_ notification: Notification) {
        perfMeasurements?.playbackEnded() // mark playback as ended
        player.seek(to: CMTime.zero) // seek to time zero on reaching end
        togglePlay() //on reaching end player.timeControlStatus is playing, toggle it to pause
    }
    
    @objc func handleTimebaseRateChanged(_ notification: Notification) {
        if CMTimebaseGetTypeID() == CFGetTypeID(notification.object as CFTypeRef) {
            let timebase = notification.object as! CMTimebase
            let rate: Double = CMTimebaseGetRate(timebase)
            perfMeasurements?.rateChanged(rate: rate)
        }
    }
    
    @objc func handlePlaybackStalled(_ notification: Notification) {
        perfMeasurements?.playbackStalled()
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
        // Do any additional setup after loading the view.
        //setup and add playerView
        playerView.backgroundColor = .black
        self.view.insertSubview(playerView, at: 0)
        self.setupConstraints(for: playerView)
        
        addTapGestureRecognizers() // adding gesture recognizers

        // initialize and sync scrubbing
        self.initializeScrubberTimer()
        self.syncScrubber()
        playbackControlView.delegate = self
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
