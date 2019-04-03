//
//  MaxOrbsUpgradePowerUp.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/17/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import Foundation

class MaxOrbsUpgradePowerUp: PowerUpProtocol {
    
    var textureName: String = "MaxOrbsUpgradePowerUp"
    var message: String = "Max Orbs +2"
    
    var maxOrbsIncrease = 2
    
    func affect(_ player: PlayerNode) {
        player.maxOrbs += maxOrbsIncrease
    }
}
