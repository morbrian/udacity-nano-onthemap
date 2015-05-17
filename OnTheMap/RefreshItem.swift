//
//  RefreshItem.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/16/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//
// Reference: http://www.raywenderlich.com/93695/video-tutorial-swift-scroll-view-school-part-17-pull-refresh-iii
//

import UIKit

import UIKit

class RefreshItem {
    unowned var view: UIView
    private var spinnerBaseTransform: CGAffineTransform
    
    init(view: UIView, center: CGPoint) {
        self.view = view
        self.view.center = center
        self.spinnerBaseTransform = view.transform
    }
    
    var activityInProgress = false
    
    func animate() {
        UIView.animateWithDuration(0.001,
            delay: 0.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { self.view.transform =
                CGAffineTransformConcat(self.view.transform, CGAffineTransformMakeRotation((CGFloat(60.0) * CGFloat(M_PI)) / CGFloat(180.0)) )},
            completion: { something in
                if self.activityInProgress {
                    self.animate()
                } else {
                    // TODO: this snaps to position at then end, we should perform the final animation.
                    self.view.transform = self.spinnerBaseTransform
                }
        })
    }

}