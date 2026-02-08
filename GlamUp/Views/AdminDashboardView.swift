import SwiftUI

struct AdminDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Top metrics
                HStack(spacing: 12) {
                    MetricCard(title: "Total Users", value: "12,847", delta: "+2.5% from last month", deltaColor: .green, symbol: "person.3.fill")
                    MetricCard(title: "Active Bookings", value: "1,234", delta: "+1.1% from last week", deltaColor: .green, symbol: "calendar.badge.clock")
                }

                HStack(spacing: 12) {
                    SmallCard(title: "Flagged Reviews", value: "23", subtitle: "Needs attention", symbol: "flag.fill", tint: .orange)
                    SmallCard(title: "Open Disputes", value: "8", subtitle: "Pending resolution", symbol: "exclamationmark.bubble.fill", tint: .pink)
                }

                // Recent Disputes
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Disputes").font(.headline)
                        Spacer()
                        Button("View All") {}
                            .font(.subheadline)
                    }

                    VStack(spacing: 8) {
                        DisputeRow(title: "Payment Dispute", detail: "User claims unauthorized charge for booking #4321", time: "2 hours ago", priority: "High")
                        DisputeRow(title: "Review Dispute", detail: "Host disputes negative review claiming false information", time: "6 hours ago", priority: "Medium")
                        DisputeRow(title: "Property Dispute", detail: "Discrepancy in property amenities listed vs actual", time: "1 day ago", priority: "Low")
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Actions").font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ActionButton(title: "Add User", systemImage: "person.badge.plus") {}
                        ActionButton(title: "Block User", systemImage: "person.fill.xmark") {}
                        ActionButton(title: "Reports", systemImage: "doc.text.magnifyingglass") {}
                        ActionButton(title: "Settings", systemImage: "gearshape") {}
                        ActionButton(title: "Dashboard", systemImage: "rectangle.grid.2x2") {}
                        ActionButton(title: "Users", systemImage: "person.2") {}
                        ActionButton(title: "Bookings", systemImage: "calendar") {}
                        ActionButton(title: "Disputes", systemImage: "exclamationmark.bubble") {}
                    }
                }

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("Admin Panel")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackPillButton { dismiss() }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let delta: String
    let deltaColor: Color
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: symbol).foregroundStyle(.secondary)
                Spacer()
            }
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.title2).bold()
            Text(delta).font(.caption).foregroundStyle(deltaColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }
}

private struct SmallCard: View {
    let title: String
    let value: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                Text(value).font(.title3).bold()
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }
}

private struct DisputeRow: View {
    let title: String
    let detail: String
    let time: String
    let priority: String

    var priorityColor: Color {
        switch priority.lowercased() {
        case "high":
            return .red
        case "medium":
            return .orange
        case "low":
            return .gray
        default:
            return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline).bold()
                Spacer()
                Text(priority).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(priorityColor.opacity(0.2)))
                    .foregroundColor(priorityColor)
            }
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
            Text(time).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }
}

private struct ActionButton: View {
    let title: String
    let systemImage: String
    var action: () -> Void

    init(title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                Text(title).fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { AdminDashboardView() }
}
