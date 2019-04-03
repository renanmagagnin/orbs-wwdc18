//
//  ChangeStanceAbility.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation

class ChangeStanceAbility: ToggleableAbilityProtocol {
    
    var stance: StanceProtocol!
    
    weak var player: PlayerNode!
    var iconName: String
    var tier: AbilityTier = .normal
    
    var cooldown: TimeInterval = 1.5
    var cooldownTimer: Timer = Timer()
    var isOnCooldown: Bool = false
    
    var state: ToggleableAbilityState = .off
    
    func toggle() {
        
        if player.isUnder([.stunning]) {
            return
        }
        
        switch state {
        case .on:
            player.stance.removePassives()
            
            player.stance = PlayerNode.defaultStance
            player.stance.player = player               // Hook up the stance to the player
            
            state = .off
        case .off:
            player.stance = stance
            
            player.stance.applyPassives()
            playSoundEffect()
            
            state = .on
        }
        
    }
    
    init(withStance stance: StanceProtocol) {
        self.stance = stance
        self.iconName = stance.iconName
    }
}
