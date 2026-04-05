//
//  PortfolioView.swift
//  GlamUp
//

import SwiftUI

struct PortfolioView: View {
    private let galleryImages = ["gallery01", "gallery02", "gallery03", "gallery04", "gallery05", "gallery06"]
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    @State private var selectedImage: String? = nil
    @State private var showDetail = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Showcase your best work to attract more clients.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(galleryImages, id: \.self) { name in
                        Button {
                            selectedImage = name
                            showDetail = true
                        } label: {
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDetail) {
            if let name = selectedImage {
                ImageDetailView(imageName: name)
            }
        }
    }
}

private struct ImageDetailView: View {
    let imageName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            Spacer()

            Image(imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99).ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        PortfolioView()
    }
}
