import SwiftUI

struct SearchView: View {
    @Binding var searchText: String

    var body: some View {
        let background = RoundedRectangle(cornerRadius: 5)
                            .fill(G.textFieldBgColor)

        return TextField("Search", text: $searchText)
        .multilineTextAlignment(.center)
        .font(.system(size: 18))
        .frame(width: G.screenWidth*0.7)
        // Padding inside the textbox
        .padding([.leading, .trailing], 5)
        .padding([.bottom, .top], 5)
        .background(background)
        // Padding outside the textbox
        .overlay(Group {
            // Clear content button
            if !searchText.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        searchText = ""
                    } label: {
                      Image(systemName: "multiply.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 15))
                        .padding(.trailing, 5)
                    }
                }
            }
        })
    }
}


