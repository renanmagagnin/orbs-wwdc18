//
//  PlayerSpawnerNode.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import SpriteKit

enum PlayerSpawnerLevel: Int {
    case one = 1, two = 2, three = 3, four = 4, five = 5
    
    func numberOfCharges() -> Int {     // Number of players spawned before self destructing
        switch self {
        case .one:
            return 3
        case .two:
            return 1
        case .three:
            return 2
        case .four:
            return 1
        case .five:
            return 1
        }
    }
    
//    let loadoutPossibilites = [shootingLoadout, shootAndTeleportLoadout, shootingAndCombineLoadout, ultimateLoadout]
    func loadoutProbabilities() -> [Double] {
        switch self {
        case .one:
            return [100.0, 0.0, 0.0, 0.0]
        case .two:
            return [100.0, 0.0, 0.0, 0.0]
        case .three:
            return [50.0, 25.0, 25.0, 0]
        case .four:
            return [25.0, 75.0, 0, 0]
        case .five:
            return [25.0, 75.0, 0, 0]
        }
    }
    
    func spawingInterval() -> TimeInterval {
        switch self {
        case .one:
            return 3
        case .two:
            return 3
        case .three:
            return 3
        case .four:
            return 2
        case .five:
            return 1
        }
    }
    
    func numberOfOrbsBoundaries() -> (Int, Int) {
        switch self {
        case .one:
            return (4, 5)
        case .two:
            return (6, 8)
        case .three:
            return (10, 12)
        case .four:
            return (10, 15)
        case .five:
            return (10, 24)
        }
    }
}

class PlayerSpawnerNode: SKSpriteNode {

    static var spawnerSize = CGSize(width: 20, height: 20)
    
    
    var team: Team
    
    var level: PlayerSpawnerLevel
    var charges: Int
    
    // Interval auxiliar variables
    var playerSpawingReference: TimeInterval = 0.0     // LastTime
    var playerSpawningCounter: TimeInterval = 0.0      // Delta
    
    init(withTeam team: Team, andOf level: PlayerSpawnerLevel) {
        
        self.team = team
        self.level = level
        self.charges = level.numberOfCharges()
        
        super.init(texture: nil, color: .purple, size: PlayerSpawnerNode.spawnerSize)
        
        self.zPosition = ZPosition.Player
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension PlayerSpawnerNode {
    
    static func randomLoadout(probabilities: [Double]) -> [AbilityProtocol] {
        
        let shootingCooldown: TimeInterval = 3
        let combiningCooldown: TimeInterval = 1.2
        
        let shootingLoadout = [ShootAbility()]
        shootingLoadout.first?.cooldown = shootingCooldown
        
        let shootAndTeleportLoadout: [AbilityProtocol] = [ShootAbility(), TeleportAbility()]
        shootAndTeleportLoadout.first?.cooldown = shootingCooldown

        let shootingAndCombineLoadout: [AbilityProtocol] = [ShootAbility(), CombineOrbsAbility()]
        shootingAndCombineLoadout.first?.cooldown = shootingCooldown
        shootingAndCombineLoadout[1].cooldown = combiningCooldown
        
        let ultimateLoadout = [UltimateShootAbility()]
        ultimateLoadout.first?.enterCooldown()
        
        let loadoutPossibilites = [shootingLoadout, shootAndTeleportLoadout, shootingAndCombineLoadout, ultimateLoadout]
        
        var result: Int = 0
        
        // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
        let sum = probabilities.reduce(0, +)
        // Random number in the range 0.0 <= rnd < sum :
        let rnd = sum * Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max)
        // Find the first interval of accumulated probabilities into which `rnd` falls:
        var accum = 0.0
        for (i, p) in probabilities.enumerated() {
            accum += p
            if rnd < accum {
                result = i
                break
            }
        }
        
        return loadoutPossibilites[result]
    }
    
    func randomPlayer() -> PlayerBlueprint {
        
        // Player stats
        var health = 0
        switch self.level {
        case .one:
            health = 40
        case .two:
            health = 70
        default:
            health = 90
        }
        
        let minimum = self.level.numberOfOrbsBoundaries().0
        let maximum = self.level.numberOfOrbsBoundaries().1
        let numberOfOrbs: Int = Int(arc4random_uniform(UInt32(maximum - minimum + 1)) + UInt32(minimum))
        
        // Player behaviour
        let randomDistance = CGFloat((arc4random_uniform(2) + 2) * 100)
        let possibleBehaviours: [PlayerBehaviour] = [.seeker, .ranged(randomDistance)]
        let behaviour = possibleBehaviours.randomElement()
        
        // Player default Stance
        let defaultStance: StanceProtocol = (arc4random_uniform(20) <= 2) ? ShieldStance() : OrbitalStance()
        
        // Player Abilities
        let playerLoadout = PlayerSpawnerNode.randomLoadout(probabilities: self.level.loadoutProbabilities())
        
        // Player position
        let offsetRadius = self.size.width * 5
    
        var xOffset = CGFloat(arc4random_uniform(UInt32(offsetRadius)))
        var yOffset = CGFloat(arc4random_uniform(UInt32(offsetRadius)))
        
        xOffset = (arc4random_uniform(2) == 1) ? xOffset : -xOffset
        yOffset = (arc4random_uniform(2) == 1) ? yOffset : -yOffset
        
        let offset = CGPoint(x: xOffset, y: yOffset)
        
        if self.level == .four {
            return self.bossPlayer()
        }
    
        return PlayerBlueprint(health: health, defaultStance: defaultStance, behaviour: behaviour, abilities: playerLoadout, offset: offset, numberOfOrbs: numberOfOrbs)
    }
    
    func bossPlayer() -> PlayerBlueprint {
        let health = 375
        let stance = OrbitalStance()
        let behaviour = PlayerBehaviour.seeker        
        let abilities: [AbilityProtocol] = [ShootAbility()]
        abilities.first?.cooldown = 3
        let offset = CGPoint.zero
        let numberOfOrbs = 12
        
        return PlayerBlueprint(health: health, defaultStance: stance, behaviour: behaviour, abilities: abilities, offset: offset, numberOfOrbs: numberOfOrbs)
    }
    
}

struct PlayerBlueprint {
    var health: Int
    var defaultStance: StanceProtocol
    var behaviour: PlayerBehaviour
    var abilities: [AbilityProtocol]
    var offset: CGPoint
    var numberOfOrbs: Int
}
