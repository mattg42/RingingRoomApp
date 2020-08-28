//
//  AudioManager.swift
//  iOSRingingRoom
//
//  Created by Matthew on 25/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//
   
import AVFoundation

class AudioPlayer {
    
    
    func playSound(_ fileName:String) {
        var player: AVAudioPlayer?
        
        if let path = Bundle.main.path(forResource: fileName, ofType: ".m4a", inDirectory: "RingingRoomAudio") {

            player = AVAudioPlayer()

            let url = URL(fileURLWithPath: path)

            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.play()
            }catch {
                print("Error")
            }
        }
    }
}
