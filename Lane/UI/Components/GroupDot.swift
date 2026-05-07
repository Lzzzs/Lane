import SwiftUI

struct GroupDot: View {
    let colorHex: String
    var icon: String? = nil
    var size: CGFloat = 8

    var body: some View {
        if let icon, !icon.isEmpty {
            Text(icon)
                .font(LaneFonts.medium(size: size + 2))
                .foregroundStyle(Color(hexString: colorHex))
        } else {
            Circle()
                .fill(Color(hexString: colorHex))
                .frame(width: size, height: size)
        }
    }
}
