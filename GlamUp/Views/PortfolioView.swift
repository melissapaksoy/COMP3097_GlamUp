// ============================================================
// PortfolioView.swift — Melissa's changes
// ============================================================
// - Created the portfolio management screen for beauty pros.
// - Shows up to 6 photos in a 3-column square grid.
// - "+" tile opens PhotosPicker to add a new photo.
// - Each photo has an X button to delete it.
// - Fully connected to Firestore: photos are stored in
//   "portfolios/{uid}" as a base64 string array.
// - addPhoto() resizes the image to 400px max, encodes as
//   base64 JPEG, and appends it to the Firestore array.
// - deleteImage() removes by index and updates Firestore.
// - Removed all hardcoded dummy photos — everything is live from DB.
// ============================================================

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct PortfolioView: View {
    @State private var images: [String] = []   // base64 strings stored in Firestore
    @State private var isLoading = false
    @State private var isUploading = false
    @State private var selectedPhoto: PhotosPickerItem? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private let maxImages = 6

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Showcase your best work. Add up to \(maxImages) photos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {

                        // Existing photos
                        ForEach(Array(images.enumerated()), id: \.offset) { index, base64 in
                            if let data = Data(base64Encoded: base64),
                               let img = UIImage(data: data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button { deleteImage(at: index) } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.4), radius: 2)
                                    }
                                    .padding(4)
                                }
                            }
                        }

                        // Add button (while not at max)
                        if images.count < maxImages {
                            if isUploading {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(ProgressView())
                            } else {
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray6))
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(
                                            VStack(spacing: 6) {
                                                Image(systemName: "plus")
                                                    .font(.title2)
                                                    .foregroundStyle(.pink)
                                                Text("Add")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        )
                                }
                            }
                        }
                    }

                    if images.isEmpty && !isUploading {
                        Text("No portfolio photos yet. Tap + to add your first photo.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadPortfolio() }
        .onChange(of: selectedPhoto) { _, newItem in
            guard newItem != nil else { return }
            Task { await addPhoto(from: newItem) }
        }
    }

    // MARK: - Firestore

    private func loadPortfolio() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Firestore.firestore().collection("portfolios").document(uid).getDocument { doc, _ in
            isLoading = false
            images = doc?.data()?["images"] as? [String] ?? []
        }
    }

    private func addPhoto(from item: PhotosPickerItem?) async {
        guard let item, let uid = Auth.auth().currentUser?.uid else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        await MainActor.run { isUploading = true }

        let resized = resizeImage(uiImage, maxDimension: 400)
        guard let jpegData = resized?.jpegData(compressionQuality: 0.4) else {
            await MainActor.run { isUploading = false }
            return
        }

        let base64 = jpegData.base64EncodedString()
        let updated = images + [base64]

        Firestore.firestore().collection("portfolios").document(uid)
            .setData(["images": updated]) { _ in
                images = updated
                isUploading = false
                selectedPhoto = nil
            }
    }

    private func deleteImage(at index: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var updated = images
        updated.remove(at: index)

        Firestore.firestore().collection("portfolios").document(uid)
            .setData(["images": updated]) { _ in
                withAnimation { images = updated }
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
    NavigationStack { PortfolioView() }
}
