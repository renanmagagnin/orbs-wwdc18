//
//  GameScene.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let None            : UInt32 = 0
    static let All             : UInt32 = UInt32.max
    static let Player          : UInt32 = 0b1
    static let Orb             : UInt32 = 0b10
    static let Pickup          : UInt32 = 0b100
    static let SafeArea        : UInt32 = 0b1000
    static let Background      : UInt32 = 0b10000
}

struct ZPosition {
    static let Background            : CGFloat = 0
    static let SafeArea              : CGFloat = 10
    static let Pickup                : CGFloat = 20
    static let Orb                   : CGFloat = 30
    static let Player                : CGFloat = 40
    static let InGameUserInterface   : CGFloat = 50
    static let MenuUserInterface     : CGFloat = 60
}

public class GameScene: SKScene {
    
    var player: PlayerNode!
    var playerLoadout: [AbilityProtocol] = [ShootAbility(),
                                                    ChangeStanceAbility(withStance: ShieldStance()),
                                                    TeleportAbility(),
                                                    UltimateShootAbility()]
    
    var enemyPlayers: [PlayerNode] = []
    
    var playersSpawners: [PlayerSpawnerNode] = []
    
    var powerUpNodes: [PowerUpNode] = []
    
    var userInterface: UserInterfaceNode!
    
    var wavesManager: WavesManager = WavesManager()
    var waveLabelSpriteNode: SKSpriteNode = SKSpriteNode(imageNamed: "Wave1Label")
    
    var backgroundNode = SKSpriteNode(texture: SKTexture.init(imageNamed: "BackgroundGradient"), color: UIColor.clear, size: CGSize.zero)

    public override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.view?.isMultipleTouchEnabled = true
        
        // Initialize player
        self.spawnPlayer(for: .blue, withAbilites: playerLoadout, at: CGPoint.zero, withOrbs: 12)
        
        // Initialize UI
        AbilityButtonNode.sideLength = self.size.width * 110 / 1024
        UserInterfaceNode.analogStickDiameter = self.size.width * 150 / 1024
        self.userInterface = UserInterfaceNode(withSize: self.size)
        self.userInterface.delegate = self
        self.userInterface.setupAnalogSticks()

        self.userInterface.setupAbilityBar(withAbilities: self.playerLoadout)
        
        addChild(self.userInterface)
        
        // Intialize spawners
        self.positionSpawners()
        
        self.waveLabelSpriteNode.position.y = self.size.height * 2 / 6
        self.waveLabelSpriteNode.zPosition = ZPosition.InGameUserInterface
        self.waveLabelSpriteNode.setScale(0)
        self.addChild(self.waveLabelSpriteNode)
        self.displayWaveMessage()
        
        setupBackground()
        setupStars()
    }
    
    public override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    
        var players = enemyPlayers
        if let player = self.player {
            players.append(player)
        } else {
            // Player is dead, show death menu
            if self.userInterface.darknessNode.isHidden {
                self.userInterface.setupDeathMenu(withNumberOfWaves: self.wavesManager.currentWave)
            }
        }
        
        // Orb regen for every player
        players.forEach { (player) in
            
            if !isPlayerFull(player) {
                
                if player.orbSpawningCounter >= player.orbSpawningInterval {  // Also check if player isn't full of orbs
                    spawnOrbs(for: player, amount: 1)
                    
                    player.orbSpawningCounter = 0
                } else {
                    
                    // If player was just spawned, don't spawn an orb.
                    if player.orbSpawingReference == 0 {
                        player.orbSpawingReference = currentTime
                    } else {
                        player.orbSpawningCounter += currentTime - player.orbSpawingReference
                        player.orbSpawingReference = currentTime
                    }
                }
            }
            
            // Update aim of every player
            if let closestEnemy = closestEnemyPlayerTo(player),  closestEnemy.isInside(self) {
                player.aim = closestEnemyPlayerPositionTo(player)
                
                // Enable Targeted abilities
                let shootButton = self.userInterface.bottomPlayerAbilityButtons[0]
                if !shootButton.ability.isOnCooldown {
                    self.userInterface.bottomPlayerAbilityButtons[0].state = .normal
                }
                let ultButton = self.userInterface.bottomPlayerAbilityButtons[3]
                if !ultButton.ability.isOnCooldown {
                    self.userInterface.bottomPlayerAbilityButtons[3].state = .normal
                }
            } else {
                // Disable Targeted abilities
                let shootButton = self.userInterface.bottomPlayerAbilityButtons[0]
                if !shootButton.ability.isOnCooldown {
                    self.userInterface.bottomPlayerAbilityButtons[0].state = .disabled
                }
                let ultButton = self.userInterface.bottomPlayerAbilityButtons[3]
                if !ultButton.ability.isOnCooldown {
                    self.userInterface.bottomPlayerAbilityButtons[3].state = .disabled
                }
            }
            
            
            // Distribute orbs of every player
            player.stance.positionOrbs()
            
            // Make player move based on its behaviour
            switch player.behaviour {
            case .none:
                break
            case .seeker:
                
                let speed: CGFloat = 20
                
                let distance = (closestEnemyPlayerPositionTo(player) - player.position)
                let velocity = distance.normalized() * speed

                player.move(withVelocity: velocity)
                
            case .ranged(let range):
                
                let speed: CGFloat = 15
                
                let distance = (closestEnemyPlayerPositionTo(player) - player.position)
                
                
                // Side strafing random changing
                if arc4random_uniform(1000) > 985 {
                    let jukingPossibilites: [PlayerJukingDirection] = [.none, .none, .left, .right]
                    player.playerJukingDirection = jukingPossibilites.randomElement()
                }
                
                // Side strafing
                if player.playerJukingDirection == .left {
                    let leftVector = (player.isGettingCloser == false) ? player.movingDirection.perpendicularCounterClockwise() : player.movingDirection.perpendicularClockwise()
                    player.move(withVelocity: leftVector.normalized() * speed)
                } else if player.playerJukingDirection == .right {
                    let rightVector = (player.isGettingCloser == true) ? player.movingDirection.perpendicularCounterClockwise() : player.movingDirection.perpendicularClockwise()
                    player.move(withVelocity: rightVector.normalized() * speed)
                }
                
                
                var velocity = CGPoint.zero
                
                if distance.length() > range {                  // Gets closer to enemy
                    velocity = distance.normalized() * speed
                    player.isGettingCloser = true
                } else if distance.length() < range && !player.isNearScreenBorder() {    // If too close, run away
                    velocity = distance.normalized() * -speed
                    player.isGettingCloser = false
                }
                player.move(withVelocity: velocity)
            
                
                // Use abilities if on screen
                if player.isInside(self) {
                    for ability in player.abilities {
                        if let activeAbility = ability as? ActiveAbilityProtocol {
                            if arc4random_uniform(100) < 7 {
                                activeAbility.active()
                            }
                        }
                    }
                }
                
            }
        }
        
        playersSpawners.forEach { (spawner) in
            // Player spawn for every player spawner
            if spawner.playerSpawningCounter >= spawner.level.spawingInterval() {
                
                // Spawn a player
                let newEnemyBlueprint = spawner.randomPlayer()
                spawnPlayer(for: spawner.team, from: newEnemyBlueprint, at: spawner.position + newEnemyBlueprint.offset)
                
                if let newBoss = self.enemyPlayers.last, newEnemyBlueprint.health > 200 {
                    let texture = SKTexture(imageNamed: "EnemyBoss")
                    newBoss.texture = texture
                }
                
                spawner.playerSpawningCounter = 0
                
                spawner.charges -= 1
                
                // If spawner is out of charges, remove it
                if spawner.charges == 0 {
                    removePlayerSpawner(spawner: spawner)
                }
                
            } else {
                
                // If spawner was just spawned, don't spawn a player.
                if spawner.playerSpawingReference == 0 {
                    spawner.playerSpawingReference = currentTime
                } else {
                    spawner.playerSpawningCounter += currentTime - spawner.playerSpawingReference
                    spawner.playerSpawingReference = currentTime
                }
            }
        }
        
        if(self.playersSpawners.isEmpty && enemyPlayers.isEmpty) {
            
            let removeIndicatorsAction = SKAction.run {
                // Clear spawners indicators
                self.userInterface.removeSpawnerIndicators()
            }
            
            let spawnRewardsAction = SKAction.run {
                // Spawn Rewards
                let numberOfRewards = arc4random_uniform(3) + 1
                for _ in 0..<numberOfRewards {
                    self.spawnRandomUpgradePowerUp()
                }
            }
            
            let waitAction = SKAction.wait(forDuration: 3)
            
            // If difficulty was hard, player just defeated the boss and victory screen should be shown.
            if wavesManager.waveDifficulty == .hard {
    
                // wait for boss death animation
                let drawWWDCAction = SKAction.run {
                    if self.userInterface.darknessNode.isHidden {
                        self.drawWWDCWithOrbsFrom(self.player)
                    }
                }

                let showVictoryMenuAction = SKAction.run({
                    if self.userInterface.darknessNode.isHidden {
                        self.userInterface.setupVictoryMenu()
                    }
                })

                if self.action(forKey: "endGameAction") == nil {
                    self.run(.sequence([removeIndicatorsAction, drawWWDCAction, waitAction, showVictoryMenuAction]), withKey: "endGameAction")
                }
                
            } else {
                // Wait for 3 seconds and start new wave
                let commenceNextWaveAction = SKAction.run({
                    // Setup next Wave
                    self.wavesManager.currentWave += 1
                    self.positionSpawners()
                    
                    // Display Wave Message
                    self.displayWaveMessage()
                })
                
                if self.action(forKey: "nextWaveAction") == nil {
                    self.run(.sequence([removeIndicatorsAction, spawnRewardsAction, waitAction, commenceNextWaveAction]), withKey: "nextWaveAction")
                }
            }
        
        }
    }
}

// MARK: Background
extension GameScene {
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

//MARK: Enemy Waves
extension GameScene {
    func positionSpawners() {
        
        let distributions = wavesManager.waveDifficulty.distributionDictionary()
        
        
        // BOSS WAVE
        if wavesManager.waveDifficulty == .hard {
            
            let positions: [SpawnerPosition] = [.left, .right, .top, .bottom]
            
            // Position the boss spawner at a random side
            spawnPlayerSpawner(for: .red, of: .four, at: positions.randomElement().point())
            
            // Setup All 4 Spawner Indicators
            for position in positions {
                self.userInterface.setupSpawnerIndicator(for: position)
            }
            
            return
        }
        
        if distributions[.left] != nil {
            spawnPlayerSpawner(for: .red, of: wavesManager.waveDifficulty.spawnerLevel(), at: SpawnerPosition.left.point())
            self.userInterface.setupSpawnerIndicator(for: SpawnerPosition.left)
        }
        if distributions[.right] != nil {
            spawnPlayerSpawner(for: .red, of: wavesManager.waveDifficulty.spawnerLevel(), at: SpawnerPosition.right.point())
            self.userInterface.setupSpawnerIndicator(for: SpawnerPosition.right)
        }
        if distributions[.top] != nil {
            spawnPlayerSpawner(for: .red, of: wavesManager.waveDifficulty.spawnerLevel(), at: SpawnerPosition.top.point())
            self.userInterface.setupSpawnerIndicator(for: SpawnerPosition.top)
        }
        if distributions[.bottom] != nil {
            spawnPlayerSpawner(for: .red, of: wavesManager.waveDifficulty.spawnerLevel(), at: SpawnerPosition.bottom.point())
            self.userInterface.setupSpawnerIndicator(for: SpawnerPosition.bottom)
        }
    }
    
    func displayWaveMessage() {
        
        let newTexture = SKTexture(imageNamed: "Wave\(self.wavesManager.currentWave)Label")
        self.waveLabelSpriteNode.texture = newTexture
        self.waveLabelSpriteNode.size = newTexture.size()
        
        let growAction = SKAction.scale(to: 1.2, duration: 0.3)
        let waitAction = SKAction.wait(forDuration: 2)
        let shrinkAction = SKAction.scale(to: 0, duration: 0.5)
        
        let sequence = SKAction.sequence([growAction, waitAction, shrinkAction])
        
        self.waveLabelSpriteNode.run(sequence)
    }
}

extension GameScene {
    func spawnPlayer(for team: Team, withAbilites abilities: [AbilityProtocol] = [], andBehaviour behaviour: PlayerBehaviour = .none, at position: CGPoint = CGPoint.zero, withOrbs amount: Int = 0, andHealth health: Int = 100) {
        let newPlayer = PlayerNode(with: team, andAbilities: abilities)
        newPlayer.behaviour = behaviour
        newPlayer.position = position
        newPlayer.health = health
        
        switch team {
        case .blue:
            self.player = newPlayer
        case .red:
            enemyPlayers.append(newPlayer)
            newPlayer.orbSpawingModifier += -200   // enemy players take 3 times longer to generate orbs
        case .none:
            break
        }
        
        addChild(newPlayer)
        
        if amount > 0 {
            spawnOrbs(for: newPlayer, amount: amount)
        }
    }
    
    func spawnPlayer(for team: Team, from playerBlueprint: PlayerBlueprint, at position: CGPoint = CGPoint.zero) {
        
        let newPlayer = PlayerNode(with: team, andAbilities: playerBlueprint.abilities)
        newPlayer.position = position
        
        if playerBlueprint.health > 100 {
            newPlayer.maxHealth = playerBlueprint.health
        }
        newPlayer.health = playerBlueprint.health
        newPlayer.stance = playerBlueprint.defaultStance
        newPlayer.behaviour = playerBlueprint.behaviour
        
        switch team {
        case .blue:
            self.player = newPlayer
        case .red:
            enemyPlayers.append(newPlayer)
            newPlayer.orbSpawingModifier += -200   // enemy players take 3 times longer to generate orbs
        case .none:
            break
        }
        
        addChild(newPlayer)
        
        if playerBlueprint.numberOfOrbs > 0 {
            spawnOrbs(for: newPlayer, amount: playerBlueprint.numberOfOrbs)
        }
    }
    
    // Give a player a number os orbs with the desired special effects
    func spawnOrbs(for player: PlayerNode, withEffects effects: [Effect] = [], amount: Int = 1) {
        
        for _ in 1...amount {
            
            if self.isPlayerFull(player) {
                break
            }
            
            let newOrb = OrbNode(withTeam: player.team, andEffects: effects)
            newOrb.player = player
            newOrb.position = player.position
            newOrb.name = "Orb"
            addChild(newOrb)
            
            // Make sure that the newOrb is not inserted after a special orb.
            var specialIndex = -1
            for i in stride(from: player.orbs.count - 1, through: 0, by: -1) {
                let currentOrb = player.orbs[i]

                if currentOrb.effects != [] || currentOrb.radius > OrbNode.defaultRadius {
                    specialIndex = i
                }
            }

            if specialIndex == -1 {
                player.orbs.append(newOrb)
            } else {
                player.orbs.insert(newOrb, at: specialIndex)
            }
            
        }
    }
    
    func spawnPlayerSpawner(for team: Team, of level: PlayerSpawnerLevel, at position: CGPoint = CGPoint.zero) {
        let newSpawner = PlayerSpawnerNode(withTeam: team, andOf: level)
        newSpawner.position = position
        addChild(newSpawner)
        
        playersSpawners.append(newSpawner)
    }
    
    func removePlayerSpawner(spawner: PlayerSpawnerNode) {
        playersSpawners.removeElement(spawner)
        spawner.removeFromParent()
    }
}


//MARK: UserInterfaceDelegate
extension GameScene: UserInterfaceDelegate {
    
    func menuButtonPressed() {
        self.userInterface.fireWorksPlayer.stop()
        
        let menuScene = MenuScene(size: UIScreen.main.bounds.size)
        menuScene.scaleMode = .aspectFit
        if let view = self.view {
            let transition = SKTransition.fade(withDuration: 0.5)
            view.presentScene(menuScene, transition: transition)
        }
    }
    
    func tryAgainButtonPressed() {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFit
        if let view = self.view {
            view.presentScene(scene)
        }
    }
    
    //MARK: Joystick Handlers
    var bottomJoystickClosure: ((AnalogJoystickData) -> ())? {
        return { [weak self] data in
            
            if let player = self?.player {
                player.move(withVelocity: data.velocity)
            }
            
        }
    }
}


//MARK: Entities management
extension GameScene {
    
    // Removes player from game and handles killing if necessary
    func removePlayer(_ player: PlayerNode, withKiller killerPlayer: PlayerNode? = nil) {
        
        // Transfer orbs to killer until he is full
        if let killer = killerPlayer {
            transferOrbs(from: player, to: killer)
        }
        
        // Remove orbs from player, in case there are still orbs left.
        player.orbs.forEach { (orb) in
            removeOrb(orb)
        }
        
        // Drop a powerUp
        if player.team == .red {
            if arc4random_uniform(100) > 10 {
                spawnRandomBonusPowerUp(at: player.position)
            }
        }
        
        // Remove player from team array
        if player.team == .red {
            enemyPlayers.removeElement(player)
        } else {
            // MAIN PLAYER HAS DIED
            self.player = nil
        }
        
        // Death particles
        let waitAction = SKAction.wait(forDuration: 1.5)
        let particleName = player.team == .blue ? "PlayerDeath.sks" : "EnemyDeath.sks"
        if let deathParticleEmitter = SKEmitterNode(fileNamed: particleName) {
            deathParticleEmitter.position = player.position
            deathParticleEmitter.zPosition = ZPosition.Player + 1
            deathParticleEmitter.targetNode = self
            self.addChild(deathParticleEmitter)
            
            deathParticleEmitter.run(.sequence([waitAction, .removeFromParent()]))
        }
        
        player.removeFromParent()
    }
    
    func removeOrb(_ orb: OrbNode) {
        if let ownerPlayer = orb.player {
            ownerPlayer.orbs.removeElement(orb)
        }
        orb.removeFromParent()
    }

    
    func isPlayerFull(_ player: PlayerNode) -> Bool {
        
        // Count number of orbs that belong to the player
        var numberOfOrbs = 0
        for child in self.children {
            if child.name == "Orb" {
                let orb = child as! OrbNode
                if orb.player == player {
                    numberOfOrbs += 1
                }
            }
        }
        
        return player.orbs.count >= player.maxOrbs || numberOfOrbs >= player.maxOrbs
    }
    
    
    // Amount 0 means transfer every orb
    func transferOrbs(_ amount: Int = 0, from player: PlayerNode, to secondPlayer: PlayerNode) {
        
        var transferedOrbs = 0
        
        for orb in player.orbs {
        
            // If second player is full, stop transfering
            if isPlayerFull(player) {
                break
            }
            
            // If the amount of orbs transfered reached the desired one, stop trasnfering
            if transferedOrbs >= amount && amount != 0 {
                break
            }
            
            // Transfer orb
            orb.player = secondPlayer
            orb.team = (secondPlayer.team)!
            orb.resize()
            secondPlayer.orbs.append(orb)
            player.orbs.removeElement(orb)
            
            transferedOrbs += 1
        }
        
    }
    
    // Returns the closest enemy player to the received player
    func closestEnemyPlayerTo(_ player: PlayerNode) -> PlayerNode? {
        guard let team = player.team else { return nil }
        
        var enemyPlayers: [PlayerNode] = []
        
        switch team {
        case .blue:
            enemyPlayers = self.enemyPlayers
        case .red:
            if let player = self.player {
                enemyPlayers = [player]
            } else {
                return nil
            }
        default:
            break
        }
        
        var closestEnemyPlayer: PlayerNode? = nil
        var smallestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        if !enemyPlayers.isEmpty {
            enemyPlayers.forEach({ (enemyPlayer) in
                
                let distance = (enemyPlayer.position - player.position).length()
                
                if distance < smallestDistance && enemyPlayer.isInside(self) {
                    smallestDistance = distance
                    closestEnemyPlayer = enemyPlayer
                }
                
            })
        }
        return closestEnemyPlayer
    }
    
    func closestEnemyPlayerPositionTo(_ player: PlayerNode) -> CGPoint {
        if let enemy = closestEnemyPlayerTo(player), enemy.isInside(self) {
            return enemy.position
        } else {
            // Player aims foward when there are no enemies
            return player.position + player.movingDirection * 30
        }
    }
}

// MARK: PowerUps
extension GameScene {
    
    func spawnPowerUp(_ powerUp: PowerUpProtocol, at position: CGPoint) {
        let powerUpNode = PowerUpNode(withPowerUp: powerUp)
        
        
        
        powerUpNode.position = position
        powerUpNode.setScale(0)
        self.powerUpNodes.append(powerUpNode)
        self.addChild(powerUpNode)
        
        // Grow action
        let growAction = SKAction.scale(to: 1, duration: 0.7)
        powerUpNode.run(growAction)
    }
    
    func spawnPowerUp(_ powerUp: PowerUpProtocol, at position: CGPoint, withOffset offset: CGFloat) {
        let powerUpNode = PowerUpNode(withPowerUp: powerUp)
        
        powerUpNode.position = position
        self.powerUpNodes.append(powerUpNode)
        self.addChild(powerUpNode)
        
        // Bounce towards offset
        let randomAngle = CGFloat(arc4random_uniform(UInt32(2 * CGFloat.pi + 1)))
        let dx = offset * cos(randomAngle)
        let dy = offset * sin(randomAngle)
        let offsetVector = CGVector(dx: dx, dy: dy)
        
        let moveAction = SKAction.move(by: offsetVector, duration: 0.3)
        
        let growAction = SKAction.scale(to: 1.3, duration: 0.3/2)
        let shrinkAction = SKAction.scale(to: 1, duration: 0.3/2)
        let bounceAction = SKAction.sequence([growAction, shrinkAction])
        
        let dropGroup = SKAction.group([bounceAction, moveAction])
        powerUpNode.run(dropGroup)
    }
    
    // Used for drops
    func spawnRandomBonusPowerUp(at position: CGPoint) {
        
        let permanentPowerUpPossibilites: [PowerUpProtocol] = [HealingPowerUp(), OrbsPowerUp()]
        let temporaryPowerUpPossibilites: [PowerUpProtocol] = [DoubleDamagePowerUp(), DoubleOrbRegenPowerUp(), SpeedBoostPowerUp()]
        
        let powerUpPossibilites = permanentPowerUpPossibilites + temporaryPowerUpPossibilites
        
        let randomPowerUp = powerUpPossibilites.randomElement()
        
//        spawnPowerUp(randomPowerUp, at: position)
        spawnPowerUp(randomPowerUp, at: position, withOffset: 38 * 1.3)
    }
    
    // Used for wave cleared rewards
    func spawnRandomUpgradePowerUp() {
        
        let upgradePowerUpPossibilites: [PowerUpProtocol] = [OrbRegenUpgradePowerUp(), DamageUpgradePowerUp()]
        
        let randomUpgradePowerUp = upgradePowerUpPossibilites.randomElement()
        
        
        let centerRect = CGRect(x: self.size.width / 4, y: self.size.height / 4, width: self.size.width / 2, height: self.size.height / 2)
        spawnPowerUp(randomUpgradePowerUp, inRect: centerRect)
    }
    
    // Spawn a powerUp at a random position
    func spawnPowerUp(_ powerUp: PowerUpProtocol, inRect rect: CGRect) {
        var randomX: CGFloat = 0
        var randomY: CGFloat = 0
        var randomPosition = CGPoint.zero
        
        repeat {
            randomX = CGFloat(arc4random_uniform(UInt32(rect.width - PowerUpNode.pickUpSize.width/2 + 1))) - rect.minX
            randomY = CGFloat(arc4random_uniform(UInt32(rect.height - PowerUpNode.pickUpSize.height/2 + 1))) - rect.minY
            randomPosition = CGPoint(x: randomX, y: randomY)
        } while(randomPosition.distanceTo(self.player.position) < 50)
        
        spawnPowerUp(powerUp, at: randomPosition)
    }
    
    
    func removePowerUpNode(_ powerUpNode: PowerUpNode) {
        self.powerUpNodes.removeElement(powerUpNode)
        powerUpNode.removeFromParent()
    }
    
}



//MARK: Orb effects
extension GameScene {
    
    func affect(_ player: PlayerNode, withEffects effects: [Effect], fromOrb orb: OrbNode) {
        if !effects.isEmpty {
            
            for effect in effects {
                switch effect {
                case .slowing:
                    let slowPercentage: CGFloat = 30
                    
                    player.mobilityModifier -= slowPercentage
                    
                    Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (_) in
                        player.mobilityModifier += slowPercentage
                    })
                    
                case .stunning:
                    player.effects.append(.stunning)
                    
                    Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (_) in
                        player.effects.removeElement(.stunning)
                    })
                case .orbStealing:
                    if let orbPlayer = orb.player {
                        transferOrbs(2, from: player, to: orbPlayer)
                    }
                case .invulnerable:
                    break
                }
                
            }
            
        }
    }
    
}


//MARK: SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    
    public func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // First is lower bit mask
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Handle contact between orbs
        if let orb1 = firstBody.node as? OrbNode,
            let orb2 = secondBody.node as? OrbNode {
            if orb1.team != orb2.team {
                hitOrb(orb1, with: orb2, at: contact.contactPoint)
            }
        }
        
        // Handle contact between orbs and players
        if let player = firstBody.node as? PlayerNode,
            let orb = secondBody.node as? OrbNode {
            if player.team != orb.team {
                hitPlayer(player, with: orb, at: contact.contactPoint)
            }
        }
        
        // Handle contact between powerUps and Main Player
        if let player = firstBody.node as? PlayerNode, let mainPlayer = self.player, player == mainPlayer,
            let powerUpNode = secondBody.node as? PowerUpNode {
            
            let powerUpMessageLabel = SKLabelNode(text: powerUpNode.powerUp.message)
            powerUpMessageLabel.fontSize = 18
            powerUpMessageLabel.fontName = "Dosis ExtraBold"
            powerUpMessageLabel.setScale(0)
            powerUpMessageLabel.position = player.position
            powerUpMessageLabel.zPosition = ZPosition.InGameUserInterface
            addChild(powerUpMessageLabel)
            
            let growingAction = SKAction.scale(to: 1, duration: 0.30)
            let goUpAction = SKAction.moveBy(x: 0, y: 60, duration: 0.70)
            let fadeOutAction = SKAction.fadeOut(withDuration: 0.30)
            let removeAction = SKAction.removeFromParent()
            let sequence = SKAction.sequence([growingAction, goUpAction, fadeOutAction, removeAction])
            powerUpMessageLabel.run(sequence)
            
            // Sound effect
            let playSoundEffectAction = SKAction.playSoundFileNamed("PowerUp", waitForCompletion: false)
            self.run(playSoundEffectAction)
            
            powerUpNode.powerUp.affect(player)
            self.removePowerUpNode(powerUpNode)
        }
        
    }
    
    // Use to detect that a body is out of bounds
    public func didEnd(_ contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // First is lower bit mask
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Handle orb leaving screen, should remove it.
        if let orb = firstBody.node as? OrbNode, secondBody.node?.name == "background" {
            removeOrb(orb)
        }
    }
    
    func hitPlayer(_ player: PlayerNode, with orb: OrbNode, at position: CGPoint) {
        
        // Sound effect
        let soundEffectAction = SKAction.playSoundFileNamed("Hit3", waitForCompletion: true)
        self.run(soundEffectAction)
        
        // Particles setup
        let waitAction = SKAction.wait(forDuration: 1.5)
        
        if let purpleParticleEmitter = SKEmitterNode(fileNamed: "EnemyDamage.sks") {
            purpleParticleEmitter.position = position
            purpleParticleEmitter.zPosition = ZPosition.Player + 1
            purpleParticleEmitter.targetNode = self
            self.addChild(purpleParticleEmitter)
            
            if orb.player != nil && orb.player.team == .red {
                purpleParticleEmitter.particleLifetime *= 1 / 2
            }
            
            purpleParticleEmitter.run(.sequence([waitAction, .removeFromParent()]))
        }
        
        if let orangeParticleEmitter = SKEmitterNode(fileNamed: "PlayerDamage.sks") {
            orangeParticleEmitter.position = position
            orangeParticleEmitter.zPosition = ZPosition.Player + 1
            orangeParticleEmitter.targetNode = self
            self.addChild(orangeParticleEmitter)
            
            if orb.player != nil && orb.player.team == .blue {
                orangeParticleEmitter.particleLifetime *= 1 / 2
                orangeParticleEmitter.particleLifetime *= 1 / 2
            }
            
            orangeParticleEmitter.run(.sequence([waitAction, .removeFromParent()]))
        }
        
        // Hit Animation
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.1)
        let fadeInAction = SKAction.fadeIn(withDuration: 0.1)
        player.run(.sequence([fadeOutAction, fadeInAction]), withKey: "blinkAction")
        
        
        // Damage Dealing
        let previousPlayerHealth = CGFloat(player.health)
        
        // Calculate the finalOrbDamage using a random modifier and the player damage modifier
        let randomPercentageModifier = Double(arc4random_uniform(UInt32(41))) - 20  // Varies between -20 and 20
        let finalPercentageModifier = randomPercentageModifier + Double(orb.player.damageModifier)
        let finalOrbDamage = Int(Double(orb.damage) + round(Double(orb.damage) * finalPercentageModifier/100.0))
        
        // Damage Label setup
        let damageLabel = SKLabelNode(text: "\(finalOrbDamage)")
        damageLabel.fontName = "Dosis ExtraBold"
        damageLabel.position = player.position
        damageLabel.setScale(0)
        damageLabel.fontColor = orb.team == .blue ? UIColor(red: 249/255, green: 181/255, blue: 74/255, alpha: 1) : UIColor(red: 185/255, green: 117/255, blue: 253/255, alpha: 1)
        damageLabel.zPosition = ZPosition.InGameUserInterface
        self.addChild(damageLabel)
        
        let distance = (orb.player != nil) ? (player.position - orb.player.position).normalized() : CGPoint.zero
        
        let horizontalMovingAction = SKAction.move(by: CGVector(dx: distance.x * 45, dy: 0), duration: 0.30)
        let verticalMovingSequence = SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: distance.y), duration: 0.20),
                                                        SKAction.move(by: CGVector(dx: 0, dy: -distance.y), duration: 0.10)])
        
        let movingGroup = SKAction.group([horizontalMovingAction, verticalMovingSequence])
        
        let growAction = SKAction.scale(to: 1.8, duration: 0.30)
        let shortWaitAction = SKAction.wait(forDuration: 0.2)
        let shrinkAction = SKAction.scale(to: 0.1, duration: 0.10)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([growAction, shortWaitAction, shrinkAction, removeAction])
        
        let animationGroup = SKAction.group([movingGroup, sequence])
        damageLabel.run(animationGroup)
        
        // Decrease player's HP using the orb damage with a random factor
        player.health -= finalOrbDamage
        affect(player, withEffects: orb.effects, fromOrb: orb)
        
        // Evaluate the situation
        let shootingPlayer = orb.player
        
        if player.health == 0 {               // Orb and player should die
            removePlayer(player, withKiller: shootingPlayer)
            if !orb.effects.contains(.invulnerable) {
                removeOrb(orb)
            }
        } else if player.health < 0 {         // Player died, orb should shrink
            let radiusDecrease: CGFloat = previousPlayerHealth * 7.0 / 10.0
            
            // Apply decrease but not getting smaller than default
            if orb.radius - radiusDecrease < OrbNode.defaultRadius {
                if !orb.effects.contains(.invulnerable) {
                    removeOrb(orb)
                }
            } else {
                orb.radius -= radiusDecrease
            }
            
            removePlayer(player, withKiller: shootingPlayer)
            
        } else if player.health > 0 {         // Player survivied, only orb should die
            if !orb.effects.contains(.invulnerable) {
                removeOrb(orb)
            }
        }
    }
    
    func hitOrb(_ orb: OrbNode, with secondOrb: OrbNode, at position: CGPoint) {
        
        // Particle setup
        let waitAction = SKAction.wait(forDuration: 1.5)
        
        if let purpleParticleEmitter = SKEmitterNode(fileNamed: "EnemyDamage.sks") {
            purpleParticleEmitter.position = position
            purpleParticleEmitter.zPosition = ZPosition.Player + 1
            purpleParticleEmitter.targetNode = self
            purpleParticleEmitter.particleLifetime *= 1 / 2
            self.addChild(purpleParticleEmitter)
            
            purpleParticleEmitter.run(.sequence([waitAction, .removeFromParent()]))
        }
        
        if let orangeParticleEmitter = SKEmitterNode(fileNamed: "PlayerDamage.sks") {
            orangeParticleEmitter.position = position
            orangeParticleEmitter.zPosition = ZPosition.Player + 1
            orangeParticleEmitter.targetNode = self
            orangeParticleEmitter.particleLifetime *= 1 / 2
            self.addChild(orangeParticleEmitter)
            
            orangeParticleEmitter.run(.sequence([waitAction, .removeFromParent()]))
        }
        
        
        let biggerOrb = orb.radius > secondOrb.radius ? orb : secondOrb
        let smallerOrb = orb.radius > secondOrb.radius ? secondOrb : orb
        
        if biggerOrb.radius == smallerOrb.radius {
            if !biggerOrb.effects.contains(.invulnerable) {
                removeOrb(biggerOrb)
            }
            if !smallerOrb.effects.contains(.invulnerable) {
                removeOrb(smallerOrb)
            }
        } else {
            biggerOrb.radius -= smallerOrb.radius
            if !smallerOrb.effects.contains(.invulnerable) {
                removeOrb(smallerOrb)
            }
        }
        
        // Orb Collision Sound Effect
        let randomSound = arc4random_uniform(2) + 1
        let soundEffect = SKAction.playSoundFileNamed("Hit\(randomSound)", waitForCompletion: false)
        self.run(soundEffect)
    }
}

// WWDC Positioning
extension GameScene {
    
    var wCoordinates: [(CGFloat, CGFloat)] {
        return [(455, 400), (416, 400), (409, 366), (453, 383), (413, 383), (443, 366), (478, 366), (474, 383), (436, 383), (471, 400), (432, 400), (464, 416), (424, 416)]
    }
    
    var dCoordinates: [(CGFloat, CGFloat)] {
        return [(632, 373), (615, 363), (615, 417), (632, 407), (636, 391), (594, 365), (594, 383), (594, 400), (594, 417)]
    }
    
    var cCoordinates: [(CGFloat, CGFloat)] {
        return [(704, 408), (691, 418), (674, 418), (661, 407), (661, 373), (676, 363), (693, 363), (704, 375), (658, 391)]
    }
    
    var oneCoordinates: [(CGFloat, CGFloat)] {
        return [(740, 370), (757, 414), (757, 397), (757, 380), (757, 363)]
    }
    
    var eightCoordinates: [(CGFloat, CGFloat)] {
        return [(827, 404), (818, 395), (820, 416), (786, 407), (794, 417), (794, 396), (794, 363), (786, 374), (795, 383), (828, 374), (819, 383), (820, 363), (807, 360), (807, 420), (807, 389)]
    }
    
    func drawWWDCWithOrbsFrom(_ player: PlayerNode) {
        
        let necessaryNumberOfOrbs = 2 * wCoordinates.count + dCoordinates.count + cCoordinates.count + oneCoordinates.count + eightCoordinates.count
        if player.orbs.count < necessaryNumberOfOrbs {
            let difference = necessaryNumberOfOrbs - player.orbs.count
            player.maxOrbs += difference
            self.spawnOrbs(for: player, withEffects: [], amount: difference)
        }
        
        let letterSpacing: CGFloat = 91
        let secondW: [(CGFloat, CGFloat)]  = self.wCoordinates.map { ($0.0 + letterSpacing, $0.1) }
        
        let lettersCoordinates = [self.wCoordinates, secondW, self.dCoordinates, self.cCoordinates, oneCoordinates, eightCoordinates]
        
        for letterCoordinates in lettersCoordinates {
            for (x, y) in letterCoordinates {
                guard let newOrb = player.orbs.last else {
                    return
                }
                
                let orbSpeed = CGFloat(arc4random_uniform(UInt32(11))) * 0.1 + 0.5
                newOrb.orbSpeed *= orbSpeed * 0.7
                newOrb.name = "Orb"
                
                let waitAction = SKAction.wait(forDuration: 0.2)
                let goAction = SKAction.run({
                    newOrb.destination = CGPoint(x: x - self.frame.size.width * 0.6, y: -y + self.frame.size.height * 7 / 8)
                })
                
                newOrb.run(.sequence([waitAction, goAction]))
                
                player.orbs.removeLast()
            }
        }
        
    }
}




