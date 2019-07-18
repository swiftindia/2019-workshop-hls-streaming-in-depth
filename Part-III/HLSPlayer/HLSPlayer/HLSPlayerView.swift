//
//  HLSPlayerView.swift
//  HLSPlayer
//
//  Created by soaurabh on 16/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit
import AVFoundation

//A UIView is really just a wrapper around a CALayer. It provides touch handling and accessibility features, but isn’t a subclass. Instead, it owns and manages an underlying layer property. One nifty trick is that you can actually specify what type of layer you would like your view subclass to own.
class HLSPlayerView: UIView {
    
    // AVPlayerLayer, a CALayer subclass is like any other layer: It displays whatever is in its contents property onscreen.
    //This layer just happens to fill its contents with frames from a video you’ve given it via its player property.
    
    //property override to inform this class that it should use an AVPlayerLayer instead of a plain CALayer.
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    //Add the following computed property so you don’t need to cast your layer subclass all the time.
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    //Since you’re wrapping the player layer in a view, you’ll need to expose a player property.
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }
}
