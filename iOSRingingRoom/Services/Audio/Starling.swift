//
//  Starling
//
//  Released under: MIT License
//  Copyright (c) 2018 by Matt Reagan
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import AVFoundation
import Dispatch

/// Typealias used for identifying specific sound effects
public typealias SoundIdentifier = String

/// Errors specific to Starling's loading or playback functions
enum StarlingError: Error {
    case resourceNotFound(name: String)
    case invalidSoundIdentifier(name: String)
    case audioLoadingFailure
    case engineIsStopped
}

@MainActor
public class Starling {
    
    /// Defines the number of players which Starling instantiates
    /// during initialization. If more concurrent sounds than this
    /// are requested at any point, Starling will allocate additional
    /// players as needed, up to `maximumTotalPlayers`.
    private static let defaultStartingPlayerCount = 8
    
    /// Defines the total number of concurrent sounds which Starling
    /// will allow to be played at the same time. If (N) sounds are
    /// already playing and another play() request is made, it will
    /// be ignored (not queued).
    private static let maximumTotalPlayers = 20
    
 // MARK: - Internal Properties
    
    private var players: [StarlingAudioPlayer]
    private var files: [String: AVAudioFile]
    private let engine = AVAudioEngine()
    private let audioSessionController = AudioSessionController()
    private let notificationObservers = NotificationObserverStore()
    private var isInterrupted = false
    private var isAudioSessionConfigured = false
    private var engineStartTask: Task<Void, Never>?

    // MARK: - Error handling

    @MainActor public static var nonFatalErrorHandler: ((Error) -> Void)? = nil

    // MARK: - Initializer
    
    public init() {
        assert(Starling.defaultStartingPlayerCount <= Starling.maximumTotalPlayers, "Invalid starting and max audio player counts.")
        assert(Starling.defaultStartingPlayerCount > 0, "Starting audio player count must be > 0.")
        
        players = [StarlingAudioPlayer]()
        files = [String: AVAudioFile]()

        createInitialPlayers()
        
        let volume = UserDefaults.standard.optionalDouble(forKey: "volume") ?? 1
        let mappedVolume = pow(volume, 3)
        changeVolume(to: Float(mappedVolume))
        
        observeAudioEvents()
    }

    // MARK: - Public API (Change volume)
    public func changeVolume(to volume: Float) {
        engine.mainMixerNode.outputVolume = volume
    }
    
    // MARK: - Public API (Loading Sounds)
    
    public func load(resource: String, type: String, for identifier: SoundIdentifier, in bundle: Bundle? = nil) {
        if let url = (bundle ?? Bundle.main).url(forResource: resource, withExtension: type) {
            load(sound: url, for: identifier)
        } else {
            handleNonFatalError(StarlingError.resourceNotFound(name: "\(resource).\(type)"))
        }
    }
    
    public func load(sound url: URL, for identifier: SoundIdentifier) {
        if let file = try? AVAudioFile(forReading: url) {
            didFinishLoadingAudioFile(file, identifier: identifier)
        } else {
            handleNonFatalError(StarlingError.audioLoadingFailure)
        }
    }
    
    // MARK: - Public API (Playback)
    
    public func prepareToStart() async {
        guard !engine.isRunning, !isInterrupted else { return }

        if let engineStartTask {
            await engineStartTask.value
            return
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            if !(await self.startEngine()) {
                self.resetPlayersAndEngine()
                _ = await self.startEngine()
            }

            self.engineStartTask = nil
        }
        engineStartTask = task
        await task.value
    }
    
    public func play(_ sound: SoundIdentifier, allowOverlap: Bool = true) async {
        await prepareToStart()
        guard !Task.isCancelled else { return }
        performSoundPlayback(sound, allowOverlap: allowOverlap)
    }
    
    public func stop(_ sound: SoundIdentifier) {
        performSoundStop(sound)
    }

    // MARK: - Internal Functions
    
    private func performSoundPlayback(_ sound: SoundIdentifier, allowOverlap: Bool) {
        let file = files[sound]
        
        guard let audio = file else {
            handleNonFatalError(StarlingError.invalidSoundIdentifier(name: sound))
            return
        }
        
        func performPlaybackOnFirstAvailablePlayer() {
            guard engine.isRunning else {
                handleNonFatalError(StarlingError.engineIsStopped)
                return
            }

            guard let player = firstAvailablePlayer() else { return }
            player.play(audio, identifier: sound)
        }
        
        if allowOverlap {
           performPlaybackOnFirstAvailablePlayer()
        } else {
            if !soundIsCurrentlyPlaying(sound) {
                performPlaybackOnFirstAvailablePlayer()
            }
        }
    }

    public func performSoundStop(_ sound: SoundIdentifier)  {
        // TODO: This O(n) loop could be eliminated by simply keeping a playback tally.
        for player in players where player.state.status != .idle && player.state.sound == sound {
            player.stop(identifier: sound)
        }
    }

    private func soundIsCurrentlyPlaying(_ sound: SoundIdentifier) -> Bool {
        // TODO: This O(n) loop could be eliminated by simply keeping a playback tally
        for player in players {
            let state = player.state
            if state.status != .idle && state.sound == sound {
                return true
            }
        }
        return false
    }
    
    private func firstAvailablePlayer() -> StarlingAudioPlayer? {
        // TODO: A better solution would be to actively manage a pool of available player references
        // For almost every general use case of this library, however, this performance penalty is trivial
        if let player = players.first(where: { $0.state.status == .idle }) {
            return player
        }

        guard players.count < Starling.maximumTotalPlayers else { return nil }
        let player = createNewPlayerAttachedToEngine()
        players.append(player)
        return player
    }
    
    private func createNewPlayerAttachedToEngine() -> StarlingAudioPlayer {
        let player = StarlingAudioPlayer()
        engine.attach(player.node)
        engine.connect(player.node, to: engine.mainMixerNode, format: nil)
        return player
    }
    
    private func didFinishLoadingAudioFile(_ file: AVAudioFile, identifier: SoundIdentifier) {
        files[identifier] = file
    }
        
    private func createInitialPlayers() {
        for _ in 0..<Starling.defaultStartingPlayerCount {
            players.append(createNewPlayerAttachedToEngine())
        }
    }
    
    @discardableResult private func startEngine() async -> Bool {
        guard !isInterrupted else { return false }
        guard !engine.isRunning else { return true }

        do {
            if !isAudioSessionConfigured {
                try await audioSessionController.configure()
                isAudioSessionConfigured = true
            }
            try await audioSessionController.activate()
            guard !isInterrupted else { return false }
            guard !engine.isRunning else { return true }

            engine.prepare()
            try engine.start()
        } catch {
            handleNonFatalError(error)
            return false
        }

        return true
    }
    
    private func resetPlayersAndEngine() {
        guard !isInterrupted else { return }

        engine.stop()
        engine.reset()
        players.removeAll()
        createInitialPlayers()
    }
    
    private func handleNonFatalError(_ error: Error) {
        AppLogger.audio.error("Audio error: \(String(describing: error), privacy: .private)")
        Self.nonFatalErrorHandler?(error)
    }

    private func observeAudioEvents() {
        let notificationCenter = NotificationCenter.default

        notificationObservers.append(
            notificationCenter.addObserver(
                forName: .AVAudioEngineConfigurationChange,
                object: engine,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.recoverFromAudioConfigurationChange()
                }
            }
        )

        notificationObservers.append(
            notificationCenter.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { [weak self] notification in
                let interruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                let interruptionOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
                Task { @MainActor [weak self] in
                    await self?.handleAudioInterruption(type: interruptionType, options: interruptionOptions)
                }
            }
        )

        notificationObservers.append(
            notificationCenter.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.recoverFromAudioConfigurationChange()
                }
            }
        )
    }

    private func handleAudioInterruption(type rawType: UInt?, options rawOptions: UInt?) async {
        guard let rawType,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch interruptionType {
        case .began:
            isInterrupted = true
            engine.pause()
        case .ended:
            isInterrupted = false
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions ?? 0)
            if options.contains(.shouldResume) {
                await recoverFromAudioConfigurationChange()
            }
        @unknown default:
            break
        }
    }

    private func recoverFromAudioConfigurationChange() async {
        guard !isInterrupted else { return }

        engine.stop()
        for player in players {
            engine.disconnectNodeOutput(player.node)
            engine.connect(player.node, to: engine.mainMixerNode, format: nil)
        }
        engine.disconnectNodeOutput(engine.mainMixerNode)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: nil)

        await prepareToStart()
    }
    
    // MARK: - Debugging / Diagnostics
    
    private var diagnosticTimer: Timer? = nil
    public func beginPeriodicDiagnostics() {
        guard diagnosticTimer == nil else { return }
        diagnosticTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(diagnosticTimerFire(_:)), userInfo: nil, repeats: true)
    }
    
    public func stopDiagnostics() {
        diagnosticTimer?.invalidate()
        diagnosticTimer = nil
    }
    
    @objc private func diagnosticTimerFire(_ timer: Timer) {
        let loadedFileCount = files.count
        AppLogger.audio.debug("Audio diagnostics: \(loadedFileCount, privacy: .public) files loaded")
        let playerCount = players.count
        let playingCount = players.filter({ $0.state.status != .idle }).count
        AppLogger.audio.debug("Audio diagnostics: \(playerCount, privacy: .public) players, \(playingCount, privacy: .public) currently playing")
        for (index, player) in players.enumerated() {
            let status = player.state.status == .idle ? "Idle" : "Playing"
            AppLogger.audio.debug("Audio player \(index, privacy: .public): \(status, privacy: .public)")
        }
    }
}

/// Serializes AVAudioSession configuration and activation away from the main thread.
private final class AudioSessionController: @unchecked Sendable {
    private let audioSession = AVAudioSession.sharedInstance()
    private let sessionQueue = DispatchQueue(label: "com.ringingroom.audio-session", qos: .userInitiated)

    func configure() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [self] in
                do {
                    try audioSession.setCategory(
                        .playback,
                        mode: .default,
                        options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
                    )
                    try audioSession.setPreferredIOBufferDuration(0.002)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func activate() async throws {
        if #available(iOS 27.0, *) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                sessionQueue.async { [self] in
                    audioSession.activate(options: []) { activated, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if activated {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: AudioSessionControllerError.activationFailed)
                        }
                    }
                }
            }
        } else {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                sessionQueue.async { [self] in
                    do {
                        try audioSession.setActive(true)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

private enum AudioSessionControllerError: LocalizedError {
    case activationFailed

    var errorDescription: String? {
        "The audio session did not activate."
    }
}

/// Notification-center observer tokens are not Sendable, but this store is
/// only mutated on Starling's main-actor executor. It owns and unregisters
/// tokens without forcing Starling's nonisolated deinitializer to touch them.
private final class NotificationObserverStore: @unchecked Sendable {
    private var observers = [NSObjectProtocol]()

    func append(_ observer: NSObjectProtocol) {
        observers.append(observer)
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

/// The internal playback status. This is somewhat redundant at the moment given that
/// it should effectively mimic -isPlaying on the node, however it may be extended in
/// the future to represent other non-binary playback modes.
///
/// - idle: No sound is currently playing.
/// - playing: A sound is playing.
/// - looping: (Not currently implemented)
private enum PlayerStatus {
    case idle
    case playing
    case looping
}

private struct PlayerState {
    let sound: SoundIdentifier?
    let status: PlayerStatus
    
    static func idle() -> PlayerState {
        return PlayerState(sound: nil, status: .idle)
    }
}

@MainActor
private class StarlingAudioPlayer {
    let node = AVAudioPlayerNode()
    var state: PlayerState = PlayerState.idle()
    
    func play(_ file: AVAudioFile, identifier: SoundIdentifier) {
        node.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) {
            [weak self] callbackType in
            Task { @MainActor [weak self] in
                self?.didCompletePlayback(for: identifier)
            }
        }
        state = PlayerState(sound: identifier, status: .playing)
        node.play()
    }
    
    func stop(identifier: SoundIdentifier) {
        if state.status != .idle && state.sound == identifier {
            node.stop()
            state = .idle()
        }
    }
    
    func didCompletePlayback(for sound: SoundIdentifier) {
        state = PlayerState.idle()
    }
}

extension StarlingError: CustomStringConvertible {
    var description: String {
        switch self {
        case .resourceNotFound(let name):
            return "Resource not found '\(name)'"
        case .invalidSoundIdentifier(let name):
            return "Invalid identifier. No sound loaded named '\(name)'"
        case .audioLoadingFailure:
            return "Could not load audio data"
        case .engineIsStopped:
            return "The audio engine is stopped"
        }
    }
}
