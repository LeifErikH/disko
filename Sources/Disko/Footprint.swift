import Foundation

struct Footprint {
    struct Slice: Identifiable {
        let kind: Kind
        let finds: [Find]

        var id: Kind { kind }
        var bytes: Int64 { finds.reduce(0) { $0 + $1.bytes } }
        var biggest: Find? { finds.max { $0.bytes < $1.bytes } }
    }

    let agent: Agent
    let finds: [Find]

    var bytes: Int64 { finds.reduce(0) { $0 + $1.bytes } }

    var slices: [Slice] {
        Dictionary(grouping: finds, by: \.kind)
            .map { Slice(kind: $0.key, finds: $0.value) }
            .sorted { $0.bytes > $1.bytes }
    }
}

enum Bytes {
    static func short(_ bytes: Int64) -> String {
        let gigabytes = Double(bytes) / 1_073_741_824
        let megabytes = Double(bytes) / 1_048_576
        if gigabytes >= 10 { return "\(Int(gigabytes.rounded()))G" }
        if gigabytes >= 1 { return String(format: "%.1fG", gigabytes) }
        if megabytes >= 1 { return "\(Int(megabytes.rounded()))M" }
        return bytes > 0 ? "<1M" : "0"
    }

    static func long(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .binary)
    }
}
