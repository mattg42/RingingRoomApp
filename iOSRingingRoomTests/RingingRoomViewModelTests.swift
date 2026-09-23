import Combine
import Foundation
import XCTest
@testable import Ringing_Room

final class SocketTransportSpy: SocketTransport, @unchecked Sendable {
    weak var delegate: (any SocketIODelegate)?
    var connectCompletion: (() -> ())?
    var sentEvents = [(name: String, payload: [String: Any])]()
    private(set) var connectCount = 0
    private(set) var disconnectCount = 0
    private(set) var resetCount = 0
    var onReset: (() -> Void)?

    func connect(completion: @escaping () -> ()) {
        connectCount += 1
        connectCompletion = completion
    }

    func triggerConnect() {
        connectCompletion?()
    }

    func reset() {
        resetCount += 1
        onReset?()
    }

    func disconnect() {
        disconnectCount += 1
    }

    func send(event: String, with data: [String: Any]) {
        sentEvents.append((event, data))
    }
}

@MainActor
final class AudioPlayingSpy: AudioPlaying {
    private(set) var prepared = false
    private(set) var changedVolumes = [Float]()
    private(set) var playedFiles = [String]()
    private(set) var pendingPlaybackCancellationCount = 0

    func prepareToStart() async {
        prepared = true
    }

    func changeVolume(to volume: Float) {
        changedVolumes.append(volume)
    }

    func play(_ file: String) {
        playedFiles.append(file)
    }

    func cancelPendingPlayback() {
        pendingPlaybackCancellationCount += 1
    }
}

@MainActor
final class RingingRoomViewModelTests: XCTestCase {
    func testConnectionTransitionsAndJoinPayload() {
        let socket = SocketTransportSpy()
        let audio = AudioPlayingSpy()
        let viewModel = makeViewModel(socket: socket, audio: audio)

        viewModel.connect()
        XCTAssertEqual(viewModel.connectionState, .connecting)
        XCTAssertTrue(socket.sentEvents.isEmpty)

        socket.triggerConnect()

        XCTAssertEqual(viewModel.connectionState, .authenticating)
        let join = XCTAssertNotNilAndReturn(socket.sentEvents.last)
        XCTAssertEqual(join?.name, "c_join")
        XCTAssertEqual(join?.payload["tower_id"] as? Int, 99)
        XCTAssertEqual(join?.payload["user_token"] as? String, "token")
        XCTAssertEqual(join?.payload["anonymous_user"] as? Bool, false)

        viewModel.disconnect()
        XCTAssertEqual(viewModel.connectionState, .disconnected)
        XCTAssertEqual(socket.disconnectCount, 1)
        XCTAssertEqual(viewModel.state.size, 0)
        XCTAssertTrue(viewModel.state.assignments.isEmpty)
        XCTAssertTrue(viewModel.state.bellStates.isEmpty)
        XCTAssertEqual(audio.pendingPlaybackCancellationCount, 1)
    }

    func testLeavingTowerCancelsBellWaitingForAudioActivation() async {
        let socket = SocketTransportSpy()
        let engine = DelayedActivationAudioEngineSpy()
        let audioService = AudioService(starling: engine)
        let viewModel = makeViewModel(socket: socket, audio: audioService)
        let activationStarted = expectation(description: "startup and bell playback await activation")
        let playbackReturned = expectation(description: "pending playback finishes after activation")

        engine.onActivationWaiterCountChanged = { waiterCount in
            if waiterCount == 2 {
                activationStarted.fulfill()
            }
        }
        engine.onPlaybackReturned = {
            playbackReturned.fulfill()
        }

        viewModel.didReceiveCall("Bob")
        await fulfillment(of: [activationStarted], timeout: 2)

        viewModel.leaveTower()
        engine.finishActivation()

        await fulfillment(of: [playbackReturned], timeout: 2)
        XCTAssertTrue(engine.playedSounds.isEmpty)
    }

    func testConnectionTimeoutIsDeterministicAndDisconnects() async {
        let socket = SocketTransportSpy()
        let scheduler = TaskSchedulerSpy()
        let viewModel = makeViewModel(socket: socket, scheduler: scheduler)

        viewModel.connect()
        XCTAssertEqual(scheduler.scheduled.map(\.nanoseconds), [20_000_000_000])

        await scheduler.runNext()

        XCTAssertEqual(viewModel.connectionState, .failed)
        XCTAssertEqual(socket.disconnectCount, 1)
        XCTAssertEqual(viewModel.state.size, 0)
    }

    func testSizingMaintainsAssignmentAndBellStateInvariants() {
        let socket = SocketTransportSpy()
        let viewModel = makeViewModel(socket: socket)
        viewModel.autoRotate = false

        viewModel.sizeDidChange(to: 6)

        XCTAssertEqual(viewModel.state.size, 6)
        XCTAssertEqual(viewModel.state.assignments.count, 6)
        XCTAssertEqual(viewModel.state.bellStates.count, 6)
        XCTAssertEqual(socket.sentEvents.last?.name, "c_request_global_state")

        viewModel.sizeDidChange(to: 6)
        XCTAssertEqual(socket.sentEvents.filter { $0.name == "c_request_global_state" }.count, 2)

        viewModel.state.assignments[0] = 7
        viewModel.sizeDidChange(to: 4)
        XCTAssertEqual(viewModel.state.size, 4)
        XCTAssertEqual(viewModel.state.assignments, [7, nil, nil, nil])
        XCTAssertEqual(viewModel.state.bellStates.count, 4)

        viewModel.sizeDidChange(to: 16)
        XCTAssertEqual(viewModel.state.size, 16)
        XCTAssertEqual(viewModel.state.assignments.count, 16)
        XCTAssertEqual(viewModel.state.bellStates.count, 16)
    }

    func testUserAssignmentsPerspectivePermissionsAndMessages() {
        let socket = SocketTransportSpy()
        let viewModel = makeViewModel(socket: socket, isHost: false)
        let alice = Ringer(name: "Alice", id: 7)
        viewModel.state.ringer = alice
        viewModel.state.users = [alice]
        viewModel.state.size = 6
        viewModel.state.assignments = Array(repeating: nil, count: 6)
        viewModel.state.bellStates = Array(repeating: .hand, count: 6)
        viewModel.autoRotate = true

        viewModel.didAssign(ringerID: 7, to: 3)
        XCTAssertEqual(viewModel.state.assignments[2], 7)
        XCTAssertEqual(viewModel.state.perspective, 3)

        viewModel.didAssign(ringerID: 0, to: 3)
        XCTAssertNil(viewModel.state.assignments[2])
        XCTAssertEqual(viewModel.state.perspective, 1)

        viewModel.didAssign(ringerID: 999, to: 3)
        XCTAssertNil(viewModel.state.assignments[2])

        viewModel.state.hostMode = true
        XCTAssertFalse(viewModel.hasPermissions)
        viewModel.state.hostMode = false
        XCTAssertTrue(viewModel.hasPermissions)

        viewModel.canSeeMessages = false
        viewModel.didReceiveMessage(Message(sender: "Alice", message: "Hello"))
        XCTAssertEqual(viewModel.state.newMessages, 1)
        XCTAssertEqual(viewModel.state.messages.count, 1)
        viewModel.canSeeMessages = true
        viewModel.didReceiveMessage(Message(sender: "Alice", message: "Seen"))
        XCTAssertEqual(viewModel.state.newMessages, 1)
        XCTAssertEqual(viewModel.state.messages.count, 2)
    }

    func testOutgoingPayloadsAndCallPlaybackUseInjectedAdapters() {
        let socket = SocketTransportSpy()
        let audio = AudioPlayingSpy()
        let viewModel = makeViewModel(socket: socket, audio: audio)
        viewModel.state.size = 6
        viewModel.state.assignments = Array(repeating: nil, count: 6)
        viewModel.state.bellStates = Array(repeating: .back, count: 6)
        viewModel.state.ringer = Ringer(name: "Alice", id: 7)

        viewModel.send(.bellRung(bell: 2, stroke: false))
        viewModel.send(.messageSent(message: "Hello", time: "12:00"))
        viewModel.send(.setWheatleySetting(setting: .pealSpeed(180)))
        viewModel.didReceiveCall("Bob")

        XCTAssertEqual(socket.sentEvents.map(\.name), ["c_bell_rung", "c_msg_sent", "c_wheatley_setting"])
        XCTAssertEqual(socket.sentEvents[0].payload["bell"] as? Int, 2)
        XCTAssertEqual(socket.sentEvents[0].payload["stroke"] as? Bool, false)
        XCTAssertEqual(socket.sentEvents[1].payload["user"] as? String, "test-user")
        XCTAssertEqual(socket.sentEvents[1].payload["msg"] as? String, "Hello")
        XCTAssertEqual((socket.sentEvents[2].payload["settings"] as? [String: Any])?["peal_speed"] as? Int, 180)
        XCTAssertEqual(audio.playedFiles, ["Bob"])
    }

    func testPreferencesControlInitialRotationAndPersistVolume() {
        let socket = SocketTransportSpy()
        let preferences = PreferencesSpy()
        preferences.values["autoRotate"] = false
        let audio = AudioPlayingSpy()
        let viewModel = makeViewModel(socket: socket, audio: audio, preferences: preferences)

        XCTAssertFalse(viewModel.autoRotate)

        viewModel.changeVolume(to: 0.5)

        XCTAssertEqual(preferences.values["volume"] as? Double, 0.5)
        XCTAssertEqual(audio.changedVolumes, [0.125])
    }

    func testInvalidEventsAreIgnoredAndLeaveReturnsHome() {
        let socket = SocketTransportSpy()
        let router = Router<MainRoute>(defaultRoute: .home)
        let viewModel = makeViewModel(socket: socket, router: router)
        viewModel.state.size = 6
        viewModel.state.assignments = Array(repeating: nil, count: 6)
        viewModel.state.bellStates = Array(repeating: .hand, count: 6)

        viewModel.sizeDidChange(to: 7)
        XCTAssertEqual(viewModel.state.size, 6)
        viewModel.didReceiveGlobalState(Array(repeating: .back, count: 5))
        XCTAssertEqual(viewModel.state.bellStates.map(\.boolValue), Array(repeating: true, count: 6))
        viewModel.bellDidRing(number: 0, globalState: viewModel.state.bellStates)
        viewModel.didAssign(ringerID: 7, to: 0)
        XCTAssertEqual(viewModel.state.assignments, Array(repeating: nil, count: 6))

        viewModel.leaveTower()
        XCTAssertEqual(socket.disconnectCount, 1)
        guard case .home = router.currentRoute else {
            return XCTFail("Expected the router to return home")
        }
    }

    func testRingBellSendsOnlyValidBellNumbers() {
        let socket = SocketTransportSpy()
        let viewModel = makeViewModel(socket: socket)
        viewModel.state.size = 6
        viewModel.state.bellStates = [.hand, .back, .hand, .back, .hand, .back]

        viewModel.ringBell(number: 2)

        XCTAssertEqual(socket.sentEvents.count, 1)
        XCTAssertEqual(socket.sentEvents[0].name, "c_bell_rung")
        XCTAssertEqual(socket.sentEvents[0].payload["bell"] as? Int, 2)
        XCTAssertEqual(socket.sentEvents[0].payload["stroke"] as? Bool, false)

        viewModel.ringBell(number: 0)
        viewModel.ringBell(number: 7)
        XCTAssertEqual(socket.sentEvents.count, 1)
    }

    func testConnectGuardsActiveStatesAndAllowsRecoverableStates() {
        let guardedStates: [SocketConnectionState] = [.connecting, .authenticating, .reconnecting, .joined]
        for state in guardedStates {
            let socket = SocketTransportSpy()
            let scheduler = TaskSchedulerSpy()
            let viewModel = makeViewModel(socket: socket, scheduler: scheduler)
            viewModel.connectionState = state

            viewModel.connect()

            XCTAssertEqual(socket.connectCount, 0, "connect should be guarded for \(state)")
            XCTAssertEqual(viewModel.connectionState, state)
        }

        let allowedStates: [SocketConnectionState] = [.idle, .failed, .disconnected]
        for state in allowedStates {
            let socket = SocketTransportSpy()
            let scheduler = TaskSchedulerSpy()
            let viewModel = makeViewModel(socket: socket, scheduler: scheduler)
            viewModel.connectionState = state

            viewModel.connect()

            XCTAssertEqual(socket.connectCount, 1, "connect should be allowed for \(state)")
            XCTAssertEqual(viewModel.connectionState, .connecting)
        }
    }

    func testResetSocketAndRetryConnectionResetStateBeforeConnecting() {
        let socket = SocketTransportSpy()
        let scheduler = TaskSchedulerSpy()
        let viewModel = makeViewModel(socket: socket, scheduler: scheduler)
        viewModel.connectionState = .joined
        viewModel.state.size = 6
        viewModel.state.assignments = Array(repeating: 7, count: 6)

        viewModel.resetSocket()

        XCTAssertEqual(socket.resetCount, 1)
        XCTAssertEqual(socket.connectCount, 1)
        XCTAssertEqual(viewModel.connectionState, .connecting)
        XCTAssertEqual(viewModel.state.size, 0)
        XCTAssertTrue(viewModel.state.assignments.isEmpty)

        viewModel.retryConnection()

        XCTAssertEqual(socket.resetCount, 2)
        XCTAssertEqual(socket.connectCount, 2)
        XCTAssertEqual(viewModel.connectionState, .connecting)
    }

    func testSocketLifecycleCallbacksTransitionAndIgnoreTerminalStates() {
        let socket = SocketTransportSpy()
        let scheduler = TaskSchedulerSpy()
        let viewModel = makeViewModel(socket: socket, scheduler: scheduler)

        viewModel.socketDidConnect()
        XCTAssertEqual(viewModel.connectionState, .authenticating)
        XCTAssertEqual(scheduler.scheduled.count, 1)

        viewModel.socketWillReconnect()
        XCTAssertEqual(viewModel.connectionState, .reconnecting)
        XCTAssertEqual(scheduler.scheduled.count, 2)

        viewModel.state.size = 6
        viewModel.state.assignments = Array(repeating: 7, count: 6)
        viewModel.state.bellStates = Array(repeating: .hand, count: 6)
        viewModel.socketDidDisconnect(reason: "network")
        XCTAssertEqual(viewModel.connectionState, .failed)
        XCTAssertEqual(viewModel.state.size, 0)

        viewModel.socketDidDisconnect(reason: "duplicate")
        XCTAssertEqual(viewModel.connectionState, .failed)

        let failedSocket = SocketTransportSpy()
        let failedViewModel = makeViewModel(socket: failedSocket)
        failedViewModel.connectionState = .failed
        failedViewModel.socketDidFail(message: "already failed")
        XCTAssertEqual(failedViewModel.connectionState, .failed)

        let disconnectedSocket = SocketTransportSpy()
        let disconnectedViewModel = makeViewModel(socket: disconnectedSocket)
        disconnectedViewModel.connectionState = .disconnected
        disconnectedViewModel.socketDidConnect()
        disconnectedViewModel.socketWillReconnect()
        disconnectedViewModel.socketDidDisconnect(reason: "ignored")
        disconnectedViewModel.socketDidFail(message: "ignored")
        XCTAssertEqual(disconnectedViewModel.connectionState, .disconnected)
    }

    func testSocketFailureMovesToReconnectAndSchedulesTimeout() {
        let socket = SocketTransportSpy()
        let scheduler = TaskSchedulerSpy()
        let viewModel = makeViewModel(socket: socket, scheduler: scheduler)
        viewModel.connectionState = .connecting

        viewModel.socketDidFail(message: "transport failed")

        XCTAssertEqual(viewModel.connectionState, .reconnecting)
        XCTAssertEqual(scheduler.scheduled.count, 1)
    }

    func testConnectionTimeoutIsCancelledAfterSocketConnectAndJoin() async {
        let socket = SocketTransportSpy()
        let scheduler = TaskSchedulerSpy()
        let viewModel = makeViewModel(socket: socket, scheduler: scheduler)

        viewModel.connect()
        let connectionTimeout = scheduler.scheduled[0]

        viewModel.socketDidConnect()
        let authenticationTimeout = scheduler.scheduled[1]
        await connectionTimeout.waitUntilCancelled()

        viewModel.userDidEnter(Ringer(name: "Alice", id: 7))
        await authenticationTimeout.waitUntilCancelled()

        XCTAssertEqual(viewModel.connectionState, .joined)
        XCTAssertTrue(viewModel.connected)
    }

    func testUserEntryDeduplicatesUsersAndLeaveCleansAssignments() {
        let socket = SocketTransportSpy()
        let viewModel = makeViewModel(socket: socket)
        let alice = Ringer(name: "Alice", id: 7)
        let bob = Ringer(name: "Bob", id: 8)
        viewModel.connectionState = .connecting
        viewModel.state.size = 4
        viewModel.state.assignments = [7, 8, 8, nil]

        viewModel.userDidEnter(alice)
        viewModel.userDidEnter(alice)
        viewModel.userDidEnter(bob)

        XCTAssertEqual(viewModel.state.users, [alice, bob])
        XCTAssertEqual(viewModel.state.ringer, alice)
        XCTAssertEqual(viewModel.connectionState, .joined)
        XCTAssertTrue(viewModel.connected)

        viewModel.userDidLeave(bob)

        XCTAssertEqual(viewModel.state.users, [alice])
        XCTAssertEqual(viewModel.state.assignments, [7, nil, nil, nil])
    }

    func testUserEntryIsIgnoredWhenDisconnectedAndSelfLeaveRoutesHome() {
        let ignoredSocket = SocketTransportSpy()
        let ignoredViewModel = makeViewModel(socket: ignoredSocket)
        ignoredViewModel.connectionState = .disconnected
        ignoredViewModel.userDidEnter(Ringer(name: "Ignored", id: 9))
        XCTAssertTrue(ignoredViewModel.state.users.isEmpty)
        XCTAssertFalse(ignoredViewModel.connected)

        let socket = SocketTransportSpy()
        let router = Router<MainRoute>(defaultRoute: .home)
        let viewModel = makeViewModel(socket: socket, router: router)
        let alice = Ringer(name: "Alice", id: 7)
        viewModel.state.ringer = alice
        viewModel.state.users = [alice]
        viewModel.state.size = 4
        viewModel.state.assignments = [7, nil, nil, nil]
        viewModel.connectionState = .joined

        viewModel.userDidLeave(alice)

        XCTAssertEqual(viewModel.connectionState, .disconnected)
        XCTAssertEqual(socket.disconnectCount, 1)
        XCTAssertTrue(viewModel.state.users.isEmpty)
        guard case .home = router.currentRoute else {
            return XCTFail("Self-leave should route home")
        }
    }

    func testMissingRingerUsesAlertAndSafeFallback() {
        let alerts = AlertPresenterSpy()
        let socket = SocketTransportSpy()
        let viewModel = makeViewModel(socket: socket, alertPresenter: alerts)

        let ringer = viewModel.unwrappedRinger

        XCTAssertEqual(ringer.ringerID, 0)
        XCTAssertEqual(alerts.presentedAlerts.count, 1)
        XCTAssertEqual(alerts.presentedAlerts[0].title, "An error occured")

        guard case .cancel(_, let action) = alerts.presentedAlerts[0].dismiss else {
            return XCTFail("Expected a leave action")
        }
        action?()
        XCTAssertEqual(socket.sentEvents.last?.name, "c_user_left")
    }

    func testLeaveTowerSendsLeaveBeforeDisconnectingOnlyWhenJoined() {
        let joinedSocket = SocketTransportSpy()
        let joinedViewModel = makeViewModel(socket: joinedSocket)
        joinedViewModel.connectionState = .joined

        joinedViewModel.leaveTower()

        XCTAssertEqual(joinedSocket.sentEvents.map(\.name), ["c_user_left"])
        XCTAssertEqual(joinedSocket.disconnectCount, 1)

        let idleSocket = SocketTransportSpy()
        let idleViewModel = makeViewModel(socket: idleSocket)

        idleViewModel.leaveTower()

        XCTAssertTrue(idleSocket.sentEvents.isEmpty)
        XCTAssertEqual(idleSocket.disconnectCount, 1)
    }

    func testGlobalStateAndUserListAcceptMatchingValuesAndRejectInvalidSizes() {
        let socket = SocketTransportSpy()
        let viewModel = makeViewModel(socket: socket)
        let firstState = Array(repeating: BellStroke.hand, count: 6)
        let secondState = Array(repeating: BellStroke.back, count: 6)

        viewModel.didReceiveGlobalState(firstState)
        XCTAssertEqual(viewModel.state.size, 6)
        XCTAssertEqual(viewModel.state.bellStates.map(\.boolValue), firstState.map(\.boolValue))
        XCTAssertEqual(viewModel.state.assignments.count, 6)

        viewModel.didReceiveGlobalState(secondState)
        XCTAssertEqual(viewModel.state.bellStates.map(\.boolValue), secondState.map(\.boolValue))

        viewModel.didReceiveGlobalState(Array(repeating: .hand, count: 8))
        XCTAssertEqual(viewModel.state.bellStates.map(\.boolValue), secondState.map(\.boolValue))
        viewModel.didReceiveGlobalState(Array(repeating: .hand, count: 7))
        XCTAssertEqual(viewModel.state.bellStates.map(\.boolValue), secondState.map(\.boolValue))

        let users = [Ringer(name: "Alice", id: 7), Ringer(name: "Bob", id: 8)]
        viewModel.didReceiveUserList(users)
        XCTAssertEqual(viewModel.state.users, users)
    }

    func testBellPlaybackCoversAudioTypesAndTowerMufflingModes() {
        let cases: [(half: Bool, full: Bool, type: BellType, number: Int, state: [BellStroke], expected: String)] = [
            (false, false, .tower, 2, Array(repeating: .hand, count: 6), "T4"),
            (true, false, .tower, 2, Array(repeating: .hand, count: 6), "T4-muf"),
            (true, false, .tower, 2, Array(repeating: .back, count: 6), "T4"),
            (false, true, .tower, 2, Array(repeating: .hand, count: 6), "T4-muf"),
            (true, true, .tower, 2, Array(repeating: .hand, count: 6), "T4-muf"),
            (true, true, .tower, 6, Array(repeating: .hand, count: 6), "T8"),
            (true, true, .tower, 6, Array(repeating: .back, count: 6), "T8-muf"),
            (false, false, .hand, 2, Array(repeating: .hand, count: 6), "H8"),
            (false, false, .cowbell, 2, Array(repeating: .hand, count: 6), "C12")
        ]

        for testCase in cases {
            let audio = AudioPlayingSpy()
            let viewModel = makeViewModel(
                socket: SocketTransportSpy(),
                audio: audio,
                halfMuffled: testCase.half,
                fullyMuffled: testCase.full
            )
            viewModel.state.size = 6
            viewModel.state.bellType = testCase.type
            viewModel.state.bellStates = testCase.state

            viewModel.bellDidRing(number: testCase.number, globalState: testCase.state)

            XCTAssertEqual(audio.playedFiles, [testCase.expected], "Unexpected sound for \(testCase)")
        }

        let invalidAudio = AudioPlayingSpy()
        let invalidViewModel = makeViewModel(socket: SocketTransportSpy(), audio: invalidAudio)
        invalidViewModel.state.size = 6
        invalidViewModel.state.bellStates = Array(repeating: .hand, count: 6)
        invalidViewModel.bellDidRing(number: 0, globalState: invalidViewModel.state.bellStates)
        invalidViewModel.bellDidRing(number: 1, globalState: Array(repeating: .hand, count: 5))
        XCTAssertTrue(invalidAudio.playedFiles.isEmpty)
    }

    func testAudioAndHostModeCallbacksUpdateState() {
        let viewModel = makeViewModel(socket: SocketTransportSpy())

        viewModel.audioDidChange(to: .hand)
        viewModel.hostModeDidChange(to: true)

        XCTAssertEqual(viewModel.state.bellType.rawValue, BellType.hand.rawValue)
        XCTAssertTrue(viewModel.state.hostMode)
    }

    func testEveryClientSocketEventSendsItsExpectedPayload() {
        let socket = SocketTransportSpy()
        let viewModel = makeViewModel(socket: socket)
        let rowGen = ["type": "method", "title": "Plain Bob"] as [String: Any]

        func assertLastEvent(
            _ name: String,
            _ payload: [String: Any],
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            guard let event = socket.sentEvents.last else {
                return XCTFail("Expected \(name)", file: file, line: line)
            }
            XCTAssertEqual(event.name, name, file: file, line: line)
            XCTAssertTrue(
                NSDictionary(dictionary: event.payload).isEqual(to: payload),
                "Unexpected payload: \(event.payload)",
                file: file,
                line: line
            )
        }

        viewModel.send(.join)
        assertLastEvent("c_join", ["tower_id": 99, "user_token": "token", "anonymous_user": false])
        viewModel.send(.leaveTower)
        assertLastEvent("c_user_left", ["user_name": "test-user", "tower_id": 99, "user_token": "token", "anonymous_user": false])
        viewModel.send(.requestGlobalState)
        assertLastEvent("c_request_global_state", ["tower_id": 99])
        viewModel.send(.bellRung(bell: 2, stroke: true))
        assertLastEvent("c_bell_rung", ["bell": 2, "stroke": true, "tower_id": 99])
        viewModel.send(.assignUser(bell: 3, user: 7))
        assertLastEvent("c_assign_user", ["tower_id": 99, "bell": 3, "user": 7])
        viewModel.send(.unassignBell(bell: 3))
        assertLastEvent("c_assign_user", ["tower_id": 99, "bell": 3, "user": 0])
        viewModel.send(.audioChange(to: .hand))
        assertLastEvent("c_audio_change", ["tower_id": 99, "new_audio": "Hand"])
        viewModel.send(.hostModeSet(to: true))
        assertLastEvent("c_host_mode", ["tower_id": 99, "new_mode": true])
        viewModel.send(.sizeChange(to: 8))
        assertLastEvent("c_size_change", ["tower_id": 99, "new_size": 8])
        viewModel.send(.messageSent(message: "Hello", time: "12:00"))
        assertLastEvent("c_msg_sent", ["user": "test-user", "msg": "Hello", "tower_id": 99, "time": "12:00"])
        viewModel.send(.call("Bob"))
        assertLastEvent("c_call", ["call": "Bob", "tower_id": 99])
        viewModel.send(.setBells)
        assertLastEvent("c_set_bells", ["tower_id": 99])
        viewModel.send(.setWheatleySetting(setting: .pealSpeed(180)))
        assertLastEvent("c_wheatley_setting", ["tower_id": 99, "settings": ["peal_speed": 180]])
        viewModel.send(.setWheatleyRowGen(rowGen: rowGen))
        assertLastEvent("c_wheatley_row_gen", ["tower_id": 99, "row_gen": rowGen])
        viewModel.send(.wheatleyStopTouch)
        assertLastEvent("c_wheatley_stop_touch", ["tower_id": 99])
        viewModel.send(.resetWheatley)
        assertLastEvent("c_reset_wheatley", ["tower_id": 99])
    }

    func testEveryWheatleyCallbackUpdatesState() {
        let viewModel = makeViewModel(socket: SocketTransportSpy())
        let rowGen = RowGen.comp(WheatleyComp(title: "Test composition", url: "https://complib.org/1"))

        viewModel.rowGenDidChange(to: rowGen)
        viewModel.pealSpeedDidChange(to: 200)
        viewModel.fixedStrikingIntervalDidChange(to: true)
        viewModel.wholePullAndOffDidChange(to: false)
        viewModel.stopAtRoundsDidChange(to: false)
        viewModel.callCompositionDidChange(to: false)
        viewModel.wheatleyStateDidChange(to: true)

        if case .comp(let composition) = viewModel.wheatleyState.rowGen {
            XCTAssertEqual(composition.title, "Test composition")
        } else {
            XCTFail("Expected the composition row generator")
        }
        XCTAssertEqual(viewModel.wheatleyState.pealSpeed, 200)
        XCTAssertTrue(viewModel.wheatleyState.fixedStrikingInterval)
        XCTAssertFalse(viewModel.wheatleyState.wholePullAndOff)
        XCTAssertFalse(viewModel.wheatleyState.stopAtRounds)
        XCTAssertFalse(viewModel.wheatleyState.callComposition)
        XCTAssertTrue(viewModel.wheatleyState.wheatleyIsRinging)
    }

    func testBadTokenRecoverySucceedsAndSuppressesDuplicates() async {
        let api = RingingRoomAPIClientSpy()
        let socket = SocketTransportSpy()
        let alerts = AlertPresenterSpy()
        let viewModel = makeViewModel(socket: socket, apiService: api, alertPresenter: alerts)
        let reset = expectation(description: "socket reset after token recovery")
        socket.onReset = { reset.fulfill() }

        viewModel.didReceiveBadToken()
        await api.waitUntilUpdateStarts()
        viewModel.didReceiveBadToken()
        XCTAssertEqual(api.updateTokenCallCount, 1)

        api.release()
        await fulfillment(of: [reset], timeout: 1)
        await api.waitUntilUpdateFinishes()

        XCTAssertEqual(api.token, "refreshed-token")
        XCTAssertEqual(socket.resetCount, 1)
        XCTAssertEqual(socket.connectCount, 1)
        XCTAssertTrue(alerts.handledErrors.isEmpty)
        XCTAssertTrue(alerts.presentedAlerts.isEmpty)
    }

    func testBadTokenAPIErrorFailsConnectionAndUsesAlertHandler() async {
        let api = RingingRoomAPIClientSpy()
        api.updateTokenError = APIError.unauthorized
        let alerts = AlertPresenterSpy()
        let handled = expectation(description: "API error handled")
        alerts.onHandle = { handled.fulfill() }
        let viewModel = makeViewModel(socket: SocketTransportSpy(), apiService: api, alertPresenter: alerts)

        viewModel.didReceiveBadToken()
        await api.waitUntilUpdateStarts()
        api.release()
        await fulfillment(of: [handled], timeout: 1)

        XCTAssertEqual(viewModel.connectionState, .failed)
        XCTAssertEqual(alerts.handledErrors.count, 1)
    }

    func testBadTokenUnknownErrorUsesPresentAlert() async {
        let api = RingingRoomAPIClientSpy()
        api.updateTokenError = TestError.forcedFailure
        let alerts = AlertPresenterSpy()
        let presented = expectation(description: "unknown error presented")
        alerts.onPresent = { presented.fulfill() }
        let viewModel = makeViewModel(socket: SocketTransportSpy(), apiService: api, alertPresenter: alerts)

        viewModel.didReceiveBadToken()
        await api.waitUntilUpdateStarts()
        api.release()
        await fulfillment(of: [presented], timeout: 1)

        XCTAssertEqual(viewModel.connectionState, .failed)
        XCTAssertEqual(alerts.presentedAlerts.count, 1)
        XCTAssertTrue(alerts.handledErrors.isEmpty)
    }

    func testBadTokenRecoveryCancellationDoesNotResetSocket() async {
        let api = RingingRoomAPIClientSpy()
        let socket = SocketTransportSpy()
        let alerts = AlertPresenterSpy()
        let viewModel = makeViewModel(socket: socket, apiService: api, alertPresenter: alerts)

        viewModel.didReceiveBadToken()
        await api.waitUntilUpdateStarts()
        viewModel.disconnect()
        api.release()
        await api.waitUntilUpdateFinishes()

        XCTAssertEqual(viewModel.connectionState, .disconnected)
        XCTAssertEqual(socket.resetCount, 0)
        XCTAssertTrue(alerts.handledErrors.isEmpty)
        XCTAssertTrue(alerts.presentedAlerts.isEmpty)
    }

    func testStaleBadTokenRecoveryCannotResetAfterGenerationChanges() async {
        let api = RingingRoomAPIClientSpy()
        let socket = SocketTransportSpy()
        let viewModel = makeViewModel(socket: socket, apiService: api)

        viewModel.didReceiveBadToken()
        await api.waitUntilUpdateStarts()
        viewModel.resetSocket()
        XCTAssertEqual(socket.resetCount, 1)

        api.release()
        await api.waitUntilUpdateFinishes()

        XCTAssertEqual(socket.resetCount, 1)
    }

    private func makeViewModel(
        socket: SocketTransportSpy,
        audio: any AudioPlaying = AudioPlayingSpy(),
        router: Router<MainRoute>? = nil,
        isHost: Bool = true,
        halfMuffled: Bool = false,
        fullyMuffled: Bool = false,
        preferences: any PreferencesStoring = UserDefaultsPreferences(),
        scheduler: any TaskScheduling = LiveTaskScheduler(),
        apiService: (any RingingRoomAPIClient)? = nil,
        alertPresenter: any AlertPresenting = SystemAlertPresenter()
    ) -> RingingRoomViewModel {
        let defaults = makeIsolatedDefaults()
        let credentials = SessionCredentials(email: "test@example.com", password: "secret")
        let defaultAPIService = APIService(
            token: "token",
            region: .uk,
            credentials: credentials,
            urlSession: makeTestURLSession(),
            credentialStore: SessionCredentialStore(userDefaults: defaults, passwordStore: InMemoryPasswordStore())
        )
        let details = APIModel.TowerDetails(
            tower_id: 99,
            tower_name: "Test Tower",
            server_address: "https://ringingroom.com",
            additional_sizes_enabled: true,
            host_mode_permitted: true,
            half_muffled: halfMuffled,
            fully_muffled: fullyMuffled
        )
        let actualRouter = router ?? Router<MainRoute>(defaultRoute: .home)
        return RingingRoomViewModel(
            socketIOService: socket,
            router: actualRouter,
            towerInfo: TowerInfo(towerDetails: details, isHost: isHost),
            apiService: apiService ?? defaultAPIService,
            user: User(email: "test@example.com", username: "test-user", towers: []),
            audioService: audio,
            preferences: preferences,
            alertPresenter: alertPresenter,
            scheduler: scheduler
        )
    }
}

private func XCTAssertNotNilAndReturn<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) -> T? {
    XCTAssertNotNil(value, file: file, line: line)
    return value
}
