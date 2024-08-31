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
}
