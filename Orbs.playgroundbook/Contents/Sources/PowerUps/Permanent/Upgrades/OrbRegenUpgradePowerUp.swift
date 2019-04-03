//
//  OrbRegenUpgradePowerUp.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/16/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation

class OrbRegenUpgradePowerUp: PowerUpProtocol {
    
    var textureName: String = "OrbRegenUpgradePowerUp"
    var message: String = "Orb Regen UP"
    
    var orbRegenIntervalDecrease: Double = 10
    
    func affect(_ player: PlayerNode) {
        player.orbSpawingModifier += orbRegenIntervalDecrease
    }
}
