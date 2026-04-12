// ============================================================
// SetAvailabilityView.swift — Melissa's changes
// ============================================================
// - Created this screen so beauty pros can set their weekly schedule.
// - Each day (Mon–Sun) has a toggle; turning it on reveals
//   open/close hour pickers (6 AM – 10 PM range).
// - DayAvailability struct defined here — also shared with
//   BeautyProfileView so clients can see the pro's hours.
// - loadAvailability() pre-fills from "availability/{uid}" in Firestore.
// - saveAvailability() writes all 7 days to Firestore and shows
//   a green success message for 3 seconds.
// - Day rows animate smoothly when toggled.
// ============================================================

import SwiftUI
import FirebaseFirestore

struct SetAvailabilityView: View {
    let proUID: String

    private let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    @State private var availability: [String: DayAvailability] = [:]
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var saveSuccess = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Set your weekly availability so clients know when to book.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    VStack(spacing: 10) {
                        ForEach(days, id: \.self) { day in
                            DayRow(
                                day: day,
                                availability: Binding(
                                    get: { availability[day] ?? DayAvailability() },
                                    set: { availability[day] = $0 }
                                )
                            )
                        }
                    }

                    Button {
                        saveAvailability()
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save Availability")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isSaving)
                    .padding(.top, 8)

                    if saveSuccess {
                        Text("Availability saved successfully!")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .transition(.opacity)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationTitle("Set Availability")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadAvailability() }
    }

    private func loadAvailability() {
        guard !proUID.isEmpty else { return }
        isLoading = true

        Firestore.firestore().collection("availability").document(proUID).getDocument { doc, _ in
            isLoading = false
            guard let data = doc?.data() else { return }

            var loaded: [String: DayAvailability] = [:]
            for day in days {
                if let dayData = data[day] as? [String: Any] {
                    loaded[day] = DayAvailability(
                        isOn: dayData["isOn"] as? Bool ?? false,
                        startHour: dayData["startHour"] as? Int ?? 9,
                        endHour: dayData["endHour"] as? Int ?? 17
                    )
                }
            }
            availability = loaded
        }
    }

    private func saveAvailability() {
        guard !proUID.isEmpty else { return }
        isSaving = true
        saveSuccess = false

        var data: [String: Any] = [:]
        for day in days {
            let a = availability[day] ?? DayAvailability()
            data[day] = ["isOn": a.isOn, "startHour": a.startHour, "endHour": a.endHour]
        }

        Firestore.firestore().collection("availability").document(proUID).setData(data) { _ in
            isSaving = false
            withAnimation { saveSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { saveSuccess = false }
            }
        }
    }
}

struct DayAvailability {
    var isOn: Bool = false
    var startHour: Int = 9
    var endHour: Int = 17
}

private struct DayRow: View {
    let day: String
    @Binding var availability: DayAvailability

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(day)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $availability.isOn)
                    .labelsHidden()
                    .tint(.pink)
            }

            if availability.isOn {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opens")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Start", selection: $availability.startHour) {
                            ForEach(6..<22, id: \.self) { h in
                                Text(hourLabel(h)).tag(h)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.pink)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Closes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("End", selection: $availability.endHour) {
                            ForEach(6..<22, id: \.self) { h in
                                Text(hourLabel(h)).tag(h)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.pink)
                    }

                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: availability.isOn)
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return "\(h):00 \(suffix)"
    }
}

#Preview {
    NavigationStack {
        SetAvailabilityView(proUID: "previewUID")
    }
}
