import Foundation

struct CommitInfo: Identifiable {
    let id = UUID()
    let summary: String
    let date: String

    /// Create an object from a newline seperated string on the format
    /// `<epoch>\n<summary>`
    static func from(_ str: String) throws -> Self {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d HH:mm:ss yyyy"

        let spl = str.split(separator: "\n")
        if spl.count != 2 {
            throw AppError.invalidCommit
        }
        guard let epoch = TimeInterval(spl[0]) else {
            throw AppError.invalidCommit
        }

        let summary = String(spl[1])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let date = Date(timeIntervalSince1970: epoch)

        let dateStr = dateFormatter.string(from: date)
        return CommitInfo(summary: summary, date: dateStr)
    }
}
