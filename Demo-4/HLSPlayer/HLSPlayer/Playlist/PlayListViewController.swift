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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
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
