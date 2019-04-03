//
//  ShootAbility.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation

class ShootAbility: ActiveAbilityProtocol, PassiveAbilityProtocol {
    
    var iconName: String = "ShootIcon"
    
    weak var player: PlayerNode!
    
    var tier: AbilityTier = .normal
    
    var cooldown: TimeInterval = 0.5
    var cooldownTimer: Timer = Timer()
    var isOnCooldown: Bool = false
    
    func passive() {
        
    }
    
    func active() {
        
        if player.isUnder([.stunning]) {
            return
        }
        
        if !isOnCooldown {
            player.shootOrb(towards: player.aim)
            
            playSoundEffect()
            enterCooldown()
        }
    }
}

