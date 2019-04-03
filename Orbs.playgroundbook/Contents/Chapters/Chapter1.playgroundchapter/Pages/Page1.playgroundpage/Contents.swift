/*:
 
 - Important:
 Start by reading the instructions and play on full screen mode. Have fun!!
 
 # Introduction
 ![A Player, his orbs and enemy player with his spikes.](Introduction.png)
 - A player's size represents his current health: the more health a player has, the bigger and slower he is.
 - The orange player controls Orbs for attack and defense and enemy players do the same with Spikes.
 - Orbs deal damage to enemy players and Spikes deal damage to the orange player.
 - Orbs and Spikes destroy each other on contact.
 - Players regenerate Orbs/Spikes over time.
 ----
 
 # Objective
 Survive through waves of enemy players, collect power ups and defeat The Boss.
 
 ----
 
 # Controls
 ![Analog stick and the abilities bar](Controls.png)
 You move the orange player using the analog stick and manipulate his orbs using the abilites bar.
 
 ----
 
 # Player Abilities
 - **Shoot:** Player shoots an orb towards the closest enemy. Cooldown: 0.5 second.
 - **Shield:** Orbs form a shield towards the closest enemy. Toggleable (no cooldown)
 - **Teleport:** Player teleports forwards, leaving his orbs behind. Orbs stay [invulnerable](glossary://Invulnerable) for half a second while coming back to the player. Cooldown: 10 seconds.
 - **Ultimate:** Player shoots ALL orbs towards the closest enemy. If the target is killed, remaining orbs come back to the player's control. Cooldown: 10 seconds.
 
 ----
 
 # Power Ups
 - **Instant:** Extra orbs or healing.
 - **Temporary:** Double damage, double orb regeneration or burst of speed.
 - **Upgrades:** More damage or faster orb regeneration.
 
 ----
 
 # Credits
 
 - SpriteKit Analog Stick by [MitrophD](https://github.com/MitrophD)
 - "Nice Kitty" by [Cimba](https://cimba.newgrounds.com/)
 
*/
 
//#-hidden-code

import SpriteKit
import PlaygroundSupport
import AVFoundation

//Constant Values for the game.
let width = 1024
let height = 768

// Code to bring the game
let spriteView = SKView(frame: CGRect(x: 0, y: 0, width: width, height: height))

//Debugging commands
//spriteView.showsDrawCount = true
//spriteView.showsNodeCount = true
//spriteView.showsFPS = true

let cfURL = Bundle.main.url(forResource: "Dosis-Bold", withExtension: "ttf")! as CFURL
CTFontManagerRegisterFontsForURL(cfURL, CTFontManagerScope.process, nil)
let cfURL2 = Bundle.main.url(forResource: "Dosis-ExtraBold", withExtension: "ttf")! as CFURL
CTFontManagerRegisterFontsForURL(cfURL2, CTFontManagerScope.process, nil)
let cfURL3 = Bundle.main.url(forResource: "SecularOne-Regular", withExtension: "ttf")! as CFURL
CTFontManagerRegisterFontsForURL(cfURL3, CTFontManagerScope.process, nil)

let path = Bundle.main.path(forResource: "BackgroundMusic", ofType: "mp3")!
let url = URL(fileURLWithPath: path)
let backgroundMusicPlayer = try! AVAudioPlayer(contentsOf: url)
backgroundMusicPlayer.numberOfLoops = -1
backgroundMusicPlayer.volume = 0.2
backgroundMusicPlayer.play()

// Adding game to playground so that we all can play
let scene = MenuScene(size: CGSize(width: width, height: height))
scene.scaleMode = .aspectFit
spriteView.presentScene(scene)

// Show in Playground live view
PlaygroundPage.current.liveView = spriteView

//#-end-hidden-code
