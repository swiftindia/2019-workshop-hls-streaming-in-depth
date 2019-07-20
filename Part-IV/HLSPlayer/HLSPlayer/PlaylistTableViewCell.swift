//
//  PlaylistTableViewCell.swift
//  HLSPlayer
//
//  Created by soaurabh on 19/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var playlistImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func update(with video: PlayListVideo) {
        let image = UIImage(named: video.thumbName)
        playlistImageView.image = image
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
