//
//  NetworkStatus.swift
//  NewRingingRoom
//
//  Created by Matthew on 22/10/2021.
//

import Foundation
import Network

//class NetworkStatus {
//    static let shared = NetworkStatus()
//    
//    private init() {
//        startMonitoring()
//    }
//    
//    var monitor: NWPathMonitor?
//
//    var isConnected: Bool {
//        guard let monitor = monitor else { return false }
//        return monitor.currentPath.status == .satisfied
//    }
//    
//    func startMonitoring() {
//        monitor = NWPathMonitor()
//        
//        let queue = DispatchQueue(label: "NetworkStatus_Monitor")
//        monitor?.start(queue: queue)
//    }
//    
//    func stopMonitoring() {
//        monitor?.cancel()
//        self.monitor = nil
//    }
//    
//    deinit {
//        stopMonitoring()
//    }
//    
//}
