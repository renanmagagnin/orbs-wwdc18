//
//  MenuScene.swift
//  Orbs
//
//  Created by Renan Magagnin on 3/17/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit
import GameplayKit

public class MenuScene: SKScene {
    
    var backgroundNode = SKSpriteNode(texture: SKTexture.init(imageNamed: "BackgroundGradient"), color: UIColor.clear, size: CGSize.zero)
    
    let gameScene = GameScene(size: UIScreen.main.bounds.size)
    
    var logo: SKSpriteNode = SKSpriteNode()
    var tapToPlay: SKSpriteNode = SKSpriteNode()
    
    public override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Wait for a little while before detecting tap to start
        self.view?.isUserInteractionEnabled = false
        let waitAction = SKAction.wait(forDuration: 2)
        let enableUserInteractionAction = SKAction.run {
            self.view?.isUserInteractionEnabled = true
        }
        self.run(.sequence([waitAction, enableUserInteractionAction]))
        
        setupLogo()
        setupTapToPlay()
        
        setupBackground()
        setupStars()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Sound effect
        let playSoundAction = SKAction.playSoundFileNamed("MenuSelect", waitForCompletion: false)
        self.run(playSoundAction)
        
        // Animation
        let shrinkAction = SKAction.scale(to: 0.7, duration: 0.15)
        let growAction = SKAction.scale(to: 1.2, duration: 0.15)
        let goBackToNormalAction = SKAction.scale(to: 1, duration: 0.15)
        
        // Handling
        let transitionAction = SKAction.run {
            self.gameScene.scaleMode = .aspectFit
            let transition = SKTransition.fade(withDuration: 0.5)
            if let view = self.view {
                view.presentScene(self.gameScene, transition: transition)
            }
        }
        
        if logo.action(forKey: "Transition") == nil && tapToPlay.action(forKey: "Transition") == nil {
            tapToPlay.run(.sequence([shrinkAction, growAction, goBackToNormalAction]), withKey: "Transition")
            logo.run(.sequence([shrinkAction, growAction, goBackToNormalAction]), withKey: "Transition")
            
            let waitAction = SKAction.wait(forDuration: 0.45)
            self.run(.sequence([waitAction, transitionAction]))
        }
    }
}

// delay on touch when menu screen
// action animate is easy
// constraints relative to scene size

// MARK: UI Elements
extension MenuScene {
    func setupLogo() {
        logo = SKSpriteNode(imageNamed: "OrbsLogo")
        logo.zPosition = ZPosition.MenuUserInterface + 5
        logo.position = CGPoint(x: 0, y: +self.frame.size.height * 0.19 - logo.frame.height / 2)
        addChild(logo)
        logo.setScale(0)
        
        let waitAction = SKAction.wait(forDuration: 0.5)
        let scaleUpAction = SKAction.scale(to: 1, duration: 0.5)
        logo.run(.sequence([waitAction, scaleUpAction]))
    }
    
    func setupTapToPlay() {
        tapToPlay = SKSpriteNode(imageNamed: "TapToPlay")
        tapToPlay.zPosition = ZPosition.MenuUserInterface + 5
        tapToPlay.position = CGPoint(x: 0, y: -self.frame.size.height * 0.19 + tapToPlay.frame.height / 2)
        addChild(tapToPlay)
        tapToPlay.setScale(0)
        
        let waitAction = SKAction.wait(forDuration: 1)
        let scaleUpAction = SKAction.scale(to: 1, duration: 0.5)
        
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.8)
        let fadeInAction = SKAction.fadeIn(withDuration: 0.8)
        let blinkAction = SKAction.repeatForever(.sequence([fadeOutAction, fadeInAction]))
        
        tapToPlay.run(.sequence([waitAction, scaleUpAction, blinkAction]))
    }
}

// MARK: Background
extension MenuScene {
    func setupBackground() {
        self.backgroundNode.size = self.size
        self.backgroundNode.zPosition = ZPosition.Background
        self.backgroundNode.name = "background"
        self.addChild(backgroundNode)
    }
    
    func setupStars() {
        if let foregroundParticleEmitter = SKEmitterNode(fileNamed: "ForegroundStars.sks") {
            foregroundParticleEmitter.particlePositionRange = CGVector(dx: self.frame.size.width, dy: self.frame.size.height)
            foregroundParticleEmitter.zPosition = ZPosition.Background + 2
            foregroundParticleEmitter.targetNode = self
            self.addChild(foregroundParticleEmitter)
        }
        
        if let backgroundParticleEmitter = SKEmitterNode(fileNamed: "BackgroundStars.sks") {
            backgroundParticleEmitter.particlePositionRange = CGVector(dx: self.frame.size.width, dy: self.frame.size.height)
            backgroundParticleEmitter.zPosition = ZPosition.Background + 1
            backgroundParticleEmitter.targetNode = self
            self.addChild(backgroundParticleEmitter)
            
            // Boost birth rate for a short period of time
            let defaultBirthRate = backgroundParticleEmitter.particleBirthRate
            backgroundParticleEmitter.particleBirthRate *= 40
            
            let waitAction = SKAction.wait(forDuration: 0.05)
            let restoreBirthRate = SKAction.run {
                backgroundParticleEmitter.particleBirthRate = defaultBirthRate
            }
            backgroundParticleEmitter.run(.sequence([waitAction, restoreBirthRate]))
        }
    }
    
    func setupBlur() {
        let blurNode = SKEffectNode()
        blurNode.shouldEnableEffects = true
        if let blur = CIFilter(name: "CIGaussianBlur") {
            blur.setValue(3, forKey: kCIInputRadiusKey)
            blurNode.filter = blur
        }
        addChild(blurNode)
    }
}
