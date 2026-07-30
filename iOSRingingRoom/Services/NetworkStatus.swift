//
//  NetworkStatus.swift
//  NewRingingRoom
//
//  Created by Matthew on 22/10/2021.
//

import Foundation
import Network

enum NetworkAvailability: Equatable {
    case unknown
    case connected
    case disconnected
}

@MainActor
class NetworkMonitor: ObservableObject {
    
    static let shared = NetworkMonitor()

    private init() {
        monitor = NWPathMonitor()
        status = monitor.currentPath.status
        startMonitoring()
    }

    var monitor: NWPathMonitor

    var isConnected: Bool {
        availability == .connected
    }
    
    @Published var status: NWPath.Status
    @Published private(set) var availability: NetworkAvailability = .unknown
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.availability = path.status == .satisfied ? .connected : .disconnected
                self.status = path.status
            }
        }
        let queue = DispatchQueue(label: "NetworkStatus_Monitor")
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        monitor.cancel()
    }
}
