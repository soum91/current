import Darwin
import Foundation

/// Reads kernel-maintained counters. Does not initiate a speed test or send data.
/// Apple exposes aggregate interface counters via getifaddrs, not per-app counts.
struct InterfaceSampler {
    struct Counters {
        let received: UInt32
        let sent: UInt32
    }

    static func snapshot() -> [String: Counters] {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0, let head = first else { return [:] }
        defer { freeifaddrs(head) }

        var result: [String: Counters] = [:]
        var cursor: UnsafeMutablePointer<ifaddrs>? = head
        while let node = cursor {
            let entry = node.pointee
            defer { cursor = entry.ifa_next }
            guard let address = entry.ifa_addr,
                  Int32(address.pointee.sa_family) == AF_LINK,
                  let data = entry.ifa_data else { continue }

            let name = String(cString: entry.ifa_name)
            // On iPhones, en* carries Wi-Fi and pdp_ip* carries cellular data.
            // Ignore AWDL, VPN, loopback and tunnel interfaces to avoid double-counting.
            guard name.hasPrefix("en") || name.hasPrefix("pdp_ip") else { continue }
            guard (entry.ifa_flags & UInt32(IFF_UP)) != 0 else { continue }

            let counters = data.assumingMemoryBound(to: if_data.self).pointee
            result[name] = Counters(received: counters.ifi_ibytes, sent: counters.ifi_obytes)
        }
        return result
    }

    static func difference(from old: [String: Counters], to current: [String: Counters]) -> (received: UInt64, sent: UInt64) {
        var received: UInt64 = 0
        var sent: UInt64 = 0
        for (name, value) in current {
            guard let previous = old[name] else { continue }
            // BSD's if_data uses 32-bit counters on some iOS versions.
            // Wrapping subtraction handles one rollover between adjacent samples.
            let down = UInt64(value.received &- previous.received)
            let up = UInt64(value.sent &- previous.sent)
            // Discard resets/multiple-rollover artifacts instead of showing absurd spikes.
            if down < 1_500_000_000 { received += down }
            if up < 1_500_000_000 { sent += up }
        }
        return (received, sent)
    }

    static func label(for interfaces: Set<String>) -> String {
        let wifi = interfaces.contains { $0.hasPrefix("en") }
        let mobile = interfaces.contains { $0.hasPrefix("pdp_ip") }
        switch (wifi, mobile) {
        case (true, true): return "Wi-Fi + Cellular"
        case (true, false): return "Wi-Fi"
        case (false, true): return "Cellular"
        default: return "No connection"
        }
    }
}
