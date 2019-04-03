//
//  AbilityProtocol.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation
import SpriteKit

enum AbilityTier {
    case normal
    case ultimate   // Higher orb cost and cooldown and only one per loadout
}

protocol AbilityProtocol: class {
    weak var player: PlayerNode! { get set }
    
    var iconName: String { get set }
    
    var tier: AbilityTier { get set }
    
    var cooldown: TimeInterval { get set }
    var cooldownTimer: Timer { get set }
    var isOnCooldown: Bool { get set }
    
    func enterCooldown()
    func reset()
}

extension AbilityProtocol {
    func enterCooldown() {
        self.isOnCooldown = true
        self.cooldownTimer = Timer.scheduledTimer(withTimeInterval: cooldown, repeats: false) { [weak self] (_) in
            self?.isOnCooldown = false
        }
    }
    
    func reset() {
        self.isOnCooldown = false
        cooldownTimer.invalidate()
    }
    
    func playSoundEffect() {
        let playSoundEffectAction = SKAction.playSoundFileNamed(self.iconName, waitForCompletion: false)
        if let player = self.player, let scene = player.scene {
            scene.run(playSoundEffectAction)
        }
    }
}

protocol PassiveAbilityProtocol: AbilityProtocol {
    func passive()
}

protocol ActiveAbilityProtocol: AbilityProtocol {
    func active()
}

protocol OrbManagingAbilityProtocol: ActiveAbilityProtocol {
    var orbCost: Int { get set }
    var normalOrbCost: Int { get set }
}

protocol DoubleActiveAbilityProtocol: ActiveAbilityProtocol {
    func secondActive()
}

enum ToggleableAbilityState {
    case on, off
}
protocol ToggleableAbilityProtocol: AbilityProtocol {
    var state: ToggleableAbilityState { get set }
    func toggle()
}

