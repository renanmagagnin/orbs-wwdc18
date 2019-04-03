//
//  CombineOrbsAbility.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/15/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation

class CombineOrbsAbility: OrbManagingAbilityProtocol {
    
    var iconName: String = "combine"
    
    weak var player: PlayerNode!
    
    var tier: AbilityTier = .normal
    
    var cooldown: TimeInterval = 1
    var cooldownTimer: Timer = Timer()
    var isOnCooldown: Bool = false
    
    
    // Number of orbs to be combined
    var orbCost: Int = 2
    var normalOrbCost: Int = 0
    
    // This should have a limit to the size of the receiver orb.
    // When the last reaches the max size, use the one before the last as receiver.
    // The hard part should be disabling the ability button
    
    func active() {
        
        if player.isUnder([.stunning]) {
            return
        }
        
        if !isOnCooldown {
            
            if player.orbs.count < orbCost {
                return
            }
            
            var timer: Timer = Timer()
            guard var lastOrb = player.orbs.last else { return }
            
            // If the resulting orb is getting too big, do it with the previous, making sure it's possible.
            if lastOrb.radius >= OrbNode.defaultRadius * 5 {
                let newLastOrbIndex = player.orbs.index(of: lastOrb)! - 1
                
                if let newLastOrb = player.orbs[safe: newLastOrbIndex],
                    let _ = player.orbs[safe: newLastOrbIndex - 1] {
                    lastOrb = newLastOrb
                }
            }
            
            
            let loops = orbCost - 1
            
            for _ in 0..<loops {
                
                // Get an orb, increase its speed and set it free from the player.
                let currentOrbIndex = player.orbs.index(of: lastOrb)! - 1
                guard let currentOrb = player.orbs[safe: currentOrbIndex] else { return }
                currentOrb.orbSpeed *= 2
                player.orbs.removeElement(currentOrb)
                
                
                timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true, block: { (_) in
                    
                    currentOrb.destination = lastOrb.position
                    
                    let distance = (lastOrb.position - currentOrb.position).length()
                    
                    // When the two orbs are close enough, combine them.
                    if distance < lastOrb.radius * 1.7 {
                        
                        lastOrb.radius += currentOrb.radius
                        lastOrb.effects += currentOrb.effects
                        
                        currentOrb.removeFromParent()
                        
                        timer.invalidate()
                    }
                })
            }
            
            playSoundEffect()
            enterCooldown()
        }
    }
}
