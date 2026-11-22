//
//  ConnectionMonitor.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import Foundation
import Network
import Observation

@MainActor @Observable
final class ConnectionMonitor {
    private let monitor = NWPathMonitor()
    var connected = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in self?.connected = connected }
        }
        monitor.start(queue: DispatchQueue(label: "martem.network"))
    }

    deinit { monitor.cancel() }
}
