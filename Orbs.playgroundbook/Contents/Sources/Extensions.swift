//
//  Extensions.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit
import SpriteKit

// Vector Math
extension CGPoint {
    static func +(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x , y: left.y + right.y)
    }
    
    static func -(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x , y: left.y - right.y)
    }
    
    static func *(left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
    
    static func /(left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x / right, y: left.y / right)
    }
    
    func length() -> CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }
    
    func distanceTo(_ point: CGPoint) -> CGFloat {
        let distance = (self - point).length()
        return distance
    }
    
    func normalized() -> CGPoint {
        return self / self.length()
    }
    
    func perpendicularClockwise() -> CGPoint {
        return CGPoint(x: -self.y, y: self.x)
    }
    
    func perpendicularCounterClockwise() -> CGPoint {
        return CGPoint(x: self.y, y: -self.x)
    }
}

extension CGSize {
    
    static func *(left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width * right, height: left.height * right)
    }
    static func /(left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width / right, height: left.height / right)
    }
    
}

extension Array where Element: Equatable {
    mutating func removeElement(_ element: Element) {
        self = self.filter({$0 != element })
    }
}

extension Array {
    func randomElement() -> Element {
        let randomIndex = Int(arc4random_uniform(UInt32(self.count)))
        return self[randomIndex]
    }
}

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension SKSpriteNode {
//    func isOnScreen() -> Bool {
//
//        var isInsideScreen = true
//
//        let screenSize = UIScreen.main.bounds.size
//
//        if !(self.position.x >= size.width/2 - screenSize.width/2 && self.position.x <= screenSize.width/2 - size.width/2) {
//            isInsideScreen = false
//        }
//
//        if !(self.position.y >= size.height/2 - screenSize.height/2 && self.position.y <= screenSize.height/2 - size.height/2) {
//            isInsideScreen = false
//        }
//
//        return isInsideScreen
//    }
    
    func isInside(_ scene: SKScene) -> Bool {
        var isInsideScreen = true
        
        let screenSize = scene.frame.size
        
        if !(self.position.x >= -screenSize.width/2 - self.size.width/2 && self.position.x <= screenSize.width/2 + self.size.width/2) {
            isInsideScreen = false
        }
        
        if !(self.position.y >=  -screenSize.height/2 - self.size.height/2 && self.position.y <= screenSize.height/2 + self.size.height/2) {
            isInsideScreen = false
        }
        
        return isInsideScreen
    }
    
    func isNearScreenBorder() -> Bool {
        
        var isNearScreenBorder = false
        
        let screenSize = UIScreen.main.bounds.size
        if (self.position.x < size.width/2 - screenSize.width/2.1 || self.position.x > screenSize.width/2.1 - size.width/2) {
            isNearScreenBorder = true
        }
        
        if (self.position.y < size.height/2 - screenSize.height/2.1 || self.position.y > screenSize.height/2.1 - size.height/2) {
            isNearScreenBorder = true
        }
        
        return isNearScreenBorder
    }
}


// MARK: Design Implementation
extension SKShapeNode {
    // Used for ability button cooldown animation
    static func arcShapeNodeWith(_ radius: CGFloat, _ startingAngle: CGFloat, _ endingAngle: CGFloat, clockwise: Bool) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint.zero)
        path.addLine(to: CGPoint(x: 0, y: -radius))
        path.addArc(center: CGPoint.zero,
                    radius: radius,
                    startAngle: startingAngle,
                    endAngle: endingAngle,
                    clockwise: clockwise)
        
        let mask = SKShapeNode(path: path)
        mask.lineWidth = 1
        mask.fillColor = .blue
        mask.strokeColor = .white
        return mask
    }
}

extension SKSpriteNode {
    // Default menu button
    convenience init(imageNamed imageName: String, andText text: String) {
        self.init(imageNamed: imageName)
        
        self.zPosition = ZPosition.MenuUserInterface
        
        let buttonLabel = SKLabelNode(text: text)
        buttonLabel.fontColor = .white
        buttonLabel.fontName = "Secular One"
        buttonLabel.fontSize = 40
        buttonLabel.zPosition = self.zPosition + 1
        buttonLabel.horizontalAlignmentMode = .center
        buttonLabel.verticalAlignmentMode = .center
        self.addChild(buttonLabel)
    }
}

extension SKLabelNode {
    // Default text font
    convenience init(withText text: String) {
        self.init(text: text)
        
        self.fontColor = .white
        self.fontSize = 40
        self.fontName = "Dosis Bold"
        self.zPosition = ZPosition.MenuUserInterface
        self.horizontalAlignmentMode = .center
        self.verticalAlignmentMode = .center
    }
}

extension CGFloat {
    func inRadians() -> CGFloat {
        return self * CGFloat.pi / 180.0
    }
}
