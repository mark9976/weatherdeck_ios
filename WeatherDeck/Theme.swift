import SwiftUI

enum Theme {
    @AppStorage("isDarkMode") static var isDark: Bool = true

    static var bg: Color { isDark ? Color(red: 0.043, green: 0.059, blue: 0.078) : Color(red: 0.95, green: 0.96, blue: 0.97) }
    static var panel: Color { isDark ? Color(red: 0.078, green: 0.106, blue: 0.141) : Color.white }
    static var panel2: Color { isDark ? Color(red: 0.106, green: 0.145, blue: 0.188) : Color(red: 0.93, green: 0.94, blue: 0.95) }
    static var accent: Color { Color(red: 0.114, green: 0.435, blue: 0.878) }
    static var text: Color { isDark ? Color(red: 0.902, green: 0.933, blue: 0.973) : Color(red: 0.1, green: 0.1, blue: 0.15) }
    static var muted: Color { isDark ? Color(red: 0.541, green: 0.627, blue: 0.722) : Color(red: 0.45, green: 0.48, blue: 0.52) }
    static var warn: Color { Color(red: 0.878, green: 0.635, blue: 0.114) }
    static var danger: Color { Color(red: 0.878, green: 0.275, blue: 0.114) }
}