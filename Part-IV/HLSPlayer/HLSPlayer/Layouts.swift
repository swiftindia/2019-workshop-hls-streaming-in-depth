//
//  Layouts.swift
//  HLSPlayer
//
//  Created by soaurabh on 25/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit

//MARK:- Utility
extension UIViewController {
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        // Just to be safe, we check that this view controller
        // is actually added to a parent before removing it.
        guard parent != nil else {
            return
        }
        
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

//MARK:- Setup Constraints
extension PlayListHomeViewController {
    func setupConstraints(for looperView: UIView) {
        looperView.translatesAutoresizingMaskIntoConstraints = false
        // Specifying constraints.
        looperView.widthAnchor.constraint(equalToConstant: 180).isActive = true
        looperView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        if #available(iOS 11.0, *) {
            looperView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20.0).isActive = true
        } else {
            // Fallback on earlier versions
            looperView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0).isActive = true
        }
        
        if #available(iOS 11.0, *) {
            looperView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0.0).isActive = true
        } else {
            // Fallback on earlier versions
            looperView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20.0).isActive = true
        }
    }
}

//MARK:- Layout Constraints
extension HLSViewController {
    func setupConstraints(for playerView: HLSPlayerView) {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        playerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
}


//MARK:- Layout PlaybackControlView
extension PlaybackControlView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = bounds
    }
    
    func loadView() {
        Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        self.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
}
