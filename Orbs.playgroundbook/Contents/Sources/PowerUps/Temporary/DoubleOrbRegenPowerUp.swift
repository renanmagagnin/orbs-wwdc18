//
//  DoubleOrbRegenPowerUp.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/17/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

class DoubleOrbRegenPowerUp: TemporaryPowerUpProtocol {
    
    var textureName: String = "DoubleOrbRegenPowerUp"
    var message: String = "DOUBLE ORB REGEN"
    
    var duration: TimeInterval = 2
    
    func affect(_ player: PlayerNode) {
        // Add visual effect to player
        player.orbSpawingModifier += 50
        
        let waitAction = SKAction.wait(forDuration: duration)
        let removePowerUpAction = SKAction.customAction(withDuration: 0) { (_, _) in
            self.removeEffect(from: player)
        }
        
        if player.action(forKey: "doubleOrbRegenPowerUp") != nil {
            self.removeEffect(from: player)
        }
        
        let durationAction = SKAction.sequence([waitAction, removePowerUpAction])
        player.run(durationAction, withKey: "doubleOrbRegenPowerUp")
        
    }
    
    func removeEffect(from player: PlayerNode) {
        // Remove visual effect from player
        player.orbSpawingModifier -= 50
    }
}
