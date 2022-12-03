//
//  AudioController.swift
//  iOSRingingRoom
//
//  Created by Matthew on 07/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import AVFoundation

enum SoundAsset: String, CaseIterable {
    case BOB      = "bob"
    case GO       = "go"
    case LOOKTO   = "look"
    case SINGLE   = "single"
    case STAND    = "stand"
    case THATSALL = "all"
    
    case H1 = "H1"
    case H2 = "H2"
    case H3 = "H3"
    case H4 = "H4"
    case H5 = "H5"
    case H6 = "H6"
    case H6f = "H6f"
    case H7 = "H7"
    case H8 = "H8"
    case H9 = "H9"
    case H0 = "H0"
    case HE = "HE"
    case HT = "HT"
    case HA = "HA"
    case HB = "HB"
    case HC = "HC"
    case HD = "HD"
    
    case T1  = "T1"
    case T2  = "T2"
    case T2S = "T2sharp"
    case T3  = "T3"
    case T4  = "T4"
    case T5  = "T5"
    case T6  = "T6"
    case T7  = "T7"
    case T8  = "T8"
    case T9  = "T9"
    case T0  = "T0"
    case TE  = "TE"
    case TT  = "TT"
    case Te1 = "Te1"
    case Te2 = "Te2"
    case Te3 = "Te3"
    case Te4 = "Te4"
    
    case T1M  = "T1-muf"
    case T2M  = "T2-muf"
    case T2SM = "T2sharp-muf"
    case T3M  = "T3-muf"
    case T4M  = "T4-muf"
    case T5M  = "T5-muf"
    case T6M  = "T6-muf"
    case T7M  = "T7-muf"
    case T8M  = "T8-muf"
    case T9M  = "T9-muf"
    case T0M  = "T0-muf"
    case TEM  = "TE-muf"
    case TTM  = "TT-muf"
    case Te1M = "Te1-muf"
    case Te2M = "Te2-muf"
    case Te3M = "Te3-muf"
    case Te4M = "Te4-muf"
}

extension SoundAsset {
    var player:AVAudioPlayer {
        var thePlayer:AVAudioPlayer!
        if let url = Bundle.main.url(forResource: self.rawValue, withExtension: ".wav", subdirectory: "RingingRoomAudio") {
            do {
                thePlayer = try AVAudioPlayer(contentsOf: url)
            } catch {
                print("error")
            }
        }
        thePlayer.prepareToPlay()
        return thePlayer
    }
}

class AudioController: NSObject, AVAudioPlayerDelegate {
    
    var callPlayer:AVAudioPlayer!
    
    let starling = Starling()

    override init() {
        super.init()
        loadSounds()
    }
    
    func loadSounds() {
        for sound in SoundAsset.allCases {
            switch sound.rawValue {
            case "bob":
                starling.load(resource: sound.rawValue, type: "wav", for: SoundIdentifier("Bob"))
            case "single":
                starling.load(resource: sound.rawValue, type: "wav", for: SoundIdentifier("Single"))
            case "go":
                starling.load(resource: sound.rawValue, type: "wav", for: SoundIdentifier("Go"))
            case "look":
                starling.load(resource: sound.rawValue, type: "wav", for: SoundIdentifier("Look to"))
            case "stand":
                starling.load(resource: sound.rawValue, type: "wav", for: SoundIdentifier("Stand next"))
            case "all":
                starling.load(resource: sound.rawValue, type: "wav", for: SoundIdentifier("That's all"))
            default:
                starling.load(resource: sound.rawValue, type: "wav", for: SoundIdentifier(sound.rawValue))
            }
        }
    }
    
    func play(_ file:String) {
        
        
        var fileName = file
        
        if file.first! == "C" {
            fileName.removeFirst()
        }
        
        starling.play(SoundIdentifier(fileName))
    }
}

