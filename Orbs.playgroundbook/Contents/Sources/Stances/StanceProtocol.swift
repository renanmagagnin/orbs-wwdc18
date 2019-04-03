//
//  StanceProtocol.swift
//  OrbsPlayground
//
//  Created by Renan Magagnin on 3/14/18.
//  Copyright © 2018 Renan Magagnin. All rights reserved.
//

import UIKit

protocol StanceProtocol {
    
    var iconName: String { get set }
    
    weak var player: PlayerNode! { get set }
    
    func applyPassives()
    func removePassives()
    
    func positionOrbs()
    
}
