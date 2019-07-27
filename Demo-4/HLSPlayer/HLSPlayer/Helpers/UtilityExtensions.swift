//
//  UtilityExtensions.swift
//  HLSPlayer
//
//  Created by soaurabh on 25/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit
import AVFoundation

//MARK:- Utility
extension UIApplication {
    var keyWindowFrame: CGRect? {
        return keyWindow?.frame
    }
}

extension HLSPlayerViewController {
    func format(duration: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional // Use the appropriate positioning for the current locale
        formatter.allowedUnits = duration >= 3600 ?
            [.hour, .minute, .second] :
            [.minute, .second] // Units to display in the formatted string
        formatter.zeroFormattingBehavior = [ .pad ] // Pad with zeroes where appropriate for the locale
        
        let formattedDuration = formatter.string(from: duration)
        return formattedDuration
    }
}

extension Notification.Name {
    /// Notification for when a timebase changed rate
    static let TimebaseEffectiveRateChangedNotification = Notification.Name(rawValue: kCMTimebaseNotification_EffectiveRateChanged as String)
}
