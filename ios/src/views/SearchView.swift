import SwiftUI

struct SearchView: View {
    @Environment(\.screenDims) var screenDims
    @Binding var searchText: String

    var body: some View {
        let background = RoundedRectangle(cornerRadius: 5)
            .fill(TEXT_FIELD_BG_COLOR)

        return TextField("Search…", text: $searchText)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(TITLE3_FONT)
            .frame(width: 0.7 * screenDims.width)
            // Padding inside the textbox
            .padding(.all, 10)
            .background(background)
            .overlay(
                Group {
                    // Clear content button
                    if !searchText.isEmpty {
                        HStack {
                            Spacer()
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(BODY_FONT)
                                    .padding(.trailing, 10)
                            }
                        }
                    }
                })
    }
}
