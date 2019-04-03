//
//  PowerUpNode.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/16/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

class PowerUpNode: SKSpriteNode {
    
    static var pickUpSize: CGSize {
        return CGSize(width: 38, height: 38)
    }
    
    var powerUp: PowerUpProtocol!
    
    init(withPowerUp powerUp: PowerUpProtocol) {
        
        self.powerUp = powerUp
        
        super.init(texture: nil, color: UIColor.white, size: PowerUpNode.pickUpSize)
        
        self.zPosition = ZPosition.Pickup
        setupPhyisicsBody()
        setupTexture()
        
        
        let waitAction = SKAction.wait(forDuration: 0.7)
        
        let growAction = SKAction.scale(to: 1.3, duration: 2)
        let shrinkAction = SKAction.scale(to: 1, duration: 2)
        let pulsateAction = SKAction.sequence([growAction, shrinkAction])
        let repeatForeverAction = SKAction.repeatForever(pulsateAction)
        
        let initialSequence = SKAction.sequence([waitAction, repeatForeverAction])
        
        self.run(initialSequence, withKey: "pulsateForeverAction")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PowerUpNode {
    //MARK: Physics Body
    func setupPhyisicsBody() {
        let body = SKPhysicsBody(rectangleOf: PowerUpNode.pickUpSize * 0.5) // slightly smaller to look like the player is absorbing it
        
        body.isDynamic = true
        body.categoryBitMask = PhysicsCategory.Pickup
        body.contactTestBitMask = PhysicsCategory.Player
        body.collisionBitMask = PhysicsCategory.None
        self.physicsBody = body
    }
    
    func setupTexture() {
        let texture = SKTexture(imageNamed: self.powerUp.textureName)
        self.texture = texture
    }
}
