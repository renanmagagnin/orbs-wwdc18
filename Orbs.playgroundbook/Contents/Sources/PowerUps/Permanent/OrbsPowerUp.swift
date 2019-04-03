//
//  OrbsPickupNode.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/16/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

class OrbsPowerUp: PowerUpProtocol {
    
    var textureName: String = "OrbsPowerUp"
    var message: String = "Orbs +5"
    
    var amountOfOrbs: Int = 5
    
    func affect(_ player: PlayerNode) {
        guard let gameScene = player.scene as? GameScene else { return }
        
        let newAmountOfOrbs = player.orbs.count + amountOfOrbs
        
        if newAmountOfOrbs > player.maxOrbs {
            player.maxOrbs = newAmountOfOrbs
            gameScene.spawnOrbs(for: player, withEffects: [], amount: amountOfOrbs)
        } else {
            gameScene.spawnOrbs(for: player, withEffects: [], amount: amountOfOrbs)
        }
    }
}


