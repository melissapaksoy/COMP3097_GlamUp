import SwiftUI

struct PrimaryButton: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(Color.pink)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SecondaryButton: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Color(red: 0.55, green: 0.05, blue: 0.29))
            .background(Color.pink.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct Chip: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.caption).bold()
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }
}

struct BackPillButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.pink)
                .padding(10)
                .background(Color.pink.opacity(0.15))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
