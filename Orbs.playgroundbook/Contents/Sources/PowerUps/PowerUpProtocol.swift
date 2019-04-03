//
//  PowerUpProtocol.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/16/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

// Affect the player instantaneously, for example: heal for 20, give player 5 orbs, etc.
//* Permanent buffs: healing, increase dmg, max orbs, give orbs, orb regen.
protocol PowerUpProtocol {
    var textureName: String { get }
    var message: String { get }
    
    func affect(_ player: PlayerNode)
}

// Starts affecting the player on contact and keeps
//Temporary: double damage, double orb regen, speed.
protocol TemporaryPowerUpProtocol: PowerUpProtocol {
    var duration: TimeInterval { get }
    func removeEffect(from player: PlayerNode)
}



