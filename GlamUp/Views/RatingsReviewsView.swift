import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RatingsReviewsView: View {
    let proName: String
    let proUserID: String

    @Environment(\.dismiss) private var dismiss

    @State private var reviews: [Review] = []
    @State private var isLoading = false
    @State private var currentUserID = Auth.auth().currentUser?.uid
    @State private var currentUserRole: String? = nil
    @State private var errorMessage: String? = nil

    // Review form
    @State private var rating = 0
    @State private var reviewText = ""
    @State private var isSubmitting = false

    private var userIsClient: Bool {
        currentUserRole?.lowercased() == "client"
    }

    private var averageRating: Double {
        guard !reviews.isEmpty else { return 0 }
        let total = reviews.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(reviews.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Ratings & Reviews")
                        .font(.title3)
                        .bold()

                    Spacer()

                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.top, 8)

                // Summary
                if !reviews.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overall Rating")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(format: "%.1f", averageRating))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.pink)

                                HStack(spacing: 3) {
                                    ForEach(1...5, id: \.self) { idx in
                                        Image(systemName: idx <= Int(round(averageRating)) ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                    }
                                }

                                Text("\(reviews.count) review\(reviews.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "star.bubble.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(.pink.opacity(0.8))
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                }

                // Leave review section (CLIENTS CAN SUBMIT MULTIPLE REVIEWS)
                if userIsClient {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Leave a Review")
                            .font(.title3)
                            .bold()

                        Text("Rating")
                            .font(.headline)

                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.5))
                                    .onTapGesture {
                                        rating = star
                                    }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Feedback")
                                .font(.headline)

                            TextEditor(text: $reviewText)
                                .frame(height: 120)
                                .padding(10)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button(action: submitReview) {
                            if isSubmitting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black.opacity(0.85))
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            } else {
                                Text("Submit Review")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black.opacity(0.85))
                                    .cornerRadius(14)
                            }
                        }
                        .disabled(rating == 0 || reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                        .opacity((rating == 0 || reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting) ? 0.6 : 1)
                    }
                }

                Divider()
                    .padding(.top, 4)

                // Previous Reviews header
                HStack {
                    Text("Previous Reviews")
                        .font(.title3)
                        .bold()

                    Spacer()

                    Text("\(reviews.count) review\(reviews.count == 1 ? "" : "s")")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }

                if isLoading {
                    ProgressView("Loading reviews...")
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity)
                } else if reviews.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.6))

                        Text("No reviews yet")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Be the first to leave feedback.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 14) {
                        ForEach(reviews) { review in
                            ReviewCard(review: review)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 10)
                }

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            currentUserID = Auth.auth().currentUser?.uid
            fetchCurrentUserRole()
            fetchReviews()
        }
    }

    // MARK: - Fetch Current User Role
    private func fetchCurrentUserRole() {
        guard let uid = currentUserID else {
            currentUserRole = nil
            return
        }

        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { doc, error in
            if let error = error {
                print("❌ Failed to fetch role:", error.localizedDescription)
                return
            }

            guard let data = doc?.data() else {
                print("⚠️ No user doc found for role check")
                return
            }

            let role = (data["role"] as? String)?.lowercased()
            currentUserRole = role
        }
    }

    // MARK: - Fetch Reviews (NO INDEX REQUIRED)
    private func fetchReviews() {
        isLoading = true
        errorMessage = nil

        let db = Firestore.firestore()

        db.collection("reviews")
            .whereField("proUserID", isEqualTo: proUserID)
            .getDocuments { snapshot, error in
                isLoading = false

                if let error = error {
                    print("❌ Fetch reviews error:", error.localizedDescription)
                    errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else {
                    reviews = []
                    return
                }

                reviews = documents.compactMap { doc in
                    let data = doc.data()

                    guard
                        let savedProUserID = data["proUserID"] as? String,
                        let reviewerID = data["reviewerID"] as? String,
                        let reviewerName = data["reviewerName"] as? String,
                        let text = data["text"] as? String,
                        let timestamp = data["date"] as? Timestamp
                    else {
                        return nil
                    }

                    let ratingValue = data["rating"]
                    let rating: Int

                    if let intRating = ratingValue as? Int {
                        rating = intRating
                    } else if let doubleRating = ratingValue as? Double {
                        rating = Int(doubleRating)
                    } else {
                        return nil
                    }

                    return Review(
                        id: doc.documentID,
                        proUserID: savedProUserID,
                        reviewerID: reviewerID,
                        reviewerName: reviewerName,
                        rating: rating,
                        text: text,
                        date: timestamp.dateValue()
                    )
                }

                // Sort newest first locally
                reviews.sort { $0.date > $1.date }
            }
    }

    // MARK: - Submit Review
    private func submitReview() {
        guard rating > 0 else {
            errorMessage = "Please select a rating."
            return
        }

        let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            errorMessage = "Please write a review."
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to leave a review."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let db = Firestore.firestore()

        db.collection("users").document(user.uid).getDocument { userDoc, error in
            if let error = error {
                isSubmitting = false
                errorMessage = "Failed to fetch user info: \(error.localizedDescription)"
                return
            }

            let userData = userDoc?.data()

            let reviewerName =
                (userData?["fullName"] as? String) ??
                (user.displayName) ??
                "Client"

            let reviewData: [String: Any] = [
                "proUserID": proUserID,
                "reviewerID": user.uid,
                "reviewerName": reviewerName,
                "rating": rating,
                "text": trimmedText,
                "date": Timestamp(date: Date())
            ]

            db.collection("reviews").addDocument(data: reviewData) { error in
                isSubmitting = false

                if let error = error {
                    print("❌ Submit review error:", error.localizedDescription)
                    errorMessage = error.localizedDescription
                    return
                }

                reviewText = ""
                rating = 0
                fetchReviews()
            }
        }
    }
}

struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.7))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(review.reviewerName)
                            .font(.headline)

                        Text(relativeDateString(from: review.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { idx in
                            Image(systemName: idx <= review.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }

                Spacer()
            }

            Text(review.text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        RatingsReviewsView(
            proName: "Sophia Martinez",
            proUserID: "dummyProUserID123"
        )
    }
}
