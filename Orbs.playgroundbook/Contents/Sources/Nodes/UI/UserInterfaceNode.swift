//
//  UserInterfaceNode.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

protocol UserInterfaceDelegate: class {
    var bottomJoystickClosure: ((_ data: AnalogJoystickData) -> ())? { get }
    
    func menuButtonPressed()
    func tryAgainButtonPressed()
}

class UserInterfaceNode: SKNode {
    
    var size: CGSize
    
    weak var delegate: UserInterfaceDelegate?
    
    // Analog Sticks
    static var analogStickDiameter: CGFloat = 150
    var bottomJoystick: AnalogJoystick!
    
    
    // Ability Buttons
    var bottomPlayerAbilityButtons: [AbilityButtonNode] = []

    var spawnerIndicators: [SKSpriteNode] = []
    
    // SpriteNode used to separate the game screen from the victory and death menus.
    var darknessNode: SKSpriteNode!
    var fireWorksPlayer: AVAudioPlayer!
    
    func setup() {
        self.setupAnalogSticks()
    }
    
    init(withSize size: CGSize) {
        
        self.size = size
        
        super.init()
        
        self.isUserInteractionEnabled = true
    
        self.setupDarknessNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: Analog Sticks
extension UserInterfaceNode {
    func setupAnalogSticks() {
        
        let joystickRadius = UserInterfaceNode.analogStickDiameter/2
        let joystickMargin = UserInterfaceNode.analogStickDiameter * 80 / 150
        
        let innerJoystickImage = UIImage(named: "Analog Stick")
        let outerJoystickImage = UIImage(named: "Analog Stick Background")
        
        self.bottomJoystick = AnalogJoystick(diameter: UserInterfaceNode.analogStickDiameter, colors: (Team.blue.playerColor(), UIColor.white), images: (outerJoystickImage, innerJoystickImage))
        
        let bottomJoystickX = -size.width/2 + joystickRadius + joystickMargin
        let bottomJoystickY = -size.height/2 + joystickRadius + joystickMargin
        bottomJoystick.position = CGPoint(x: bottomJoystickX, y: bottomJoystickY)
        bottomJoystick.zPosition = ZPosition.InGameUserInterface
        addChild(bottomJoystick)
        
        //MARK: Handlers begin
        bottomJoystick.trackingHandler = delegate?.bottomJoystickClosure
        
        // Analog Stick entrance
        bottomJoystick.alpha = 0
        let moveBackAction = SKAction.fadeIn(withDuration: 0.5)
        moveBackAction.timingMode = .easeOut
        bottomJoystick.run(moveBackAction)
    }
}


// MARK: Ability Bars
extension UserInterfaceNode {
    
    func setupAbilityBar(withAbilities abilities: [AbilityProtocol]) {
        let buttonSize = CGSize(width: AbilityButtonNode.sideLength, height: AbilityButtonNode.sideLength)
        let buttonSpacing: CGFloat = buttonSize.width * 10 / 110 / 2
        let buttonMargin: CGFloat = 0
 
        let lastAbilityButtonX = self.size.width/2 - buttonSize.width/2 - buttonMargin
        let abilityButtonsY = -self.size.height / 2 + buttonSize.height * 3 / 4
        var abilityButtons = self.bottomPlayerAbilityButtons
        
        // Empty ability buttons list
        for button in abilityButtons {
            button.removeFromParent()
            abilityButtons.removeElement(button)
        }
        
        // Construct ability of buttons based on abilities
        for index in 0..<abilities.count {
            let ability = abilities[index]
            
            let newAbilityButton = AbilityButtonNode(withAbiity: ability)
            
            let offsetMultiplier = CGFloat(index - abilities.count + 1)
            let x = lastAbilityButtonX + buttonSize.width * offsetMultiplier + buttonSpacing * offsetMultiplier
            newAbilityButton.position = CGPoint(x: x, y: abilityButtonsY)
            abilityButtons.append(newAbilityButton)
            addChild(newAbilityButton)
        }
        
        // Update list of ability buttons
        self.bottomPlayerAbilityButtons = abilityButtons
        
        // Animate ability bar entrance
        let yOffset = AbilityButtonNode.sideLength * 2
        for button in abilityButtons {
            let moveAwayAction = SKAction.run {
                button.position.y -= yOffset
            }
            let moveBackAction = SKAction.move(by: CGVector.init(dx: 0, dy: yOffset), duration: 0.5)
            moveAwayAction.timingMode = .easeOut
            
            button.run(.sequence([moveAwayAction, moveBackAction]))
        }
    }
    
}

// MARK: Spawner Indicators Bars
extension UserInterfaceNode {
    
    func setupSpawnerIndicator(for spawnerPosision: SpawnerPosition) {
        
        var textureName = ""
        let position = CGPoint.zero
        switch spawnerPosision {
        case .bottom:
            textureName = "BottomSpawnerIndicator"
        case .top:
            textureName = "TopSpawnerIndicator"
        case .left:
            textureName = "LeftSpawnerIndicator"
        case .right:
            textureName = "RightSpawnerIndicator"
        }
        
        let spawnerIndicator = SKSpriteNode(imageNamed: textureName)
        spawnerIndicator.zPosition = ZPosition.InGameUserInterface
        spawnerIndicator.position = position
        spawnerIndicator.alpha = 0
        self.spawnerIndicators.append(spawnerIndicator)
        self.addChild(spawnerIndicator)
        
        switch spawnerPosision {
        case .bottom:
            spawnerIndicator.position = CGPoint(x: 0, y:  -self.size.height / 2 + spawnerIndicator.size.height / 2)
        case .top:
            spawnerIndicator.position = CGPoint(x: 0, y: self.size.height / 2 - spawnerIndicator.size.height / 2)
        case .left:
            spawnerIndicator.position = CGPoint(x: -self.size.width / 2 + spawnerIndicator.size.width / 2, y: 0)
        case .right:
            spawnerIndicator.position = CGPoint(x: self.size.width / 2 - spawnerIndicator.size.width / 2, y: 0)
        }
        
        // Pulsing
        let fadeInAction = SKAction.fadeAlpha(to: 1, duration: 1.5)
        let fadeOutAction = SKAction.fadeAlpha(to: 0.2, duration: 1.5)
        let pulsingAction = SKAction.repeatForever(.sequence([fadeInAction, fadeOutAction]))
        spawnerIndicator.run(pulsingAction)
    }
    
    func removeSpawnerIndicators() {
        for spawnerIndicator in self.spawnerIndicators {
            let fadeOutAction = SKAction.fadeOut(withDuration: 1)
            spawnerIndicator.run(.sequence([fadeOutAction, .removeFromParent()]))
        }
        spawnerIndicators = []
    }
}

// MARK: Death and Victory Menus
extension UserInterfaceNode {
    
    // TO DO: Add blur
    // Node that separates the game screen from the menus
    func setupDarknessNode() {
        darknessNode = SKSpriteNode(color: .black, size: self.size)
        darknessNode.zPosition = ZPosition.MenuUserInterface + 100
        darknessNode.alpha = 0.7
        darknessNode.isHidden = true
        darknessNode.isUserInteractionEnabled = true
        addChild(darknessNode)
    }
    
    
    // Should be animated in (depressed)
    func setupDeathMenu(withNumberOfWaves numberOfWaves: Int) {
        
        darknessNode.isHidden = false
        
        let buttonMargin: CGFloat = 100
        
        let youDiedTitle = SKSpriteNode(imageNamed: "YouDiedTitle")
        youDiedTitle.zPosition = darknessNode.zPosition + 1
        youDiedTitle.position.y = self.size.height * 0.083 + youDiedTitle.frame.size.height/2
        addChild(youDiedTitle)
        
        let messageLabel = SKLabelNode(withText: "You survived \(numberOfWaves) waves!")
        messageLabel.position = CGPoint.zero
        messageLabel.zPosition = darknessNode.zPosition + 1
        addChild(messageLabel)
        
        let tryAgainButton = SKSpriteNode(imageNamed: "PurpleButton", andText: "TRY AGAIN")
        tryAgainButton.name = "tryAgainButton"
        tryAgainButton.zPosition = darknessNode.zPosition + 1
        tryAgainButton.position.y =  -self.size.height * 0.098 - tryAgainButton.frame.size.height/2

        addChild(tryAgainButton)
        
        let purpleMenuButton = SKSpriteNode(imageNamed: "PurpleButton", andText: "MENU")
        purpleMenuButton.name = "purpleMenuButton"
        purpleMenuButton.zPosition = darknessNode.zPosition + 1
        purpleMenuButton.position = CGPoint(x: tryAgainButton.position.x, y: tryAgainButton.position.y - buttonMargin)
        addChild(purpleMenuButton)

        // Animate elements entrances
        youDiedTitle.alpha = 0
        let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
        youDiedTitle.run(fadeInAction)
        
        messageLabel.alpha = 0
        let waitAction = SKAction.wait(forDuration: 0.6)
        messageLabel.run(.sequence([waitAction, fadeInAction]))
        
        let buttons = [tryAgainButton, purpleMenuButton]
        let yOffset = tryAgainButton.frame.size.height * 4
        for button in buttons {
            let moveAwayAction = SKAction.run {
                button.position.y -= yOffset
            }
            let moveBackAction = SKAction.move(by: CGVector.init(dx: 0, dy: yOffset), duration: 0.5 + Double(buttons.index(of: button)!) * 0.1)
            moveAwayAction.timingMode = .easeOut
            
            button.run(.sequence([moveAwayAction, SKAction.wait(forDuration: 0.2), moveBackAction]))
        }
    }
    
    // Should be animated in (a punch to the face, don't forget the confetti)
    func setupVictoryMenu() {
        
        darknessNode.isHidden = false
        
        let youWonTitle = SKSpriteNode(imageNamed: "YouWonTitle")
        youWonTitle.zPosition = darknessNode.zPosition + 1
        youWonTitle.position = CGPoint.init(x: 0, y: self.size.height * 0.033 + youWonTitle.size.height/2)
        addChild(youWonTitle)

        let messageLabel = SKLabelNode(withText: "Thank you for playing!")
        messageLabel.zPosition = darknessNode.zPosition + 1
        messageLabel.position.y = -self.size.height * 0.032 - messageLabel.frame.size.height/2
        addChild(messageLabel)
        
        let orangeMenuButton = SKSpriteNode(imageNamed: "OrangeButton", andText: "MENU")
        orangeMenuButton.zPosition = darknessNode.zPosition + 1
        orangeMenuButton.name = "orangeMenuButton"
        orangeMenuButton.position.y = -self.size.height * 0.17 - orangeMenuButton.size.height/2
        addChild(orangeMenuButton)
        
        // Fireworks Sound effects
//        let playFireworksAction = SKAction.playSoundFileNamed("Fireworks", waitForCompletion: true)
//        self.run(playFireworksAction, withKey: "fireworksAction")
        let path = Bundle.main.path(forResource: "Fireworks", ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        self.fireWorksPlayer = try! AVAudioPlayer(contentsOf: url)
//        backgroundMusicPlayer.volume = 0.2
        fireWorksPlayer.play()
        
        
        // Animate elements entrances
        youWonTitle.setScale(0)
        let scaleAction = SKAction.scale(to: 1, duration: 0.5)
        youWonTitle.run(scaleAction)
        
        messageLabel.run(.sequence([SKAction.wait(forDuration: 0.5), scaleAction]))

        orangeMenuButton.alpha = 0
        let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
        orangeMenuButton.run(.sequence([.wait(forDuration: 3), fadeInAction]))
        
        // Slight offset to keep emitters out the screen
        let emittersOffset = CGPoint.init(x: self.size.height/10, y: self.size.width/10)
        if let leftOrbsCannon = SKEmitterNode(fileNamed: "OrbsCannon.sks") {
            leftOrbsCannon.position = CGPoint(x: -self.size.width/2 - emittersOffset.x, y: -self.size.height/2 - emittersOffset.y)
            leftOrbsCannon.zPosition = darknessNode.zPosition + 2
            leftOrbsCannon.particleZPosition = leftOrbsCannon.zPosition
            leftOrbsCannon.targetNode = self
            self.addChild(leftOrbsCannon)
        }

        if let rightOrbsCannon = SKEmitterNode(fileNamed: "OrbsCannon.sks") {
            rightOrbsCannon.position = CGPoint(x: self.size.width/2 + emittersOffset.x, y: -self.size.height/2 - emittersOffset.y)
            rightOrbsCannon.zPosition = darknessNode.zPosition + 2
            rightOrbsCannon.particleZPosition = rightOrbsCannon.zPosition
            rightOrbsCannon.targetNode = self
            rightOrbsCannon.emissionAngle = CGFloat(110).inRadians()
            self.addChild(rightOrbsCannon)
        }
        
        
        // After a litle bit, turn the rain on
        let waitAction = SKAction.wait(forDuration: 3)
        let addOrbRainEmitterAction = SKAction.run {
            if let orbRainEmitter = SKEmitterNode(fileNamed: "OrbRain.sks") {

                orbRainEmitter.position.y = self.size.height/2 + emittersOffset.y
                orbRainEmitter.zPosition = self.darknessNode.zPosition + 2
                orbRainEmitter.particleZPosition = orbRainEmitter.zPosition
                orbRainEmitter.targetNode = self
                
                orbRainEmitter.emissionAngle = CGFloat(270).inRadians()
                self.addChild(orbRainEmitter)
            }
        }
        self.run(.sequence([waitAction, addOrbRainEmitterAction]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            guard let touchedNode = self.nodes(at: location).filter({ $0 is SKSpriteNode }).first else { return }
            
            // If a menu button was touched
            if touchedNode.name == "orangeMenuButton" || touchedNode.name == "tryAgainButton" || touchedNode.name == "purpleMenuButton" {
                
                // Sound effect
                let playSoundAction = SKAction.playSoundFileNamed("MenuSelect", waitForCompletion: false)
                self.run(playSoundAction)
                
                // Animation
                let shrinkAction = SKAction.scale(to: 0.7, duration: 0.1)
                let growAction = SKAction.scale(to: 1.2, duration: 0.1)
                let goBackToNormalAction = SKAction.scale(to: 1, duration: 0.1)
                
                let handleAction = SKAction.run {
                    // Handle it accordingly
                    if touchedNode.name == "orangeMenuButton" {
                        self.delegate?.menuButtonPressed()
                    } else if touchedNode.name == "tryAgainButton" {
                        self.delegate?.tryAgainButtonPressed()
                    } else if touchedNode.name == "purpleMenuButton" {
                        self.delegate?.menuButtonPressed()
                    }
                }
                
                if touchedNode.action(forKey: "Transition") == nil {
                    touchedNode.run(.sequence([shrinkAction, growAction, goBackToNormalAction, handleAction]), withKey: "Transition")
                }
            }
        }
    }
}

