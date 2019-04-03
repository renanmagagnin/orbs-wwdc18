//
//  UltimateShootAbility.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation

class UltimateShootAbility: ActiveAbilityProtocol {
    
    weak var player: PlayerNode!
    
    var tier: AbilityTier = .ultimate
    
    var iconName: String = "UltimateShootIcon"
    
    var cooldown: TimeInterval = 10
    var cooldownTimer: Timer = Timer()
    var isOnCooldown: Bool = false
    
    func active() {
        
        if player.isUnder([.stunning]) {
            return
        }
        
        guard let scene = player.scene as? GameScene, let enemy = scene.closestEnemyPlayerTo(player) else {
            return
        }
        
        if !isOnCooldown {
            
            player.orbs.forEach { (_) in
                player.shootOrb(towardsPlayer: enemy)
            }
            
            playSoundEffect()
            enterCooldown()
        }
    }
}

