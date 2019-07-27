//
//  HLSQualityVarient.swift
//  HLSPlayer
//
//  Created by soaurabh on 25/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit

enum HLSQualityVarient: Int {
    case low
    case medium
    case auto
    case high
    case hd
    var bitrate: Double {
        //https://bitmovin.com/video-bitrate-streaming-hls-dash/
        switch self {
        case .low:
            return 700_000 //for 240p streams
        case .medium:
            return 2100_000 //for 480p streams
        case .auto:
            return 0 // default preferredPeakBitRate, will highest quality/bitrate supported by your connection
        case .high:
            return 4200_000 //for 720p streams
        case .hd:
            return 28000_000 //for 2160p streams
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

