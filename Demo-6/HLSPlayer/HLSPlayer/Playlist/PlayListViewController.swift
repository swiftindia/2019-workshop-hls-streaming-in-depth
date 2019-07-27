//
//  PlayListViewController.swift
//  HLSPlayer
//
//  Created by soaurabh on 16/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit
import AVFoundation

class PlayListViewController: UIViewController {
    @IBOutlet private weak var playlistTableView: UITableView!
    private let playlistCellReuseIdentifier = "PlaylistTableViewCell"
    private let playListVideos = PlayListVideo.allPlayList()
    
    //Looper View Controller
    private lazy var looperViewController = HLSLooperViewController(playlistURLs: videoPlaylistURLs)
    private lazy var videoPlaylistURLs: [URL] = {
        //play local plus hls-stream, playlist-credits: raywenderlich.com
        let names = ["newYorkFlip-clip", "bulletTrain-clip", "monkey-clip", "shark-clip"]
        var playlistURLs = [URL(string: "https://wolverine.raywenderlich.com/content/ios/tutorials/video_streaming/foxVillage.m3u8")!]
        for name in names {
            let urlPath = Bundle.main.path(forResource: name, ofType: "mp4")!
            let url = URL(fileURLWithPath: urlPath)
            playlistURLs.append(url)
        }
        return playlistURLs
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Start the looping video player when the view appears
        looperViewController.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Make sure it's paused when the user leaves this screen
        looperViewController.pause()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.add(looperViewController)
        self.setupConstraints(for: looperViewController.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // deselect the selected row if any
        let selectedRow: IndexPath? = playlistTableView.indexPathForSelectedRow
        if let selectedRowNotNill = selectedRow {
            playlistTableView.deselectRow(at: selectedRowNotNill, animated: true)
        }
    }
}

extension PlayListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create an HLSPlayerViewController and present it when the user taps
        let video = playListVideos[indexPath.row]
        let videoURL = video.url
        let playerViewController: HLSPlayerViewController
        playerViewController = HLSPlayerViewController(playerURL: videoURL)
        present(playerViewController, animated: true) {
            playerViewController.play()
        }
    }
}

extension PlayListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let playlistCell = tableView.dequeueReusableCell(withIdentifier: playlistCellReuseIdentifier, for: indexPath) as? PlaylistTableViewCell else {
            return PlaylistTableViewCell()
        }
        playlistCell.update(with: playListVideos[indexPath.row])
        return playlistCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playListVideos.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
