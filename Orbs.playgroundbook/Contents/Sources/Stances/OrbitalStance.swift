//
//  OrbitalStance.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit
import SpriteKit

class OrbitalStance: StanceProtocol {
    
    weak var player: PlayerNode!
    
    var iconName: String = "OrbitalIcon"
    
    func applyPassives() { }
    func removePassives() { }
    
    func positionOrbs() {
        
        if player.isUnder([.stunning]) {
            return
        }
        
        let orbs = player.orbs
        
        if orbs.isEmpty {
            return
        }
        
        // Spacing between layers of orbs
        let orbLayersSpacing = player.radius >= 25 ? player.radius : 25
        let orbLayerRadius = (player.radius * 2) >= 50 ? player.radius * 2 : 50
        
        // Angle between different orbs, inversely proportional to the number of orbs.
        var angleSpacing = (orbs.count <= player.orbsPerLayer) ? CGFloat(2 * Double.pi / Double(orbs.count)) : CGFloat(2 * Double.pi / Double(player.orbsPerLayer))
        
        for orb in orbs {
            
            let orbIndex = CGFloat(orbs.index(of: orb)!)
            
            // Recalculate angleSpacing every new layer
            
            if (orbIndex.truncatingRemainder(dividingBy: CGFloat(player.orbsPerLayer)) == 0) {
                let count = orbs[Int(orbIndex)...].count
                angleSpacing = (count <= player.orbsPerLayer) ? CGFloat(2 * Double.pi / Double(count)) : CGFloat(2 * Double.pi / Double(player.orbsPerLayer))
            }
            
            // Layer the orb belongs to, the innermost being 0.
            let orbLayer = floor(orbIndex / CGFloat(player.orbsPerLayer))
            
            let orbAngle = (player.referenceAngle + angleSpacing * orbIndex).truncatingRemainder(dividingBy: CGFloat(2 * Double.pi))
            
            var radius = CGFloat(orbLayerRadius + (orbLayer * orbLayersSpacing))
            
            // Pulsing effect
            radius *= (1 + sin(player.referenceAngle) / 20)
            
            var dx = radius
            var dy = radius
            
            if(orbLayer.truncatingRemainder(dividingBy: 2) == 0) {
                dx *= sin(orbAngle)
                dy *= cos(orbAngle)
            } else {
                dx *= sin(orbAngle + angleSpacing / 2)
                dy *= cos(orbAngle + angleSpacing / 2)
            }
            
            let dest = CGPoint(x: player.position.x + dx, y: player.position.y + dy)
            orb.destination = dest
            
            
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
        
        player.referenceAngle += player.orbsAngularSpeed
    }
    
}
