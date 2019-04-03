//
//  HealingPickup.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/16/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

class HealingPowerUp: PowerUpProtocol {
    
    var textureName: String = "HealingPowerUp"
    var message: String = "Health +20"
    
    var healingAmount = 20
    
    func affect(_ player: PlayerNode) {
        
        
        // Increase player max health if needed
        let newHealth = player.health + healingAmount
        if newHealth > player.maxHealth {
            player.maxHealth = newHealth
            player.health = newHealth
        } else {
            player.health = newHealth
        }
        
        
        // If player is outside the screen after getting healed, put him back inside.
        guard let scene = player.scene else {
            return
        }
        let size = player.size
        let screenSize = scene.frame.size
        
        if player.position.x > screenSize.width/2 - size.width/2 {
            player.position.x = screenSize.width/2 - size.width/2
        } else if player.position.x < size.width/2 - screenSize.width/2 {
            player.position.x = size.width/2 - screenSize.width/2
        }
        
        if player.position.y > screenSize.height/2 - size.height/2 {
            player.position.y = screenSize.height/2 - size.height/2
        } else if player.position.y < size.height/2 - screenSize.height/2 {
            player.position.y = size.height/2 - screenSize.height/2
        }
    }
}
