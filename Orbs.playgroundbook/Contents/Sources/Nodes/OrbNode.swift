//
//  OrbNode.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

enum Effect {
    case stunning, slowing, orbStealing, invulnerable     // This might have associated types like stunning(2) meaning stuns for 2 sec
    
    func effectColor() -> UIColor {
        switch self {
        case .stunning:
            return UIColor.yellow
        case .slowing:
            return UIColor.purple
        case .orbStealing:
            return UIColor.cyan
        case .invulnerable:
            return UIColor(red: 58/255, green: 215/255, blue: 255/255, alpha: 1)
        }
    }
}

class OrbNode: SKSpriteNode {
    
    static var defaultRadius: CGFloat {
        return 8
    }
    
    var destination: CGPoint?
    
    weak var player: PlayerNode!
    var team: Team! {
        didSet {
            self.drawTexture()
        }
    }
    
    var radius: CGFloat = OrbNode.defaultRadius {
        didSet {
            self.resize()
        }
    }
    
    var orbSpeed: CGFloat = OrbNode.defaultRadius //6 //8 // 10
    
    var damage: Int {
        get {
            var damageModifier = 0
            if let player = self.player {
                damageModifier = player.damageModifier
            }
            return Int(10/7 * radius) * (1 + damageModifier/100) // maybe just radius without multiplier
        }
    }
    
    var effects: [Effect] = [] {
        didSet {
            self.drawTexture()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(withTeam team: Team, andEffects effects: [Effect] = []) {
        
        self.team = team
        self.effects = effects
        
        super.init(texture: nil, color: UIColor.white, size: CGSize())
        
        self.zPosition = CGFloat(ZPosition.Orb)
        
        resize()
        drawTexture()
        setupPhyisicsBody()
        
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { (_) in
            self.move()
        }
        
    }
    
}

extension OrbNode {
    
    func resize() {
        if self.team == .blue {
            self.size = CGSize(width: radius * 2, height: radius * 2)
        } else if self.team == .red {
            self.size = CGSize(width: radius * 2 * 1.15, height: radius * 2 * 1.15)
        }
        setupPhyisicsBody()
    }
    
    //MARK: Physics Body
    func setupPhyisicsBody() {
        let body = SKPhysicsBody(circleOfRadius: radius)
        
        body.isDynamic = true
        body.categoryBitMask = PhysicsCategory.Orb
        body.contactTestBitMask = PhysicsCategory.Player | PhysicsCategory.Orb | PhysicsCategory.Background
        body.collisionBitMask = PhysicsCategory.None
        self.physicsBody = body
    }
    
    func drawTexture() {
        let texture = SKTexture(imageNamed: self.team.orbTextureName())
        self.texture = texture
        
        // Add a border depending on the effects
        if effects.contains(.invulnerable){
            let borderShapeNode = SKShapeNode(circleOfRadius: self.radius)
            borderShapeNode.name = "effectBorderNode"
            borderShapeNode.lineWidth = 3
            borderShapeNode.strokeColor = Effect.invulnerable.effectColor()
            borderShapeNode.fillColor = .clear
            self.addChild(borderShapeNode)
        } else {
            if let effectBorder = self.childNode(withName: "effectBorderNode") {
                effectBorder.removeFromParent()
            }
        }
    }
    
    // Move towards target direction
    func move() {
        
        guard let destination = self.destination else {
            return
        }
        
        let dx = destination.x - position.x
        let dy = destination.y - position.y
        
        let distance = sqrt(dx*dx + dy*dy)
        
        // Orb is faster when further from the destination but is capped at double the speed
        var speed = orbSpeed * distance / 35
        if speed > orbSpeed * 3 {
            speed = orbSpeed * 3
        }
        
        // Prevent flicking with high speeds
        if (distance < orbSpeed) {
            speed = distance
        }
        
        let angle = atan2(dy, dx)
        
        let vx = cos(angle) * speed
        let vy = sin(angle) * speed
        
        position.x += vx
        position.y += vy
    }
    
}

