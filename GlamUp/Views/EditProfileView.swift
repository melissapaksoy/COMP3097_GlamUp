// Melissa - Created edit profile screen so beauty pros can update their name, bio, specialty, price, and photo.

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var specialty: String = "Nail Artist"
    @State private var bio: String = ""
    @State private var priceFrom: String = ""

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var existingImageBase64: String? = nil

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var errorMessage: String? = nil

    private let specialties = [
        "Nail Artist", "Hair Stylist", "Makeup Artist",
        "Barber", "Esthetician", "Lash Technician", "Brow Artist"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: Profile photo
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else if let base64 = existingImageBase64,
                                  let data = Data(base64Encoded: base64),
                                  let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(Color.pink.opacity(0.12))
                                .overlay(
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.pink.opacity(0.5))
                                )
                        }
                    }
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 6)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.pink)
                            .background(Color.white.clipShape(Circle()))
                            .shadow(radius: 2)
                    }
                }
                .padding(.top, 8)
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            profileImage = img
                        }
                    }
                }

                // MARK: Fields
                VStack(spacing: 16) {
                    inputField(label: "Full Name", placeholder: "Your display name", text: $fullName)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Specialty").font(.headline)
                        Picker("Specialty", selection: $specialty) {
                            ForEach(specialties, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(.pink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio").font(.headline)
                        ZStack(alignment: .topLeading) {
                            if bio.isEmpty {
                                Text("Tell clients about your experience...")
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                            }
                            TextEditor(text: $bio)
                                .frame(height: 110)
                                .padding(8)
                                .background(Color.clear)
                        }
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Starting Price ($)").font(.headline)
                        TextField("e.g. 35", text: $priceFrom)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: Save button
                    Button { saveProfile() } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Profile")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(fullName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.pink.opacity(0.5) : Color.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isSaving || fullName.trimmingCharacters(in: .whitespaces).isEmpty)

                    if saveSuccess {
                        Text("Profile saved!")
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadProfile() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.headline)
            TextField(placeholder, text: text)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Firestore

    private func loadProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { isLoading = false; return }

        Firestore.firestore().collection("beautyProfessionals").document(uid).getDocument { doc, _ in
            isLoading = false
            guard let data = doc?.data() else { return }
            fullName = data["fullName"] as? String ?? ""
            specialty = data["specialty"] as? String ?? "Nail Artist"
            bio = data["bio"] as? String ?? ""
            if let price = data["priceFrom"] as? Double { priceFrom = String(format: "%.0f", price) }
            existingImageBase64 = data["profileImageBase64"] as? String
        }
    }

    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let email = Auth.auth().currentUser?.email else { return }
        let trimmedName = fullName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        var data: [String: Any] = [
            "uid": uid,
            "email": email,
            "fullName": trimmedName,
            "specialty": specialty,
            "bio": bio.trimmingCharacters(in: .whitespaces)
        ]

        if let price = Double(priceFrom.trimmingCharacters(in: .whitespaces)) {
            data["priceFrom"] = price
        }

        if let image = profileImage,
           let resized = resizeImage(image, maxDimension: 400),
           let jpegData = resized.jpegData(compressionQuality: 0.4) {
            data["profileImageBase64"] = jpegData.base64EncodedString()
        }

        Firestore.firestore().collection("beautyProfessionals").document(uid).setData(data, merge: true) { error in
            isSaving = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                withAnimation { saveSuccess = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { saveSuccess = false }
                }
            }
        }
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        guard ratio < 1 else { return image }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

#Preview {
    NavigationStack { EditProfileView() }
}
