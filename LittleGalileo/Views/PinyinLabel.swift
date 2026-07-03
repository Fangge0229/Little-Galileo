import SwiftUI

struct PinyinLabel: View {
    let chinese: String
    let pinyin: String
    var chineseFont: Font = .title2.bold()
    var pinyinFont: Font = .caption
    var chineseColor: Color = Color(hex: "FFF8E7")
    var pinyinColor: Color = Color(hex: "B8C4E0")

    var body: some View {
        VStack(spacing: 2) {
            Text(pinyin)
                .font(pinyinFont)
                .foregroundStyle(pinyinColor)
            Text(chinese)
                .font(chineseFont)
                .foregroundStyle(chineseColor)
        }
        .multilineTextAlignment(.center)
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
