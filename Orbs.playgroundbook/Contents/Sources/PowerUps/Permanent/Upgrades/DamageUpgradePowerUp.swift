//
//  DamageUpgradePowerUp.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/16/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation

class DamageUpgradePowerUp: PowerUpProtocol {
    
    var textureName: String = "DamageUpgradePowerUp"
    var message: String = "Damage UP"
    
    var damageIncrease = 5
    
    func affect(_ player: PlayerNode) {
        player.damageModifier += damageIncrease
    }
}
