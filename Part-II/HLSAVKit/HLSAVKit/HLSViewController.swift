//
//  HLSViewController.swift
//  HLSAVKit
//
//  Created by soaurabh on 15/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit
import AVKit //provides all necessary UI for interacting with a video.

class HLSViewController: UIViewController {
    //Exception Domains for http URL load
    private let videoURL = "http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"
    
    @IBAction func thumnailTapped(_ sender: UITapGestureRecognizer) {
        //Return if URL cannot be formed
        guard let videoURL = URL(string: videoURL) else { return }
        
        //Create an AVPlayer instance passing-in the HLS URL
        let player = AVPlayer(url: videoURL)
        
        //AVPlayerViewController(subclass of UIViewController) displays the video content from a player object along with system-supplied playback controls.
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        //play method of AVPlayer instance plays the video after presentation
        present(playerViewController, animated: true) {
            player.play()
        }
    }
}

