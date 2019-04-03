//
//  TeleportAbility.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit
import SpriteKit

class TeleportAbility: ActiveAbilityProtocol {
    
    weak var player: PlayerNode!
    
    var tier: AbilityTier = .normal
    
    var iconName: String = "TeleportIcon"
    
    var cooldown: TimeInterval = 10
    var cooldownTimer: Timer = Timer()
    var isOnCooldown: Bool = false
    
    func active() {
        
        if player.isUnder([.stunning]) {
            return
        }
        
        if !isOnCooldown {
            
            let travelDistance = PlayerNode.lowerBoundRadius * 5 * 6
            
            let angle = atan2(player.movingDirection.y, player.movingDirection.x)
            
            let dy = travelDistance * sin(angle)
            let dx = travelDistance * cos(angle)
            
            let newX = player.position.x + dx
            let newY = player.position.y + dy
            
            // Ensure screen bounds
            let screenSize = UIScreen.main.bounds.size
            if (newX >= player.size.width/2 - screenSize.width/2 && newX <= screenSize.width/2 - player.size.width/2) {
                player.position.x = newX
            } else {
                if newX < player.size.width/2 - screenSize.width/2 {
                    player.position.x = player.size.width/2 - screenSize.width/2
                } else {
                    player.position.x = screenSize.width/2 - player.size.width/2
                }
            }
            
            if (newY >= player.size.height/2 - screenSize.height/2 && newY <= screenSize.height/2 - player.size.height/2) {
                player.position.y = newY
            } else {
                if newY < player.size.height/2 - screenSize.height/2 {
                    player.position.y = player.size.height/2 - screenSize.height/2
                } else {
                    player.position.y = screenSize.height/2 - player.size.height/2
                }
            }
            
            // Make player's orbs invulnerable for a little while
            for orb in player.orbs {
                orb.effects.append(.invulnerable)
            }
            let waitAction = SKAction.wait(forDuration: 0.5)
            let removeInvulnerabilityAction = SKAction.run {
                for orb in self.player.orbs {
                    orb.effects.removeElement(.invulnerable)
                }
            }
            self.player.run(.sequence([waitAction, removeInvulnerabilityAction]))
            
            playSoundEffect()
            enterCooldown()
        }
    }
}
