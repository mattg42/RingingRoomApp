//
//  AudioController.swift
//  iOSRingingRoom
//
//  Created by Matthew on 07/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import AVFoundation

enum SoundAsset : String, CaseIterable {
    case BOB      = "Bob"
    case GO       = "Go"
    case LOOKTO   = "Look to"
    case SINGLE   = "Single"
    case STAND    = "Stand next"
    case THATSALL = "That's all"
    
    case H1 = "H1"
    case H2 = "H2"
    case H3 = "H3"
    case H4 = "H4"
    case H5 = "H5"
    case H6 = "H6"
    case H7 = "H7"
    case H8 = "H8"
    case H9 = "H9"
    case H0 = "H0"
    case HE = "HE"
    case HT = "HT"
    
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
}

extension SoundAsset {
    var player:AVAudioPlayer {
        var thePlayer:AVAudioPlayer!
        if let url = Bundle.main.url(forResource: self.rawValue, withExtension: ".aifc", subdirectory: "RingingRoomAudio") {
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
    var bobPlayer:AVAudioPlayer!      = SoundAsset.BOB.player
    var goPlayer:AVAudioPlayer!       = SoundAsset.GO.player
    var lookToPlayer:AVAudioPlayer!   = SoundAsset.LOOKTO.player
    var singlePlayer:AVAudioPlayer!   = SoundAsset.SINGLE.player
    var standPlayer:AVAudioPlayer!    = SoundAsset.STAND.player
    var thatsAllPlayer:AVAudioPlayer! = SoundAsset.THATSALL.player
    
    var h1Player:AVAudioPlayer!       = SoundAsset.H1.player
    var h2Player:AVAudioPlayer!       = SoundAsset.H2.player
    var h3Player:AVAudioPlayer!       = SoundAsset.H3.player
    var h4Player:AVAudioPlayer!       = SoundAsset.H4.player
    var h5Player:AVAudioPlayer!       = SoundAsset.H5.player
    var h6Player:AVAudioPlayer!       = SoundAsset.H6.player
    var h7Player:AVAudioPlayer!       = SoundAsset.H7.player
    var h8Player:AVAudioPlayer!       = SoundAsset.H8.player
    var h9Player:AVAudioPlayer!       = SoundAsset.H9.player
    var h0Player:AVAudioPlayer!       = SoundAsset.H0.player
    var hEPlayer:AVAudioPlayer!       = SoundAsset.HE.player
    var hTPlayer:AVAudioPlayer!       = SoundAsset.HT.player
    
    var t1Player:AVAudioPlayer!       = SoundAsset.T1.player
    var t2Player:AVAudioPlayer!       = SoundAsset.T2.player
    var t2SPlayer:AVAudioPlayer!      = SoundAsset.T2S.player
    var t3Player:AVAudioPlayer!       = SoundAsset.T3.player
    var t4Player:AVAudioPlayer!       = SoundAsset.T4.player
    var t5Player:AVAudioPlayer!       = SoundAsset.T5.player
    var t6Player:AVAudioPlayer!       = SoundAsset.T6.player
    var t7Player:AVAudioPlayer!       = SoundAsset.T7.player
    var t8Player:AVAudioPlayer!       = SoundAsset.T8.player
    var t9Player:AVAudioPlayer!       = SoundAsset.T9.player
    var t0Player:AVAudioPlayer!       = SoundAsset.T0.player
    var tEPlayer:AVAudioPlayer!       = SoundAsset.TE.player
    var tTPlayer:AVAudioPlayer!       = SoundAsset.TT.player
    
    var t1MPlayer:AVAudioPlayer!       = SoundAsset.T1M.player
    var t2MPlayer:AVAudioPlayer!       = SoundAsset.T2M.player
    var t2SMPlayer:AVAudioPlayer!      = SoundAsset.T2SM.player
    var t3MPlayer:AVAudioPlayer!       = SoundAsset.T3M.player
    var t4MPlayer:AVAudioPlayer!       = SoundAsset.T4M.player
    var t5MPlayer:AVAudioPlayer!       = SoundAsset.T5M.player
    var t6MPlayer:AVAudioPlayer!       = SoundAsset.T6M.player
    var t7MPlayer:AVAudioPlayer!       = SoundAsset.T7M.player
    var t8MPlayer:AVAudioPlayer!       = SoundAsset.T8M.player
    var t9MPlayer:AVAudioPlayer!       = SoundAsset.T9M.player
    var t0MPlayer:AVAudioPlayer!       = SoundAsset.T0M.player
    var tEMPlayer:AVAudioPlayer!       = SoundAsset.TEM.player
    var tTMPlayer:AVAudioPlayer!       = SoundAsset.TTM.player
    
    var audioPlayers = [AVAudioPlayer]()
    
    var callPlayer:AVAudioPlayer!
    
    let starling = Starling()
    
    override init() {
        super.init()
        loadSounds()
    }
    
    func loadSounds() {
        for sound in SoundAsset.allCases {
            starling.load(resource: sound.rawValue, type: "aifc", for: SoundIdentifier(sound.rawValue))
        }
    }
    
    func play(_ file:String) {
        
        
        var fileName = file
        
        if file.first! == "C" {
            fileName.removeFirst()
        }
        
        starling.play(SoundIdentifier(fileName))
            
//        for type in SoundAsset.allCases {
//            if type.rawValue == fileName {
//                let player = type.player
//                player.delegate = self
//                player.play()
//                if isCall {
//                    callPlayer = player
//                    callPlayer.delegate = nil
//                } else {
//                    audioPlayers.append(player)
//                    print(audioPlayers.count)
//                }
//            }
//        }
        
    }
    
    func playBlank() {
//        let player = bobPlayer!
//        player.delegate = self
//        player.play(atTime: player.duration)
//        audioPlayers.append(player)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("audio finished")
        audioPlayers.remove(at: audioPlayers.firstIndex(of: player)!)
        print(self.audioPlayers.count)
    }
}

