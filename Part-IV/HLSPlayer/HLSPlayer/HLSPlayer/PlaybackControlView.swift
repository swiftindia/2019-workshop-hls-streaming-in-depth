//
//  PlaybackControlView.swift
//  HLSPlayer
//
//  Created by soaurabh on 18/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit

protocol PlaybackControlViewDelegate: class {
    func adjustVolume(_ volume: Float)
    func adjustBrightness(_ brightness: CGFloat)
    func adjustPlaybackRate(_ rate: Float)
    func adjustQuality(_ quality: Int)
    func dismissView()
}

class PlaybackControlView: UIView {
    @IBOutlet weak var volumeSlider: UISlider! // avplayer volume
    @IBOutlet weak var brightnessSlider: UISlider! // UIScreen.main.brightness
    @IBOutlet weak var playbackRateSlider: UISlider!
    @IBOutlet weak var qualitySlider: UISlider!
    @IBOutlet weak var contentView: UIView!
    private var volume: Float?
    private var brightness: CGFloat?
    private var quality: Int? // Low(0), Med(1), Auto(2) High(3), HD(4)
    var playbackRate: Float? {
        didSet {
            playbackRateSlider.value = (self.playbackRate ?? 1.0) * 2
        }
    }
    weak var delegate: PlaybackControlViewDelegate?
    
    internal convenience init(volume: Float, brightness: CGFloat, rate: Float, quality: Int) {
        self.init(frame: .zero)
        self.volume = volume
        self.brightness = brightness
        self.playbackRate = rate
        self.quality = quality
        setupView()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.loadView()
        volumeSlider.value = self.volume ?? 1.0
        brightnessSlider.value = Float(self.brightness ?? 1.0)
        playbackRateSlider.value = (self.playbackRate ?? 1.0) * 2
        qualitySlider.value = Float(self.quality ?? 2)
    }
    
    @IBAction func adjustVolume(_ sender: UISlider) {
        delegate?.adjustVolume(sender.value)
    }
    
    @IBAction func adjustBrightness(_ sender: UISlider) {
        delegate?.adjustBrightness(CGFloat(sender.value))
    }
    
    @IBAction func adjustPlaybackRate(_ sender: UISlider) {
        //Rate values varies from 0 to 4, i.e. 0.0x, 0.5x, 1.0x, 1.5x, 2.0x
        sender.value = roundf(sender.value)
        delegate?.adjustPlaybackRate(sender.value / 2)
    }
    
    @IBAction func adjustQuality(_ sender: UISlider) {
        //Quality values varies from 0 to 3, i.e. Low(0), Med(1), Auto(2) High(3), HD(4)
        sender.value = roundf(sender.value)
        delegate?.adjustQuality(Int(sender.value))
    }
    
    @IBAction func dismiss(_ sender: UIButton) {
        delegate?.dismissView()
    }
}
