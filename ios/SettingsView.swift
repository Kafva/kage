import SwiftUI
import OSLog


struct SettingsView: View {
    @AppStorage("tint") private var tint: String = ""
    @State private var selection: Color = .red

    var body: some View {
        VStack {
            ColorPicker("Accent color", selection: $selection, 
                                        supportsOpacity: false)
                .onChange(of: selection, initial: false) { oldColor, newColor in
                    logger.debug("Selected color changed to \(newColor)")
                    let data = try NSKeyedArchiver.archivedData(withRootObject: newColor, 
                                                                requiringSecureCoding: false)

                }
        }
        .padding()
    }
}

