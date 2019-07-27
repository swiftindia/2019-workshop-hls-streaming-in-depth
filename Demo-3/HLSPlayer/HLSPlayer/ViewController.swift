//
//  ViewController.swift
//  HLSPlayer
//
//  Created by soaurabh on 16/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func playHLSStream(_ sender: UITapGestureRecognizer) {
        guard let videoURL = URL(string: "http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8") else { return }
        let playerViewController = HLSPlayerViewController(playerURL: videoURL)
        self.present(playerViewController, animated: true) {
            playerViewController.play()
        }
    }
}

