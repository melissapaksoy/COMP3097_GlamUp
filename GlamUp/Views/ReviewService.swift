// ReviewService.swift — built by Kashfi

import Foundation
import FirebaseFirestore
import FirebaseAuth

// Single source of truth for Review in the project
struct Review: Identifiable {
    let id: String
    let proUserID: String
    let reviewerID: String
    let reviewerName: String
    let rating: Int // 1-5
    let text: String
    let date: Date
}

final class ReviewService {
    static let shared = ReviewService()
    private let db = Firestore.firestore()

    // Adds a review to a beauty pro (by proUserID)
    func addReview(
        for proUserID: String,
        reviewerID: String,
        reviewerName: String,
        rating: Int,
        text: String
    ) async throws {
        let review = [
            "reviewerID": reviewerID,
            "reviewerName": reviewerName,
            "rating": rating,
            "text": text,
            "date": Timestamp(date: Date())
        ] as [String : Any]
        
        _ = try await db.collection("users").document(proUserID)
            .collection("reviews").addDocument(data: review)
    }

    // Fetch all reviews for a beauty pro
    func fetchReviews(for proUserID: String) async throws -> [Review] {
        let snapshot = try await db.collection("users").document(proUserID)
            .collection("reviews").order(by: "date", descending: true).getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let reviewerID = data["reviewerID"] as? String,
                  let reviewerName = data["reviewerName"] as? String,
                  let rating = data["rating"] as? Int,
                  let text = data["text"] as? String,
                  let timestamp = data["date"] as? Timestamp
            else { return nil }

            return Review(
                id: doc.documentID,
                proUserID: proUserID,
                reviewerID: reviewerID,
                reviewerName: reviewerName,
                rating: rating,
                text: text,
                date: timestamp.dateValue()
            )
        }
    }
}
