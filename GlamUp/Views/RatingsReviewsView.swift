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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 42, height: 42)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                    }

                    Spacer()

                    Text("Ratings & Reviews")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Spacer()

                    Color.clear
                        .frame(width: 42, height: 42)
                }
                .padding(.top, 6)

                // Pro Name
                VStack(alignment: .leading, spacing: 4) {
                    Text(proName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("See what clients are saying")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Summary Card
                VStack(spacing: 18) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(String(format: "%.1f", averageRating))
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(.pink)

                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { idx in
                                    Image(systemName: idx <= Int(round(averageRating)) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.subheadline)
                                }
                            }

                            Text("\(reviews.count) review\(reviews.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.pink.opacity(0.12))
                                .frame(width: 74, height: 74)

                            Image(systemName: "sparkles")
                                .font(.system(size: 28))
                                .foregroundStyle(.pink)
                        }
                    }
                }
                .padding(22)
                .background(
                    LinearGradient(
                        colors: [Color.white, Color(red: 1.0, green: 0.96, blue: 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

                // Leave Review Card
                if userIsClient {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Leave a Review")
                            .font(.title3)
                            .fontWeight(.bold)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Rating")
                                .font(.headline)

                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.4))
                                        .scaleEffect(star <= rating ? 1.05 : 1.0)
                                        .animation(.easeInOut(duration: 0.15), value: rating)
                                        .onTapGesture {
                                            rating = star
                                        }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Feedback")
                                .font(.headline)

                            ZStack(alignment: .topLeading) {
                                if reviewText.isEmpty {
                                    Text("Share your experience...")
                                        .foregroundStyle(.gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }

                                TextEditor(text: $reviewText)
                                    .frame(height: 130)
                                    .padding(10)
                                    .background(Color.clear)
                            }
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        Button(action: submitReview) {
                            if isSubmitting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.pink)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            } else {
                                Text("Submit Review")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.pink)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                        .disabled(rating == 0 || reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                        .opacity((rating == 0 || reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting) ? 0.6 : 1)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                }

                // Reviews Header
                HStack {
                    Text("Client Reviews")
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()

                    Text("\(reviews.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.pink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.pink.opacity(0.12))
                        .clipShape(Capsule())
                }

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading reviews...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else if reviews.isEmpty {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.pink.opacity(0.12))
                                .frame(width: 68, height: 68)

                            Image(systemName: "text.bubble")
                                .font(.system(size: 28))
                                .foregroundStyle(.pink)
                        }

                        Text("No reviews yet")
                            .font(.headline)

                        Text("Be the first to share your experience.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                } else {
                    VStack(spacing: 16) {
                        ForEach(reviews) { review in
                            ProfessionalReviewCard(review: review)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }

                Spacer(minLength: 24)
            }
            .padding(20)
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            currentUserID = Auth.auth().currentUser?.uid
            fetchCurrentUserRole()
            fetchReviews()
        }
    }

    // MARK: - Firestore
    private func fetchCurrentUserRole() {
        guard let uid = currentUserID else {
            currentUserRole = nil
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { doc, error in
                if let error = error {
                    print("❌ Failed to fetch role:", error.localizedDescription)
                    return
                }

                guard let data = doc?.data() else { return }
                currentUserRole = (data["role"] as? String)?.lowercased()
            }
    }

    private func fetchReviews() {
        isLoading = true
        errorMessage = nil

        Firestore.firestore()
            .collection("reviews")
            .whereField("proUserID", isEqualTo: proUserID)
            .getDocuments { snapshot, error in
                isLoading = false

                if let error = error {
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
                    else { return nil }

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

                reviews.sort { $0.date > $1.date }
            }
    }

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

        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument { userDoc, error in
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

                Firestore.firestore()
                    .collection("reviews")
                    .addDocument(data: reviewData) { error in
                        isSubmitting = false

                        if let error = error {
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

struct ProfessionalReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Text(initials(from: review.reviewerName))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.pink)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(review.reviewerName)
                            .font(.headline)

                        Spacer()

                        Text(relativeDateString(from: review.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { idx in
                            Image(systemName: idx <= review.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
            }

            Text(review.text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }
        return String(initials)
    }

    private func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
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
