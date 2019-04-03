//
//  AbilityButtonNode.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit
import SpriteKit

// Disabled (only passive)
// Normal
// Toggled
// On cooldown
// Waiting for second activation

enum AbilityButtonType {
    case disabled, normal, toggleable, withDoubleActive
}

enum AbilityButtonState {
    case disabled, normal, toggled, secondActive, onCooldown
}

class AbilityButtonNode: SKSpriteNode {
    
    var ability: AbilityProtocol
    var abilityIconNode: SKSpriteNode
    
    var type: AbilityButtonType = .normal
    var state: AbilityButtonState = .normal {
        didSet {
            self.updateAppearance()
        }
    }
    var cooldownLabel: SKLabelNode!
    
    static var sideLength: CGFloat = 80
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(withAbiity ability: AbilityProtocol) {
        self.ability = ability
        self.abilityIconNode = SKSpriteNode(imageNamed: ability.iconName)
        
        let buttonSize = CGSize(width: AbilityButtonNode.sideLength, height: AbilityButtonNode.sideLength)
        
        // If ability button type should be different than .normal, update it.
        if ability is PassiveAbilityProtocol && !(ability is ActiveAbilityProtocol) {
            self.type = .disabled
        } else if ability is ToggleableAbilityProtocol {
            self.type = .toggleable
        } else if ability is DoubleActiveAbilityProtocol {
            self.type = .withDoubleActive
        }
        
        super.init(texture: nil, color: UIColor.white, size: buttonSize)
        
        // Setup AbilityIconNode
        self.abilityIconNode.size = self.size
        self.abilityIconNode.zPosition = self.zPosition + 1
        self.addChild(abilityIconNode)
        
        self.setupCooldownLabel()
        
        self.updateAppearance()
        
        self.zPosition = ZPosition.InGameUserInterface
        self.isUserInteractionEnabled = true
    }
    
    func enterCooldown() {
        self.state = .onCooldown
        Timer.scheduledTimer(withTimeInterval: ability.cooldown, repeats: false, block: { (_) in
            self.state = .normal
        })
    }
    
    func setupCooldownLabel() {
        self.cooldownLabel = SKLabelNode(text: "\(Int(self.ability.cooldown))")
        cooldownLabel.horizontalAlignmentMode = .center
        cooldownLabel.verticalAlignmentMode = .center
        cooldownLabel.fontSize = 55
        cooldownLabel.fontName = "Dosis ExtraBold"
        cooldownLabel.color = UIColor.white
        
        cooldownLabel.zPosition = self.zPosition + 1
        cooldownLabel.setScale(0)
        addChild(cooldownLabel)
    }
    
    // Depends on type and state
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Need reference to player for when he is stunned, for example.
        guard let player = ability.player else {
            return
        }
        
        switch type {
        case .normal:
            if let ability = self.ability as? ActiveAbilityProtocol {
                if !ability.isOnCooldown && self.state != .disabled {
                    
                    if let managingAbility = self.ability as? OrbManagingAbilityProtocol {
                        
                        let orbCost = managingAbility.orbCost
                        let normalOrbCost = managingAbility.normalOrbCost
                        
                        if player.normalOrbs() >= normalOrbCost && normalOrbCost != 0 {
                            managingAbility.active()
                            enterCooldown()
                        } else if (player.orbs.count >= orbCost && orbCost != 0){
                            managingAbility.active()
                            enterCooldown()
                        }
                    } else {
                        ability.active()
                        
                        enterCooldown()
                    }
                }
            }
        case .toggleable:
            if let ability = self.ability as? ToggleableAbilityProtocol {
                ability.toggle()
                
                if player.isUnder([.stunning]) {
                    return
                }
                
                switch ability.state {
                case .on:
                    self.state = .toggled
                case .off:
                    self.state = .normal
                }
            }
        default:
            break
        }
    }
    
    // Depends only on the state
    func updateAppearance() {
        
        var textureName = ""
        
        switch state {
        case .disabled:
            textureName = "DisabledAbilityButton"
            self.abilityIconNode.alpha = 0.3
            // disabled texture, ability icon opacity 0.3
        case .normal:
            textureName = "NormalAbilityButton"
            self.abilityIconNode.alpha = 1
            // normal texture, ability icon opacity 1
        case .toggled:
            textureName = "ToggledAbilityButton"
            self.abilityIconNode.alpha = 1
            // toggled texture, ability icon opacity 1
        case .secondActive:
            break
        case .onCooldown:
            textureName = "DisabledAbilityButton"
            self.abilityIconNode.alpha = 0.1
            
            // Cooldown animation using normal frame on top
            
            let maskSide = AbilityButtonNode.sideLength
            
            // CropNode
            let rightCropNode = SKCropNode()
            rightCropNode.zPosition = ZPosition.InGameUserInterface
            
            let leftCropNode = SKCropNode()
            leftCropNode.zPosition = ZPosition.InGameUserInterface
            
            // Mask setup
            rightCropNode.maskNode = SKShapeNode.arcShapeNodeWith(maskSide, CGFloat.pi * 2 * 3 / 4, CGFloat.pi * 2, clockwise: false)
            leftCropNode.maskNode = SKShapeNode.arcShapeNodeWith(maskSide, CGFloat.pi * 2 * 3 / 4, CGFloat.pi * 2, clockwise: true)
            
            var rightCurrentAngle: CGFloat = CGFloat.pi * 2 * 3 / 4
            var leftCurrentAngle: CGFloat = CGFloat.pi * 2 * 3 / 4
            let numberOfIterations: CGFloat = 300
            let angleIncrement: CGFloat = CGFloat.pi / numberOfIterations
            
            let waitAction = SKAction.wait(forDuration: TimeInterval(CGFloat(ability.cooldown) / numberOfIterations))
            let scale = SKAction.run {
                rightCurrentAngle += angleIncrement
                leftCurrentAngle -= angleIncrement
                
                rightCropNode.maskNode = SKShapeNode.arcShapeNodeWith(maskSide, CGFloat.pi * 2 * 3 / 4, rightCurrentAngle, clockwise: false)
                leftCropNode.maskNode = SKShapeNode.arcShapeNodeWith(maskSide, CGFloat.pi * 2 * 3 / 4, leftCurrentAngle, clockwise: true)
            }
            
            let repeatAction = SKAction.repeat(.sequence([waitAction, scale]), count: Int(numberOfIterations))
            let removeMaskAction = SKAction.run {
                rightCropNode.removeFromParent()
                leftCropNode.removeFromParent()
            }
            self.run(.sequence([repeatAction, removeMaskAction]))
            
            // Content setup
            let borderTexture = SKSpriteNode(imageNamed: "NormalAbilityButtonBorder")
            let borderTexture2 = SKSpriteNode(imageNamed: "NormalAbilityButtonBorder")
            
            rightCropNode.addChild(borderTexture)
            leftCropNode.addChild(borderTexture2)
            
            self.addChild(rightCropNode)
            self.addChild(leftCropNode)
        
            
            // If the abilities cooldown is greater than 1, show cooldown label
            if ability.cooldown >= 1 {
                
                let growAction = SKAction.scale(to: 1, duration: 0.2)
                self.cooldownLabel.run(growAction)
                
                self.cooldownLabel.text = "\(Int(ability.cooldown))"
                
                let fadeInAction = SKAction.fadeAlpha(to: 1, duration: 0.1)
                let waitAction = SKAction.wait(forDuration: 0.8)
                let fadeOutAction = SKAction.fadeAlpha(to: 0, duration: 0.1)
                
                let waitSequence = SKAction.sequence([fadeInAction, waitAction, fadeOutAction])
                
                let decrementAction = SKAction.customAction(withDuration: 0, actionBlock: { (_, _) in
                    if let currentNumber = Int(self.cooldownLabel.text!) {
                        if currentNumber > 1 {
                            self.cooldownLabel.text = "\(currentNumber - 1)"
                        } else {
                            let shrinkAction = SKAction.scale(to: 0, duration: 0.2)
                            self.cooldownLabel.run(shrinkAction)
                        }
                    }
                })
                
                let decrementSequence = SKAction.sequence([waitSequence, decrementAction])
                
                let repeatDecrementAction = SKAction.repeat(decrementSequence, count: Int(ceil(ability.cooldown)))
                self.cooldownLabel.run(repeatDecrementAction)
            }
        }
        
        self.texture = SKTexture(imageNamed: textureName)
    }
    
}
