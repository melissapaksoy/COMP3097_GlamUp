// Melissa - Created services management screen so beauty pros can add and delete services saved to Firestore.

import SwiftUI
import FirebaseFirestore

struct ManageServicesView: View {
    let proUID: String

    @State private var services: [ProService] = []
    @State private var isLoading = false
    @State private var showAddSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if services.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "scissors")
                            .font(.system(size: 40))
                            .foregroundStyle(.pink.opacity(0.5))
                        Text("No services yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Tap + to add your first service")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    VStack(spacing: 12) {
                        ForEach(services) { service in
                            ServiceItemRow(service: service) {
                                deleteService(service)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationTitle("Manage Services")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .foregroundStyle(.pink)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddServiceSheet(proUID: proUID) {
                fetchServices()
            }
        }
        .onAppear { fetchServices() }
    }

    private func fetchServices() {
        guard !proUID.isEmpty else { return }
        isLoading = true

        Firestore.firestore()
            .collection("proServices")
            .whereField("proUserID", isEqualTo: proUID)
            .getDocuments { snapshot, _ in
                isLoading = false
                services = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let name = data["name"] as? String,
                        let duration = data["duration"] as? String,
                        let price = data["price"] as? String
                    else { return nil }
                    return ProService(id: doc.documentID, name: name, duration: duration, price: price)
                } ?? []
            }
    }

    private func deleteService(_ service: ProService) {
        Firestore.firestore().collection("proServices").document(service.id).delete { _ in
            withAnimation {
                services.removeAll { $0.id == service.id }
            }
        }
    }
}

struct ProService: Identifiable {
    let id: String
    let name: String
    let duration: String
    let price: String
}

private struct ServiceItemRow: View {
    let service: ProService
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .foregroundStyle(.pink)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.headline)
                Text("\(service.duration)  •  \(service.price)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

private struct AddServiceSheet: View {
    let proUID: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var duration = ""
    @State private var price = ""
    @State private var isSaving = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !duration.trimmingCharacters(in: .whitespaces).isEmpty &&
        !price.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                fieldBlock(label: "Service Name", placeholder: "e.g. Gel Manicure", text: $name)
                fieldBlock(label: "Duration", placeholder: "e.g. 45 min", text: $duration)
                fieldBlock(label: "Price", placeholder: "e.g. $35", text: $price)
                    .keyboardType(.default)
                Spacer()
            }
            .padding(20)
            .background(Color(red: 1.0, green: 0.97, blue: 0.99).ignoresSafeArea())
            .navigationTitle("Add Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.pink)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { saveService() }
                            .disabled(!isValid)
                            .foregroundStyle(.pink)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fieldBlock(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
            TextField(placeholder, text: text)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func saveService() {
        guard isValid else { return }
        isSaving = true

        let data: [String: Any] = [
            "proUserID": proUID,
            "name": name.trimmingCharacters(in: .whitespaces),
            "duration": duration.trimmingCharacters(in: .whitespaces),
            "price": price.trimmingCharacters(in: .whitespaces)
        ]

        Firestore.firestore().collection("proServices").addDocument(data: data) { _ in
            isSaving = false
            onSave()
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ManageServicesView(proUID: "previewUID")
    }
}
