//
//  SpeedUpgradePowerUp.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/19/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit

class SpeedUpgradePowerUp: PowerUpProtocol {
    
    var textureName: String = "SpeedUpgradePowerUp"
    var message: String = "Speed UP"
    
    var speedIncrease: CGFloat = 5
    
    func affect(_ player: PlayerNode) {
        player.mobilityModifier += speedIncrease
    }
}
