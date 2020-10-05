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
    case BOB      = "CBob"
    case GO       = "CGo"
    case LOOKTO   = "CLook to"
    case SINGLE   = "CSingle"
    case STAND    = "CStand next"
    case THATSALL = "CThat's all"
    
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
}

extension SoundAsset {
    var player:AVAudioPlayer {
        var thePlayer:AVAudioPlayer!
        if let url = Bundle.main.url(forResource: self.rawValue.replacingOccurrences(of: "C", with: ""), withExtension: ".aifc", subdirectory: "RingingRoomAudio") {
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
    
    var audioPlayers = [AVAudioPlayer]()
    var callPlayer:AVAudioPlayer!
    
    func play(_ file:String) {
        
        for type in SoundAsset.allCases {
            if type.rawValue == file {
                if type.rawValue.first == "C" {
                    self.callPlayer = type.player
                    self.callPlayer.play()
                } else {
                    let player = type.player
                    player.delegate = self
                    player.play()
                    BellCircle.current.timer.invalidate()
                    print(BellCircle.current.counter)
                    BellCircle.current.counter = 0
                    audioPlayers.append(player)
                }
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayers.remove(at: audioPlayers.firstIndex(of: player)!)
    }
}

