import Foundation

extension Date {
    var shortFormatted: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
