extension String {
    func toCString() throws -> [CChar] {
        guard let value = self.cString(using: .utf8) else {
            throw AppError.cStringError
        }
        return value
    }

    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }

    static func random(_ length: Int) -> String {
        return String(
            (0..<length).map { _ in
                "\"!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
                    .randomElement()!
            })
    }

    var isPrintableASCII: Bool {
        for c in self {
            guard let ch = c.asciiValue else {
                return false
            }
            if ch < 0x20 || ch > 0x7e {
                return false
            }
        }

        return true
    }
}
