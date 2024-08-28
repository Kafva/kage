import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared
            .sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil)
    }

    func uiError(_ message: String, line: Int = #line, fileID: String = #fileID)
        -> String
    {
        G.logger.error(message, line: line, fileID: fileID)
        return message
    }

}
