//
//  SlideInViewLauncher.swift
//  HLSPlayer
//
//  Created by soaurabh on 18/07/19.
//  Copyright © 2019 SwiftIndia. All rights reserved.
//

import UIKit

class SlideInViewLauncher {
    private let slideInView: UIView
    private var isViewVisible = false
    
    private lazy var blurView: UIView = {
        let blurView = UIView()
        blurView.backgroundColor = UIColor(white: 0, alpha: 0.55)
        return blurView
    }()
    
    private lazy var height: CGFloat = {
        var height: CGFloat = slideInView.bounds.height
        return height
    }()
    
    private lazy var window: UIWindow? = {
        return UIApplication.shared.keyWindow
    }()
    
    init(slideInView: UIView) {
        let targetSize = CGSize(width: slideInView.bounds.width,
                                height: UIView.layoutFittingCompressedSize.height)
        slideInView.frame.size = slideInView.systemLayoutSizeFitting(targetSize)
        self.slideInView = slideInView
    }
    
    //show slide-in view
    func show() {
        // Return if view is already visible or key-window is not available
        guard !isViewVisible, let window = self.window else { return }
        
        // Add tap gesture to blurView, and blurView and slideInView as subviews of window
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
        blurView.addGestureRecognizer(tapGesture)
        window.addSubview(blurView)
        window.addSubview(slideInView)
        
        let originY = window.frame.height - height
        slideInView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: height)
        blurView.frame = window.frame
        blurView.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { [weak self] in
            guard let self = self else { return }
            self.blurView.alpha = 1
            self.slideInView.frame = CGRect(x: 0, y: originY, width: self.slideInView.frame.width, height: self.height)
            }, completion: nil)
        
        isViewVisible.toggle()
    }
    
    //dismiss slide-in view
    @objc func dismiss() {
        // Return if view is already dismissed or key-window is not available
        guard isViewVisible, let window = self.window else { return }
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.blurView.alpha = 0
            self.slideInView.frame = CGRect(x: 0, y: window.frame.height, width: self.slideInView.frame.width, height: self.height)
        }
        isViewVisible.toggle()
    }
    
    //Remove views from window
    deinit {
        blurView.removeFromSuperview()
        slideInView.removeFromSuperview()
    }
}


