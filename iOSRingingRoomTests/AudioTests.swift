import XCTest
@testable import Ringing_Room

@MainActor
final class AudioTests: XCTestCase {
    func testPreloadMapsEveryBundledSoundAndPreparesPlayback() async {
        let engine = AudioEngineSpy()
        let sut = AudioService(starling: engine)

        await sut.prepareToStart()

        XCTAssertTrue(sut.isReady)
        XCTAssertEqual(engine.prepareCount, 1)
        XCTAssertEqual(engine.loadedResources.count, SoundAsset.allCases.count)
        XCTAssertEqual(Set(engine.loadedResources.map(\.resource)), Set(SoundAsset.allCases.map(\.rawValue)))
        XCTAssertTrue(engine.loadedResources.allSatisfy { $0.type == "wav" })

        let identifiers = Dictionary(uniqueKeysWithValues: engine.loadedResources.map { ($0.resource, $0.identifier) })
        XCTAssertEqual(identifiers[SoundAsset.BOB.rawValue], "Bob")
        XCTAssertEqual(identifiers[SoundAsset.LOOKTO.rawValue], "Look to")
        XCTAssertEqual(identifiers[SoundAsset.STAND.rawValue], "Stand next")
        XCTAssertEqual(identifiers[SoundAsset.THATSALL.rawValue], "That's all")
        XCTAssertEqual(identifiers[SoundAsset.H1.rawValue], "H1")
    }

    func testVolumeAndPlaybackAreForwardedToInjectedEngine() async {
        let engine = AudioEngineSpy()
        let sut = AudioService(starling: engine)
        let playbackStarted = expectation(description: "Audio engine receives playback")
        engine.onPlay = {
            playbackStarted.fulfill()
        }

        await sut.prepareToStart()
        sut.changeVolume(to: 0.4)
        sut.play("H6f")
        await fulfillment(of: [playbackStarted], timeout: 1)

        XCTAssertEqual(engine.volume, 0.4)
        XCTAssertEqual(engine.playedSounds, ["H6f"])
    }
}
