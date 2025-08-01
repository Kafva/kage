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

    func formHeaderStyle() -> some View {
        return self.font(TITLE3_FONT)
            .padding(.bottom, 10)
            .padding(.top, 40)
            .lineLimit(1)
            .textCase(nil)
    }

    func uiError(_ message: String, line: Int = #line, fileID: String = #fileID)
        -> String
    {
        LOG.error(message, line: line, fileID: fileID)
        return message
    }

}
