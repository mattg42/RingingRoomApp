//
//import Foundation
//import AVFoundation
//
///// Typealias used for identifying specific sound effects
//public typealias SoundName = String
//
//public class AudioContoller {
//    
//    private var files:[String:AVAudioFile]
//    var engine = AVAudioEngine()
//    
//    public init() {
//        files = [String: AVAudioFile]()
//        engine.mainMixerNode
//        engine.prepare()
//        do {
//            try engine.start()
//        } catch {
//          // engine failed to start
//        }
//        
//        // Subscribe to notifications that occur when the device audio output changes
//        NotificationCenter.default.addObserver(self, selector: #selector(audioOutputChanged), name: Notification.Name.AVAudioEngineConfigurationChange, object: nil)
//
//    }
//    
//    public func load(_ sounds:Any, fileType:String, subdirectory:String = "") {
//        if let sounds = sounds as? [String] {
//            for sound in sounds {
//                loadFile(fileName: sound, fileType: fileType, subdirectory: subdirectory, key: sound)
//            }
//        } else if let sounds = sounds as? [SoundName:String] {
//            for sound in sounds {
//                loadFile(fileName: sound.value, fileType: fileType, subdirectory: subdirectory, key: sound.key)
//            }
//        } else {
//            print("invalid sounds input")
//        }
//        
//    }
//    
//    private func loadFile(fileName:String, fileType:String, subdirectory:String, key:SoundName) {
////        DispatchQueue.global(qos: .utility).async {
//            if let url = Bundle.main.url(forResource: fileName, withExtension: fileType, subdirectory: subdirectory) {
//                do {
//                    let audioFile = try AVAudioFile(forReading: url)
//                    print("key ---", key)
//                    self.files[key] = audioFile
//                    print(self.files)
//                } catch {
//                    print("error creating audio file")
//                }
//            } else {
//                print("resource not found")
//            }
////        }
//    }
//    
//    public func player(_ soundName:SoundName) -> AudioPlayer? {
//        let newPlayer = AudioPlayer()
//        print(files)
//        print("soundName", soundName)
//        if let file = files[soundName] {
//            newPlayer.file = file
//        } else {
//            print("File not loaded")
//            return nil
//        }
//        
//        engine.attach(newPlayer.node)
//        engine.connect(newPlayer.node, to: engine.mainMixerNode, format: nil)
//        return newPlayer
//    }
//    
//    public func removePlayer(_ player:AudioPlayer) {
//        engine.disconnectNodeOutput(player.node)
//        engine.detach(player.node)
//    }
//
//    @objc private func audioOutputChanged(notification:Notification) {
////        engine = AVAudioEngine()
////        if #available(iOS 13, *) {
////            let nodes = engine.attachedNodes
////
////
////            for node in nodes {
////                engine.attach(node)
////                engine.connect(node, to: engine.mainMixerNode, format: nil)
////            }
////        } else {
////            for player in connectedPlayers {
////                let node = player.node
////
////                engine.attach(node)
////                engine.connect(node, to: engine.mainMixerNode, format: nil)
////            }
////        }
////
////        do {
////            try engine.start()
////        } catch {
////          // engine failed to start
////        }
//    }
//    
//}
///// custom audio player
//
//public enum PlayerState {
//    case playing, stopped, paused
//}
//
//public class AudioPlayer:NSObject {
//            
//    var node:AVAudioPlayerNode!
//    fileprivate var file:AVAudioFile!
//    
//    var volume:Float {
//        set {
//            node.volume = newValue
//        }
//        get {
//            node.volume
//        }
//    }
//    
//    public var state = PlayerState.stopped
//    
//    override init() {
//        super.init()
//        self.node = AVAudioPlayerNode()
//    }
//    
//    public func play(at time:Double = 0, repeats:Bool = false, callback: @escaping (AudioPlayer) -> () = {_ in}) {
//        if time <= Double(file.length)/file.processingFormat.sampleRate {
//            if state == .paused {
//                node.play()
//            } else {
//                node.stop()
//                node.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { _ in
//                    callback(self)
//                }
//                
//        
//                node.play(at: AVAudioTime(sampleTime: AVAudioFramePosition(time * file.processingFormat.sampleRate), atRate: file.processingFormat.sampleRate))
//            }
//            state = .playing
//        }
//    }
//    
//
//    public func pause() {
//        node.pause()
//        state = .paused
//    }
//    
//    public func stop() {
//        node.stop()
//        state = .stopped
//    }
//    
//    public func end() {
//        node.engine?.detach(node)
//    }
//}
//
////extension AVAudioPlayerNode{
////
////    var current: TimeInterval {
////        if let nodeTime = lastRenderTime, let playerTime = playerTime(forNodeTime: nodeTime) {
////            return Double(playerTime.sampleTime) / playerTime.sampleRate
////        }
////        return 0
////    }
////}
//
//extension Array where Element == AudioPlayer {
//    mutating func remove(_ element:AudioPlayer) {
//        guard let index = self.firstIndex(where: { $0 == element }) else { return }
//        self.remove(at: index)
//    }
//}
//
////example use case
////let controller = AudioController()
////controller.load("exampleSound", type: "aifc")
////controller.play("exampleSound")
//
////controller.play("Bob", category: .alarm)
