//
//  WavesManager.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/16/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit

enum SpawnerPosition {
    case right, top, left, bottom
    
    // Point where the spawner should be spawned at
    func point() -> CGPoint {
        switch self {
        case .right:
            return CGPoint(x: UIScreen.main.bounds.width * 0.6, y: 0)
        case .top:
            return CGPoint(x: 0, y: UIScreen.main.bounds.height * 0.6)
        case .left:
            return CGPoint(x: -UIScreen.main.bounds.width * 0.6, y: 0)
        case .bottom:
            return CGPoint(x: 0, y: -UIScreen.main.bounds.height * 0.6)
        }
    }
}

enum SpawnersDistribution {
    case right, left, topAndBottom, leftAndRight, allSides

    func dictionary() -> Dictionary<SpawnerPosition, Bool> {

        var dict = [SpawnerPosition: Bool]()

        switch self {
        case .right:
            dict[SpawnerPosition.right] = true
        case .left:
            dict[SpawnerPosition.left] = true
        case .topAndBottom:
            dict[SpawnerPosition.top] = true
            dict[SpawnerPosition.bottom] = true
        case .leftAndRight:
            dict[SpawnerPosition.left] = true
            dict[SpawnerPosition.right] = true
        case .allSides:
            dict[SpawnerPosition.top] = true
            dict[SpawnerPosition.bottom] = true
            dict[SpawnerPosition.left] = true
            dict[SpawnerPosition.right] = true
        }

        return dict
    }
}



enum WaveDifficulty {
    case easy, medium, hard
    
    func distributionDictionary() -> Dictionary<SpawnerPosition, Bool> {
        switch self {
        case .easy:
            let dictPossibilites: [SpawnersDistribution] = [SpawnersDistribution.left, SpawnersDistribution.right]
            let randomDict: [SpawnerPosition: Bool] = dictPossibilites.randomElement().dictionary()
            
            return randomDict
        case .medium:
            let dictPossibilites: [SpawnersDistribution] = [SpawnersDistribution.leftAndRight, SpawnersDistribution.topAndBottom]
            let randomDict: [SpawnerPosition: Bool] = dictPossibilites.randomElement().dictionary()
            
            return randomDict
        case .hard:               
            let dictPossibilites: [SpawnersDistribution] = [SpawnersDistribution.allSides]
            let randomDict: [SpawnerPosition: Bool] = dictPossibilites.randomElement().dictionary()
            
            return randomDict
        }
    }
    
    // Provides a random spawnerLevel
    func spawnerLevel() -> PlayerSpawnerLevel {
        switch self {
        case .easy:
            let levelPossibilities: [PlayerSpawnerLevel] = [.one]
            let randomLevel: PlayerSpawnerLevel = levelPossibilities.randomElement()
            
            return randomLevel
        case .medium:
            let levelPossibilities: [PlayerSpawnerLevel] = [.two]
            let randomLevel: PlayerSpawnerLevel = levelPossibilities.randomElement()
            
            return randomLevel
        case .hard:
            let levelPossibilities: [PlayerSpawnerLevel] = [.four]
            let randomLevel: PlayerSpawnerLevel = levelPossibilities.randomElement()
            
            return randomLevel
        }
    }
}

class WavesManager: NSObject {

    var currentWave: Int = 1 {
        didSet {
            switch currentWave {
            case 1...2:
                self.waveDifficulty = .easy
            case 3...4:
                self.waveDifficulty = .medium
            default:
                self.waveDifficulty = .hard
            }
        }
    }
    
    var waveDifficulty: WaveDifficulty
    
    init(withwaveDifficulty waveDifficulty: WaveDifficulty = .easy) {
        self.waveDifficulty = waveDifficulty
        
        super.init()
    }
    
}
