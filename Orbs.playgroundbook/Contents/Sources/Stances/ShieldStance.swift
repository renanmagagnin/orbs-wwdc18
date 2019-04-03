//
//  ShieldStance.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit
import SpriteKit

class ShieldStance: StanceProtocol {
    
    weak var player: PlayerNode!
    
    var iconName: String = "ShieldIcon"
    
    // 50% slow
    let movementModifier: CGFloat = 50
    
    func applyPassives() {
        player.mobilityModifier -= movementModifier
    }
    
    func removePassives() {
        player.mobilityModifier += movementModifier
    }
    
    func positionOrbs() {
        
        if player.isUnder([.stunning]) {
            return
        }
        
        let orbs = player.orbs
        if orbs.isEmpty {
            return
        }
        
        player.referenceAngle = atan2(player.closeAim.y, player.closeAim.x)
        
        var relativeAngle: CGFloat = 0
        let angleSpacing: CGFloat = (player.radius > 30) ? CGFloat.pi / 18 : CGFloat.pi / 10
        let orbLayerRadius = (player.radius * 2) >= 60 ? player.radius * 2 : 60
        let orbLayersSpacing = player.radius / 2 >= 30/2 ? player.radius / 2 : 30/2
        
        for orb in orbs {
            let orbIndex = CGFloat(orbs.index(of: orb)!)
            let orbLayer = floor(orbIndex / CGFloat(player.orbsPerLayer)) // Layer the orb belongs to, the innermost being 0.
            
            let radius = CGFloat(orbLayerRadius + (orbLayer * orbLayersSpacing))
            
            if orbIndex > 1 && orbIndex.truncatingRemainder(dividingBy: CGFloat(player.orbsPerLayer)) == 0 {
                relativeAngle = 0
            }
            
            let orbAngle = player.referenceAngle + relativeAngle
            
            let dx = radius * cos(orbAngle)
            let dy = radius * sin(orbAngle)
            
            let dest = CGPoint(x: player.position.x + dx, y: player.position.y + dy)
            orb.destination = dest
            
            if orbIndex.truncatingRemainder(dividingBy: 2) == 0 {
                relativeAngle += angleSpacing
            }
            
            relativeAngle = -relativeAngle
            
            // Rotate the orb radially
            let normalVector = orb.position - self.player.position
            let normalVectorAngle = atan2(normalVector.y, normalVector.x) - CGFloat.pi/2
            orb.zRotation = normalVectorAngle
            
            // If orb is stretched, unstretch it.
            if orb.xScale != 1 || orb.yScale != 1 {
                let unstretchAction = SKAction.scaleX(to: 1, y: 1, duration: 0.3)
                orb.run(unstretchAction)
            }
            
            // Is dealing double damage
            if player.damageModifier >= 100 {
                if orb.childNode(withName: "DoubleDamageFire") == nil {
                    if let fireParticleEmitter = SKEmitterNode(fileNamed: "DoubleDamage.sks") {
                        fireParticleEmitter.name = "DoubleDamageFire"
                        fireParticleEmitter.particlePositionRange = CGVector(dx: orb.frame.size.width/2, dy: orb.frame.size.height/2)
                        orb.addChild(fireParticleEmitter)
                    }
                }
            } else {
                if let doubleDamageFire = orb.childNode(withName: "DoubleDamageFire") {
                    doubleDamageFire.removeFromParent()
                }
            }
            
        }
    }
}
