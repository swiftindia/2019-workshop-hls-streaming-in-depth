//
//  PlayListHomeViewController.swift
//  HLSPlayer
//
//  Created by soaurabh on 16/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit
import AVFoundation

class PlayListHomeViewController: UIViewController {
    @IBOutlet private weak var playlistTableView: UITableView!
    private let playlistCellReuseIdentifier = "PlaylistTableViewCell"
    private let playListVideos = PlayListVideo.allPlayList()
    
    //precache preferrably 6-20 seconds of top two videos in the playlist
    private lazy var preCachedList: [(player: AVPlayer, playerView: HLSPlayerView)] = {
        var preCachedList = [(AVPlayer, HLSPlayerView)]()
        for (index, playListVideo) in playListVideos.enumerated() where index < 2 {
            let asset = AVURLAsset(url: playListVideo.url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: nil) //preloading master playlist, this is important for zero buffering
            var playerItem = AVPlayerItem(asset: AVURLAsset(url: playListVideo.url))
            playerItem.preferredForwardBufferDuration = TimeInterval(20.0)
            playerItem.audioTimePitchAlgorithm = .spectral // highest audio quality
            let player = AVPlayer()
            let playerView = HLSPlayerView(frame: UIApplication.shared.keyWindowFrame ?? .zero) // init player layer view with correct frame
            playerView.player = player
            playerView.layerContentsScale = UIScreen.main.scale // set the contentsScale(for retina devices)
            player.replaceCurrentItem(with: playerItem)
            preCachedList.append((player, playerView))
        }
        return preCachedList
    }()
    
    //Looper View Controller
    private lazy var hlsLooperViewController = HLSLooperViewController(playlistURLs: videoPlaylistURLs)
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
        hlsLooperViewController.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Make sure it's paused when the user leaves this screen
        hlsLooperViewController.pause()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = self.preCachedList // init precache list
        // Do any additional setup after loading the view.
        self.add(hlsLooperViewController)
        self.setupConstraints(for: hlsLooperViewController.view)
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

extension PlayListHomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create an HLSViewController and present it when the user taps
        let video = playListVideos[indexPath.row]
        let videoURL = video.url
        let videoIndex = indexPath.row
        let hlsViewController: HLSViewController
        if videoIndex < preCachedList.count {
            hlsViewController = HLSViewController(player: preCachedList[videoIndex].player, playerView: preCachedList[videoIndex].playerView) ?? HLSViewController(playerURL: videoURL)
        } else {
            hlsViewController = HLSViewController(playerURL: videoURL)
        }
        present(hlsViewController, animated: true) {
            hlsViewController.play()
        }
    }
}

extension PlayListHomeViewController: UITableViewDataSource {
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
