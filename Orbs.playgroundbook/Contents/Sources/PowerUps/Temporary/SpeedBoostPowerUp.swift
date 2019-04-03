//
//  SpeedBoostPowerUp.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/17/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

class SpeedBoostPowerUp: TemporaryPowerUpProtocol {
    
    var textureName: String = "SpeedBoostPowerUp"
    var message: String = "SPEED BOOST"
    
    var duration: TimeInterval = 3
    
    func affect(_ player: PlayerNode) {
        // Add visual effect to player
        player.mobilityModifier += 30
        
        let waitAction = SKAction.wait(forDuration: duration)
        let removePowerUpAction = SKAction.customAction(withDuration: 0) { (_, _) in
            self.removeEffect(from: player)
        }
        
        if player.action(forKey: "speedBoostPowerUp") != nil {
            self.removeEffect(from: player)
        }
        
        let durationAction = SKAction.sequence([waitAction, removePowerUpAction])
        player.run(durationAction, withKey: "speedBoostPowerUp")
    }
    
    func removeEffect(from player: PlayerNode) {
        // Remove visual effect from player
        player.mobilityModifier -= 30
    }
}
