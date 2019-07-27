//
//  PlayListVideo.swift
//  HLSPlayer
//
//  Created by soaurabh on 19/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import Foundation

struct PlayListVideo {
    let url: URL
    let thumbName: String
    
    static func allPlayList() -> [PlayListVideo] {
        let playlistURLs = [URL(string: "http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8")!, URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!, URL(string: "http://184.72.239.149/vod/smil:BigBuckBunny.smil/playlist.m3u8")!, URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!, URL(string: "https://mnmedias.api.telequebec.tv/m3u8/29880.m3u8")!, URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!]
        let playlistThumbNames = ["mac", "redbull", "bigbunny", "sintel", "voivod", "bipbop"]
        
        var allPlayList = [PlayListVideo]()
        
        for (index, name) in playlistThumbNames.enumerated() {
            let playlistVideo = PlayListVideo(url: playlistURLs[index], thumbName: name)
            allPlayList.append(playlistVideo)
        }
        return allPlayList
    }
}

