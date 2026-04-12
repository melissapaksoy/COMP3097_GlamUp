// Meric — Admin dashboard UI (layout, stat cards, Quick Actions cleanup)
// Meric - Wired Firestore metrics for Total Users and Active Bookings (AuthService + AdminDashboardViewModel)
// Kashfi - Created the template file with dummy buttons and navigation
// Melissa - Created the admin dashboard UI with metric cards, disputes list, quick actions, and logout.


import SwiftUI

// MARK: - GlamUp surfaces (aligned with HomeView / ProCardRow)

private enum GlamUpSurface {
    /// Same soft tint as `HomeView` scroll background.
    static let screenBackground = Color(red: 1.0, green: 0.97, blue: 0.99)
    static let cardFill = Color.white
    static let cardCornerRadius: CGFloat = 18
    static let actionCornerRadius: CGFloat = 14
    static let cardShadowColor = Color.black.opacity(0.04)
    static let cardShadowRadius: CGFloat = 6
    static let cardShadowY: CGFloat = 3
    static let outlinePink = Color.pink.opacity(0.18)
}

private enum AdminPanelLayout {
    static let sectionSpacing: CGFloat = 20
    static let cardSpacing: CGFloat = 12
    static let headerToContentSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = GlamUpSurface.cardCornerRadius
    static let listRowSpacing: CGFloat = 12
    static let actionButtonMinHeight: CGFloat = 48
    static let statCardHeight: CGFloat = 136
    static let statIconSlotWidth: CGFloat = 36
    static let statIconLabelSpacing: CGFloat = 8
    static let statHelperBandHeight: CGFloat = 44
    static let statValueTopPadding: CGFloat = 24
    static let disputeTitleToDetailSpacing: CGFloat = 8
    static let disputeDetailToTimeSpacing: CGFloat = 6
}

// MARK: - Card typography (hierarchy only; shared across stat + dispute cards)

private enum AdminCardTypography {
    static var statValue: Font { .title.bold() }
    static var disputeTitle: Font { .body.weight(.semibold) }
    static var statLabel: Font { .footnote }
    static var secondaryBody: Font { .subheadline }
    static var meta: Font { .caption2 }
}

struct AdminDashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var adminMetrics = AdminDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AdminPanelLayout.sectionSpacing) {

                // Top metrics (center alignment so fixed-height cards get a definite vertical proposal in the scroll view)
                HStack(alignment: .center, spacing: AdminPanelLayout.cardSpacing) {
                    MetricCard(
                        title: "Total Users",
                        value: adminMetrics.totalUsersDisplayValue,
                        delta: "Live count from Firestore",
                        deltaColor: .green,
                        symbol: "person.3.fill"
                    )

                    MetricCard(
                        title: "Active Bookings",
                        value: adminMetrics.activeBookingsDisplayValue,
                        delta: "Pending & approved",
                        deltaColor: .green,
                        symbol: "calendar.badge.clock"
                    )
                }

                HStack(alignment: .center, spacing: AdminPanelLayout.cardSpacing) {
                    SmallCard(
                        title: "Flagged Reviews",
                        value: "23",
                        subtitle: "Needs attention",
                        symbol: "flag.fill"
                    )

                    SmallCard(
                        title: "Open Disputes",
                        value: "8",
                        subtitle: "Pending resolution",
                        symbol: "exclamationmark.bubble.fill"
                    )
                }

                // Recent Disputes
                VStack(alignment: .leading, spacing: AdminPanelLayout.headerToContentSpacing) {
                    HStack(alignment: .firstTextBaseline, spacing: AdminPanelLayout.cardSpacing) {
                        Text("Recent Disputes")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Button("View All") {
                            // add action later
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.pink)
                        .lineLimit(1)
                    }

                    VStack(spacing: AdminPanelLayout.listRowSpacing) {
                        DisputeRow(
                            title: "Payment Dispute",
                            detail: "User claims unauthorized charge for booking #4321",
                            time: "2 hours ago",
                            priority: "High"
                        )

                        DisputeRow(
                            title: "Review Dispute",
                            detail: "Host disputes negative review claiming false information",
                            time: "6 hours ago",
                            priority: "Medium"
                        )

                        DisputeRow(
                            title: "Property Dispute",
                            detail: "Discrepancy in property amenities listed vs actual",
                            time: "1 day ago",
                            priority: "Low"
                        )
                    }
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: AdminPanelLayout.headerToContentSpacing) {
                    Text("Quick Actions")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: AdminPanelLayout.cardSpacing), count: 2),
                        spacing: AdminPanelLayout.cardSpacing
                    ) {
                        ActionButton(title: "Add User", systemImage: "person.badge.plus") {}
                        ActionButton(title: "Block User", systemImage: "person.fill.xmark") {}
                        ActionButton(title: "Reports", systemImage: "doc.text.magnifyingglass") {}
                        ActionButton(title: "Users", systemImage: "person.2") {}
                        ActionButton(title: "Bookings", systemImage: "calendar") {}
                        ActionButton(title: "Disputes", systemImage: "exclamationmark.bubble") {}
                    }
                }

                Spacer(minLength: AdminPanelLayout.sectionSpacing)
            }
            .padding(AdminPanelLayout.cardPadding)
        }
        .navigationTitle("Admin Panel")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .onAppear { adminMetrics.startObservingDashboardMetrics() }
        .onDisappear { adminMetrics.stopObservingDashboardMetrics() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Logout") {
                    authVM.signOut()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.pink)
            }
        }
        .background(GlamUpSurface.screenBackground)
    }
}

private struct AdminStatCardLayout<Helper: View>: View {
    let symbol: String
    let title: String
    let value: String
    @ViewBuilder let helperContent: () -> Helper

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AdminPanelLayout.statIconLabelSpacing) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(.pink.opacity(0.55))
                    .frame(width: AdminPanelLayout.statIconSlotWidth, alignment: .center)
                Text(title)
                    .font(AdminCardTypography.statLabel)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Color.clear
                .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .layoutPriority(1)
                .overlay(alignment: Alignment(horizontal: .leading, vertical: .center)) {
                    Text(value)
                        .font(AdminCardTypography.statValue)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.top, AdminPanelLayout.statValueTopPadding)
                }

            helperContent()
                .frame(
                    maxWidth: .infinity,
                    minHeight: AdminPanelLayout.statHelperBandHeight,
                    maxHeight: AdminPanelLayout.statHelperBandHeight,
                    alignment: .bottomLeading
                )
        }
        .padding(AdminPanelLayout.cardPadding)
        .frame(maxWidth: .infinity, minHeight: AdminPanelLayout.statCardHeight, maxHeight: AdminPanelLayout.statCardHeight, alignment: .topLeading)
        .background(GlamUpSurface.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AdminPanelLayout.cornerRadius, style: .continuous))
        .shadow(
            color: GlamUpSurface.cardShadowColor,
            radius: GlamUpSurface.cardShadowRadius,
            x: 0,
            y: GlamUpSurface.cardShadowY
        )
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let delta: String
    let deltaColor: Color
    var deltaMuted: Bool = true
    let symbol: String

    var body: some View {
        AdminStatCardLayout(symbol: symbol, title: title, value: value) {
            Text(delta)
                .font(AdminCardTypography.meta)
                .fontWeight(.regular)
                .foregroundStyle(deltaMuted ? deltaColor.opacity(0.55) : deltaColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SmallCard: View {
    let title: String
    let value: String
    let subtitle: String
    let symbol: String

    var body: some View {
        AdminStatCardLayout(symbol: symbol, title: title, value: value) {
            Text(subtitle)
                .font(AdminCardTypography.meta)
                .fontWeight(.regular)
                .foregroundStyle(Color.red.opacity(0.82))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
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
            return .pink
        default:
            return .pink.opacity(0.65)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AdminPanelLayout.cardSpacing) {
                Text(title)
                    .font(AdminCardTypography.disputeTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Text(priority)
                    .font(AdminCardTypography.meta)
                    .fontWeight(.semibold)
                    .foregroundStyle(priorityColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(priorityColor.opacity(0.12))
                    )
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            Text(detail)
                .font(AdminCardTypography.secondaryBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AdminPanelLayout.disputeTitleToDetailSpacing)

            Text(time)
                .font(AdminCardTypography.meta)
                .fontWeight(.regular)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .padding(.top, AdminPanelLayout.disputeDetailToTimeSpacing)
        }
        .padding(AdminPanelLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlamUpSurface.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AdminPanelLayout.cornerRadius, style: .continuous))
        .shadow(
            color: GlamUpSurface.cardShadowColor,
            radius: GlamUpSurface.cardShadowRadius,
            x: 0,
            y: GlamUpSurface.cardShadowY
        )
    }
}

private struct ActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AdminPanelLayout.cardSpacing) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(.pink.opacity(0.75))
                    .frame(width: 22, alignment: .center)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AdminPanelLayout.cardPadding)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: AdminPanelLayout.actionButtonMinHeight, alignment: .leading)
            .background(GlamUpSurface.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: GlamUpSurface.actionCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GlamUpSurface.actionCornerRadius, style: .continuous)
                    .stroke(GlamUpSurface.outlinePink, lineWidth: 1)
            )
            .shadow(
                color: GlamUpSurface.cardShadowColor,
                radius: GlamUpSurface.cardShadowRadius,
                x: 0,
                y: GlamUpSurface.cardShadowY
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView()
            .environmentObject(AuthViewModel())
    }
}
