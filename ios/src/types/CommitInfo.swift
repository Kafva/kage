import Foundation

struct CommitInfo: Identifiable {
    let id = UUID()
    let date: String
    let revstr: String
    let summary: String

    /// Create an object from a newline seperated string on the format
    /// `<epoch>\n<oid>\n<summary>`
    static func from(_ str: String) throws -> Self {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d HH:mm:ss yyyy"

        let spl = str.split(separator: "\n")
        if spl.count != 3 {
            throw AppError.invalidCommit
        }

        // First line: UNIX epoch
        guard let epoch = TimeInterval(spl[0]) else {
            throw AppError.invalidCommit
        }
        let date = Date(timeIntervalSince1970: epoch)
        let dateStr = dateFormatter.string(from: date)

        // Second line: Revision identifier
        let revstr = String(spl[1])

        // Third line: Summary
        let summary = String(spl[2])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return CommitInfo(date: dateStr, revstr: revstr, summary: summary)
    }
}
