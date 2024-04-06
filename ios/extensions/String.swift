extension String {
    func toCString() throws -> [CChar] {
        return try guardLet(self.cString(using: .utf8), AppError.cStringError)
    }

    static func random(_ length: Int) -> String {
        return String((0..<length).map { _ in
            "\"!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~".randomElement()!
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

