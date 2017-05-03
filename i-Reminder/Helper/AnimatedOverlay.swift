//
//  AnimatedOverlay.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 8/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//


// This class is created an animation for image view
// Source from http://yickhong-ios.blogspot.com.au/2012/04/animated-circle-on-mkmapview.html

import UIKit
import MapKit

class AnimatedOverlay: UIImageView {
    
    let minRatio = 0.0
    let maxRatio = 2.5
    var duration = 2.0
    
    func startAnimatingWithColor(color: UIColor, andFrame frame: CGRect)
    {
        self.image = UIImage(named: "circle.png")
        let rect = CGRectMake(0, 0, frame.width, frame.height)
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        CGContextClipToMask(context, rect, self.image?.CGImage)
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let flippedImage = UIImage(CGImage: img.CGImage!, scale: 1.0, orientation: UIImageOrientation.DownMirrored)
        
        self.image = flippedImage
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = duration
        opacityAnimation.repeatCount = HUGE
        opacityAnimation.fromValue = NSNumber(double: 0.3)
        opacityAnimation.toValue = NSNumber(double: 0.15)
        
        let transformAnimation = CABasicAnimation(keyPath: "transform.scale")
        transformAnimation.duration = duration
        transformAnimation.repeatCount = HUGE
        transformAnimation.fromValue = NSNumber(double: minRatio)
        transformAnimation.toValue = NSNumber(double: maxRatio)
        
//        view.layer.addAnimation(opacityAnimation, forKey: "opacity")
//        view.layer.addAnimation(transformAnimation, forKey: "transform")
        self.layer.addAnimation(opacityAnimation, forKey: "opacity")
        self.layer.addAnimation(transformAnimation, forKey: "transform")
//        layer.addAnimation(opacityAnimation, forKey: "opacity")
//        layer.addAnimation(transformAnimation, forKey: "transform")
        
    }
    
    override func stopAnimating() {
        self.layer.removeAllAnimations()
        self.removeFromSuperview()
    }

}
