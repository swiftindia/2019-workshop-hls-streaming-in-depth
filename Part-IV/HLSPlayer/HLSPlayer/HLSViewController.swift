//
//  HLSViewController.swift
//  HLSPlayer
//
//  Created by soaurabh on 16/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit
import AVFoundation

class HLSViewController: UIViewController {
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    private let playerView: HLSPlayerView
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
    private lazy var playbackControlView = PlaybackControlView(volume: player.volume, brightness: UIScreen.main.brightness, rate: player.rate, quality: QualityVarient.auto.rawValue)
    private lazy var slideInViewLauncher = SlideInViewLauncher(slideInView: playbackControlView)
    private enum QualityVarient: Int {
        case low
        case medium
        case auto
        case high
        case hd
        var bitrate: Double {
            //https://bitmovin.com/video-bitrate-streaming-hls-dash/
            switch self {
            case .low:
                return 700 //for 240p streams
            case .medium:
                return 2100 //for 480p streams
            case .auto:
                return 0 // default preferredPeakBitRate, will highest quality/bitrate supported by your connection
            case .high:
                return 4200 //for 720p streams
            case .hd:
                return 28000 //for 2160p streams
            }
        }
        
        var resolution: CGSize {
            switch self {
            case .low:
                return CGSize(width: 426, height: 240) //for 240p streams
            case .medium:
                return CGSize(width: 854, height: 480) //for 480p streams
            case .auto:
                return CGSize.zero // default preferredMaximumResolution, will highest resolution supported by your connection
            case .high:
                return CGSize(width: 1280, height: 720) //for 720p streams
            case .hd:
                return CGSize(width: 4096, height: 2160) //for 2160p streams
            }
        }
    }
    
    init(playerURL: URL) {
        let asset = AVURLAsset(url: playerURL)
        asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: nil) //preloading master playlist
        playerItem = AVPlayerItem(asset: asset)
        playerItem.audioTimePitchAlgorithm = .spectral // highest audio quality
        player = AVPlayer()
        playerView = HLSPlayerView(frame: .zero) //init playerLayer
        playerView.player = player //sets player on the playerLayer
        player.replaceCurrentItem(with: playerItem) //setup audio+video playback
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
        self.observeTimeControlStatus()
        self.registerPlayerDidReachedEndNotification()
    }
    
    //Use this init for precaching
    init?(player: AVPlayer, playerView: HLSPlayerView) {
        //guard if the player has set currentItem, player on playerView and playerOnView is same as the passed player
        guard let playerItem = player.currentItem, let playerOnView = playerView.player, player == playerOnView else { return nil}
        self.playerItem = playerItem
        self.player  = player
        self.playerView = playerView
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
        self.observeTimeControlStatus()
        self.registerPlayerDidReachedEndNotification()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removePlayerTimeObserver()
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        observer?.invalidate()
    }
    
    @IBAction func dismissViewController(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK:- Video Scrubbing/Seeking
extension HLSViewController {
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
extension HLSViewController: PlaybackControlViewDelegate {
    
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
            player.currentItem?.preferredMaximumResolution = QualityVarient(rawValue: quality)?.resolution ?? QualityVarient.auto.resolution
        } else {
            player.currentItem?.preferredPeakBitRate = QualityVarient(rawValue: quality)?.bitrate ?? QualityVarient.auto.bitrate
        }
    }
    
    func dismissView() {
        slideInViewLauncher.dismiss()
    }
}

//MARK:- Forward/Backward
extension HLSViewController {
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
extension HLSViewController {
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
extension HLSViewController {
    @IBAction func togglePlay(_ sender: UIButton) {
        self.togglePlay()
    }
    
    private func togglePlay() {
        if player.timeControlStatus == .playing {
            self.pause()
            self.playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        } else if player.timeControlStatus == .paused {
            self.play()
            self.playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
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
extension HLSViewController {
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
                self.playPauseButton.isHidden = false
                self.initializeScrubberTimer()
            }
        }
    }
    
    private func registerPlayerDidReachedEndNotification() {
        // Register for AVPlayerItemDidPlayToEndTime i.e. the player item has played to its end time
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    @objc func playerItemDidReachEnd(_ notification: Notification) {
        player.seek(to: CMTime.zero) // seek to time zero on reaching end
        togglePlay() //on reaching end player.timeControlStatus is playing, toggle it to pause
    }
    
}

//MARK: - Toggle Show/Hide ControlView
extension HLSViewController {
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
        self.setupConstraintsForPlayerView()
        
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
extension HLSViewController {
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
extension HLSViewController {
    private func setupConstraintsForPlayerView() {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        playerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
}


//MARK:- Utility
extension HLSViewController {
    func format(duration: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional // Use the appropriate positioning for the current locale
        formatter.allowedUnits = duration >= 3600 ?
            [.hour, .minute, .second] :
            [.minute, .second] // Units to display in the formatted string
        formatter.zeroFormattingBehavior = [ .pad ] // Pad with zeroes where appropriate for the locale
        
        let formattedDuration = formatter.string(from: duration)
        return formattedDuration
    }
}
