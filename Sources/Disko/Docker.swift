import Foundation

enum Docker {
    static func finds() -> [Find] {
        guard let binary = binary,
              let output = Shell.run(binary, ["system", "df", "-v", "--format", "{{json .}}"], timeout: 20),
              let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [] }

        let images = rows(json["Images"]).compactMap { row -> Find? in
            let name = "\(row["Repository"] ?? ""):\(row["Tag"] ?? "")"
            return find(named: name, label: "image \(name)", size: row["UniqueSize"] ?? row["Size"])
        }
        let containers = rows(json["Containers"]).compactMap { row -> Find? in
            let name = "\(row["Names"] ?? "") \(row["Image"] ?? "")"
            return find(named: name, label: "container \(row["Names"] ?? "")", size: row["Size"])
        }
        let volumes = rows(json["Volumes"]).compactMap { row -> Find? in
            let name = row["Name"] ?? ""
            return find(named: name, label: "volume \(name)", size: row["Size"])
        }
        return images + containers + volumes
    }

    private static var binary: String? {
        ["/usr/local/bin/docker", "/opt/homebrew/bin/docker", URL.home(".orbstack/bin/docker").path(), URL.home(".docker/bin/docker").path()]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func rows(_ value: Any?) -> [[String: String]] {
        (value as? [[String: Any]] ?? []).map { $0.compactMapValues { "\($0)" } }
    }

    private static func find(named name: String, label: String, size: String?) -> Find? {
        guard let agent = Agent.allCases.first(where: { $0.claims(name) }) else { return nil }
        return Find(agent: agent, kind: .docker, label: label, bytes: bytes(from: size ?? ""))
    }

    static func bytes(from text: String) -> Int64 {
        let units: [String: Double] = ["B": 1, "KB": 1e3, "MB": 1e6, "GB": 1e9, "TB": 1e12]
        guard let match = text.firstMatch(of: /([\d.]+)\s*([kKMGT]?B)/),
              let number = Double(match.output.1),
              let unit = units[match.output.2.uppercased()]
        else { return 0 }
        return Int64(number * unit)
    }
}

enum Shell {
    static func run(_ binary: String, _ arguments: [String], timeout: TimeInterval = 120) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(filePath: binary)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        guard (try? process.run()) != nil else { return nil }
        let deadline = DispatchWorkItem { process.terminate() }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: deadline)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        deadline.cancel()
        return String(data: data, encoding: .utf8)
    }
}
