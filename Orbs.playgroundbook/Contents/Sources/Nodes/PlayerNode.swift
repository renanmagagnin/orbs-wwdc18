//
//  PlayerNode.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

enum Team {
    case none, blue, red
    
    // This will become unnecessary when textures come in
    func playerColor() -> UIColor{
        switch self {
        case .blue:
            return UIColor(red: 50/255, green: 77/255, blue: 92/255, alpha: 1)
        case .red:
            return UIColor(red: 245/255, green: 56/255, blue: 85/255, alpha: 1)
        case .none:
            return UIColor.white
        }
    }
    
    // This will become unnecessary when textures come in
    func orbColor() -> UIColor {
        switch self {
        case .blue:
            return UIColor(red: 248/255, green: 149/255, blue: 54/255, alpha: 1)
        case .red:
            return UIColor(red: 187/255, green: 72/255, blue: 255/255, alpha: 1)
        case .none:
            return UIColor.white
        }
    }
    
    func orbTextureName() -> String {
        switch self {
        case .blue:
            return "MainOrb"
        case .red:
            return "EnemyOrb"
        default:
            return ""
        }
    }
    
    func playerTextureName() -> String {
        switch self {
        case .blue:
            return "MainPlayer"
        case .red:
            return "EnemyPlayer"
        default:
            return ""
        }
    }
}

enum PlayerBehaviour {
    case none, seeker, ranged(CGFloat)
}

enum PlayerJukingDirection {
    case none, right, left
}


class PlayerNode: SKSpriteNode {
    
    // Default distribution of orbs  (this is for when you deactivate all custom stances ingame)
    static var defaultStance: StanceProtocol {
        return OrbitalStance()
    }
    
    // Player size bounds
    static let lowerBoundRadius: CGFloat = 15
    static let upperBoundRadius: CGFloat = 150
    
    // Player movement multiplier bounds
    static let lowerBoundMovementMultiplier: CGFloat = 0.07
    static let upperBoundMovementMultiplier: CGFloat = 0.12
    
    // Default orb regen interval
    static let defaultOrbSpawningInterval: TimeInterval = 1.5
    
    var maxHealth: Int = 100
    var health: Int = 100 {
        didSet {
            resize()
        }
    }
    
    // Orb regen
    var orbSpawingModifier: Double = 0
    var orbSpawingReference: TimeInterval = 0.0     // LastTime
    var orbSpawningCounter: TimeInterval = 0.0      // Delta
    var orbSpawningInterval: TimeInterval {
        get {
            return PlayerNode.defaultOrbSpawningInterval * (1 - orbSpawingModifier / 100)
        }
    }
    
    var team: Team!
    
    var stance: StanceProtocol = PlayerNode.defaultStance {
        didSet {
            stance.player = self
        }
    }
    var orbs: [OrbNode] = []
    
    var damageModifier = 0  // percentage
    
    var abilities: [AbilityProtocol] = []
    
    // Effects currently applied to the player
    var effects: [Effect] = []
    
    // Where the player is looking at.
    var aim: CGPoint = CGPoint(x: 1, y: 0)
    
    // Where the player is looking towards, length of the vector is its radius.
    var closeAim: CGPoint {
        get {
            let distance = self.aim - self.position
            return distance.normalized() * self.radius * 2
        }
    }
    
    // Where the player is moving towards
    var movingDirection: CGPoint = CGPoint(x: 1, y: 0)
    
    var mobilityModifier: CGFloat = 0
    var movementMultiplier: CGFloat {
        get {
            return PlayerNode.upperBoundMovementMultiplier - CGFloat(health) / CGFloat(maxHealth) * (PlayerNode.upperBoundMovementMultiplier - PlayerNode.lowerBoundMovementMultiplier)
        }
    }
    
    var radius: CGFloat {
        get {
            var radius = floor(CGFloat(health) / 2)
            
            // Assert boundaries
            if radius > PlayerNode.upperBoundRadius {
                radius = PlayerNode.upperBoundRadius
            } else if radius < PlayerNode.lowerBoundRadius {
                radius = PlayerNode.lowerBoundRadius
            }
            
            return radius
        }
    }
    
    var maxOrbs: Int = 12 * 2
    let orbsPerLayer: Int = 12
    
    // These should probably be moved to the orbital stance
    var referenceAngle: CGFloat = 0
    var orbsAngularSpeed: CGFloat = -0.05
    
    var behaviour: PlayerBehaviour = .none
    var playerJukingDirection: PlayerJukingDirection = .none
    var isGettingCloser: Bool = false  // this is dirty
    
    var glowShapeNode: SKShapeNode!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(with team: Team, andAbilities abilities: [AbilityProtocol] = []) {
        self.team = team
        self.abilities = abilities
        
        super.init(texture: nil, color: UIColor.white, size: CGSize())
        
        self.zPosition = ZPosition.Player
        
        self.stance.player = self
        
        for ability in self.abilities {
            ability.player = self
            
            // If the ability has a stance, hook it up to self.
            if let changeStanceAbility = ability as? ChangeStanceAbility {
                changeStanceAbility.stance.player = self
            }
        }
        
        self.applyPassives()
        
        self.drawTexture()
        self.resize()
    }
}


extension PlayerNode {
    
    func drawTexture() {
        let texture = SKTexture(imageNamed: self.team.playerTextureName())
        self.texture = texture
    }
    
    func resize() {
        
//        let newSize = CGSize(width: radius * 2, height: radius * 2)
//        let resizingAction = SKAction.resize(toWidth: newSize.width, height: newSize.height, duration: 0.2)
//        resizingAction.timingMode = SKActionTimingMode.easeInEaseOut
//        let physicsBodyAction = SKAction.run(self.setupPhysicsBody, queue: DispatchQueue.main)
//        let sequence = SKAction.sequence([resizingAction, physicsBodyAction])
//        self.run(sequence, withKey: "resizeAction")
        
        self.size = CGSize(width: radius * 2, height: radius * 2)

        if let glow = self.childNode(withName: "glowShapeNode") {
            glow.removeFromParent()
        }
        self.glowShapeNode = SKShapeNode(circleOfRadius: radius * 0.1)
        glowShapeNode.glowWidth = self.radius * 1.2
        glowShapeNode.strokeColor = self.team.orbColor()
        glowShapeNode.name = "glowShapeNode"
        self.addChild(glowShapeNode)
        
        setupPhysicsBody()
    }
    
    //MARK: Physics Body
    func setupPhysicsBody() {
        let body = SKPhysicsBody(circleOfRadius: radius)
        
        
        body.isDynamic = true
        body.categoryBitMask = PhysicsCategory.Player
        body.contactTestBitMask = PhysicsCategory.SafeArea & PhysicsCategory.Orb  // & PhysicsCategory.Pickup
        body.collisionBitMask = PhysicsCategory.Player
        body.usesPreciseCollisionDetection = true
        self.physicsBody = body
    }
    
    func applyPassives() {
        for ability in self.abilities {
            if let ab = ability as? PassiveAbilityProtocol {
                ab.passive()
            }
        }
    }
    
    func move(withVelocity velocity: CGPoint){
        
        if self.isUnder([.stunning]) {
            return
        }
        
        let modifiedMovementMultiplier = self.movementMultiplier * (1 + self.mobilityModifier / 100)
        
        let dx = velocity.x * modifiedMovementMultiplier
        let dy = velocity.y * -modifiedMovementMultiplier
        
        self.movingDirection = velocity.normalized() * radius * 2
        
        // Calculation of the resulting character's position
        let newX = self.position.x + dx
        let newY = self.position.y - dy
        
        let screenSize = UIScreen.main.bounds.size
        
        if self.team == .blue {
            
            if (newX >= size.width/2 - screenSize.width/2 && newX <= screenSize.width/2 - size.width/2) {
                self.position.x = newX
//                let moveAction = SKAction.move(by: CGVector.init(dx: dx, dy: 0), duration: 1/60)
//                self.run(moveAction)
            }
            
            if (newY >= size.height/2 - screenSize.height/2 && newY <= screenSize.height/2 - size.height/2) {
                self.position.y = newY
//                let moveAction = SKAction.move(by: CGVector.init(dx: 0, dy: -dy), duration: 1/60)
//                self.run(moveAction)
            }
            
        } else if self.team == .red {       // Red players can leave the screen bounds
            self.position.x = newX
            self.position.y = newY
//            let moveAction = SKAction.move(by: CGVector.init(dx: dx, dy: -dy), duration: 1/60)
//            self.run(moveAction)
        }
    }
    
    func shootOrb(towards position: CGPoint) {
        // Make sure orbs isn't empty
        guard let orb = orbs.last else {
            return
        }
        
        // Calculates a destination outside the screen that passes through the target position
        var distance = position - orb.position
        
        let verticalMultiplier = UIScreen.main.bounds.height / abs(distance.y)
        let horizontalMultiplier = UIScreen.main.bounds.width / abs(distance.x)
        
        distance = distance * max(verticalMultiplier, horizontalMultiplier)
        
        // Tells the orb to go there and stop controlling it
        orb.destination = distance + orb.position
        
        // Rotate the orb accordingly
        let vector = orb.destination! - orb.position
        let vectorAngle = atan2(vector.y, vector.x) - CGFloat.pi/2
        orb.zRotation = vectorAngle
        
        // Stretch the orb
        let squishAction = SKAction.scaleX(to: 0.7, duration: 0.3)
        let stretchAction = SKAction.scaleY(to: 1.5, duration: 0.3)
        orb.run(.group([squishAction, stretchAction]), withKey: "stretching")
        
        orbs.removeLast()
    }
    
    func shootOrb(towardsPlayer player: PlayerNode) {
        
        // Make sure orbs isn't empty and grab the last
        guard let orb = orbs.last else {
            return
        }
        orbs.removeElement(orb)
        
        let seekAction = SKAction.customAction(withDuration: 0) { (_, _) in
            let position = player.position
            
            // Calculates a destination outside the screen that passes through the target position
            var distance = position - orb.position
            
            let verticalMultiplier = UIScreen.main.bounds.height / abs(distance.y)
            let horizontalMultiplier = UIScreen.main.bounds.width / abs(distance.x)
            
            distance = distance * max(verticalMultiplier, horizontalMultiplier)
            
            // If the player is still alive, seek him. If not, come back.
            if player.health > 0 {
                orb.destination = distance + orb.position
                
                // Rotate the orb accordingly
                let vector = orb.destination! - orb.position
                let vectorAngle = atan2(vector.y, vector.x) - CGFloat.pi/2
                orb.zRotation = vectorAngle
                
            } else {
                
                // If orbs is not full, recall the orb
                if self.orbs.count < self.maxOrbs {
                    // Transfer orb
                    orb.player = self
                    if !self.orbs.contains(orb) {
                        self.orbs.append(orb)
                    }
                    orb.removeAction(forKey: "seekingAction")
                }
    
            }
    
        }
        let waitAction = SKAction.wait(forDuration: 1/60)
        let seekSequence = SKAction.sequence([seekAction, waitAction])
        let repeatAction = SKAction.repeatForever(seekSequence)
        
        // Stretch the orb
        let squishAction = SKAction.scaleX(to: 0.7, duration: 0.3)
        let stretchAction = SKAction.scaleY(to: 1.5, duration: 0.3)
        orb.run(.group([squishAction, stretchAction]), withKey: "stretching")
        
        orb.run(repeatAction, withKey: "seekingAction")
    }
    
    func isUnder(_ effects: [Effect]) -> Bool {
        
        for playerEffect in self.effects {
            for effect in effects {
                if playerEffect == effect {
                    return true
                }
            }
        }
        return false
    }
    
    // Returns the amount of normal orbs the player has
    func normalOrbs() -> Int {
        
        var numberOfNormalOrbs = 0
        
        self.orbs.forEach { (orb) in
            if orb.effects == [] {
                numberOfNormalOrbs += 1
            }
        }
        
        return numberOfNormalOrbs
    }
    
    func lastNormalOrbs(_ amount: Int) -> [OrbNode] {
        
        var lastNormalOrbs: [OrbNode] = []
        
        for i in stride(from: self.orbs.count - 1, through: 0, by: -1) {
            if self.orbs[i].effects == []{
                
                if lastNormalOrbs.count >= amount {
                    break
                }
                
                lastNormalOrbs.append(self.orbs[i])
            }
        }
        
        return lastNormalOrbs
    }
    
    func mergeNormalOrbs(_ amount: Int, withCallback callback: @escaping (([OrbNode]) -> Void) ) {
        
        var timer: Timer = Timer()
        
        let spentOrbs: [OrbNode] = lastNormalOrbs(amount)
        
        if spentOrbs.count != amount {
            print("Not enough normal orbs")
            return
        }
        
        spentOrbs.forEach { (orb) in
            orb.orbSpeed *= 2
            self.orbs.removeElement(orb)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true, block: { (_) in
            
            var finished = true
            
            spentOrbs.forEach({ (orb) in
                orb.destination = self.position
                
                let distance = (self.position - orb.position).length()
                
                if distance >= orb.radius * 1.7 {
                    finished = false
                    
                    // If player is too fast add even more speed to the orb
                    if self.movementMultiplier > 0.10 {
                        orb.orbSpeed *= 1.2  // 2 * 1.5 = 2.4
                    }
                }
                
            })
            
            if finished {
                let spentOrbsArray: [OrbNode] = Array(spentOrbs)
                callback(spentOrbsArray)
                timer.invalidate()
            }
            
        })
        
        
    }
}

