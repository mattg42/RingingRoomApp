//
//  NetworkStatus.swift
//  NewRingingRoom
//
//  Created by Matthew on 22/10/2021.
//

import Foundation
import Network

class NetworkMonitor: ObservableObject {
    
    static let shared = NetworkMonitor()

    private init() {
        monitor = NWPathMonitor()
        status = monitor.currentPath.status
        startMonitoring()
    }
    
    var monitor: NWPathMonitor

    var isConnected: Bool {
        return status == .satisfied
    }
    
    @Published var status: NWPath.Status
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            ThreadUtil.runInMain { [weak self] in
                guard let self = self else { return }
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
        stopMonitoring()
    }
}
