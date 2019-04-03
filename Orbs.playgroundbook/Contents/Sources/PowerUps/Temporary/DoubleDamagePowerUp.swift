//
//  DoubleDamagePowerUp.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/17/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation
import SpriteKit

class DoubleDamagePowerUp: TemporaryPowerUpProtocol {
    
    var textureName: String = "DoubleDamagePowerUp"
    var message: String = "DOUBLE DAMAGE"
    
    var duration: TimeInterval = 2
    
    func affect(_ player: PlayerNode) {
        // Add visual effect to player
        player.damageModifier += 100
        
        let waitAction = SKAction.wait(forDuration: duration)
        let removePowerUpAction = SKAction.customAction(withDuration: 0) { (_, _) in
            self.removeEffect(from: player)
        }
        
        if player.action(forKey: "doubleDamagePowerUp") != nil {
            self.removeEffect(from: player)
        }
        
        let durationAction = SKAction.sequence([waitAction, removePowerUpAction])
        player.run(durationAction, withKey: "doubleDamagePowerUp")
    }
    
    func removeEffect(from player: PlayerNode) {
        // Remove visual effect from player
        player.damageModifier -= 100
    }
}

