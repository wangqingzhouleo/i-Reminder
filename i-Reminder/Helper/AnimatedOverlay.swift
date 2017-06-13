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
    
    func startAnimatingWithColor(_ color: UIColor, andFrame frame: CGRect)
    {
        self.image = UIImage(named: "circle.png")
        let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.clip(to: rect, mask: (self.image?.cgImage)!)
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let flippedImage = UIImage(cgImage: (img?.cgImage!)!, scale: 1.0, orientation: UIImageOrientation.downMirrored)
        
        self.image = flippedImage
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = duration
        opacityAnimation.repeatCount = HUGE
        opacityAnimation.fromValue = NSNumber(value: 0.3 as Double)
        opacityAnimation.toValue = NSNumber(value: 0.15 as Double)
        
        let transformAnimation = CABasicAnimation(keyPath: "transform.scale")
        transformAnimation.duration = duration
        transformAnimation.repeatCount = HUGE
        transformAnimation.fromValue = NSNumber(value: minRatio as Double)
        transformAnimation.toValue = NSNumber(value: maxRatio as Double)
        
//        view.layer.addAnimation(opacityAnimation, forKey: "opacity")
//        view.layer.addAnimation(transformAnimation, forKey: "transform")
        self.layer.add(opacityAnimation, forKey: "opacity")
        self.layer.add(transformAnimation, forKey: "transform")
//        layer.addAnimation(opacityAnimation, forKey: "opacity")
//        layer.addAnimation(transformAnimation, forKey: "transform")
        
    }
    
    override func stopAnimating() {
        self.layer.removeAllAnimations()
        self.removeFromSuperview()
    }

}
