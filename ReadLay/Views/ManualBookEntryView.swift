//
//  ManualBookEntryView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct ManualBookEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var pages = ""
    @State private var selectedDifficulty: Book.ReadingDifficulty = .medium
    @State private var coverImageURL = ""

    let onBookAdded: (Book) -> Void

    var isValidInput: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !pages.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(pages) != nil && Int(pages)! > 0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    inputFields
                    difficultySection
                    addButtonSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(backgroundGradient)
            .navigationTitle("Add Book Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.goodreadsAccent)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.fill")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsBrown)

            Text("Add Your Book")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.goodreadsBrown)

            Text("Enter the details of your book manually")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent)
                .multilineTextAlignment(.center)
        }
    }

    private var inputFields: some View {
        VStack(spacing: 20) {
            // Title field
            VStack(alignment: .leading, spacing: 8) {
                Text("Book Title *")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)

                TextField("e.g., The Way of the Superior Man", text: $title)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            // Author field
            VStack(alignment: .leading, spacing: 8) {
                Text("Author")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)

                TextField("e.g., David Deida", text: $author)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            // Pages field
            VStack(alignment: .leading, spacing: 8) {
                Text("Number of Pages *")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)

                TextField("e.g., 250", text: $pages)
                    .font(.system(size: 16))
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            // Cover URL field (optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("Cover Image URL (Optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)

                TextField("https://example.com/cover.jpg", text: $coverImageURL)
                    .font(.system(size: 16))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Difficulty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.goodreadsBrown)

            HStack(spacing: 12) {
                ForEach(Book.ReadingDifficulty.allCases, id: \.self) { difficulty in
                    Button(action: {
                        selectedDifficulty = difficulty
                    }) {
                        Text(difficulty.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedDifficulty == difficulty ? .white : .goodreadsBrown)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedDifficulty == difficulty ? Color.goodreadsBrown : Color.goodreadsBeige)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }

    private var addButtonSection: some View {
        Button(action: addBook) {
            Text("Add to My Bookshelf")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isValidInput ? Color.goodreadsBrown : Color.goodreadsAccent.opacity(0.5))
                )
        }
        .disabled(!isValidInput)
        .padding(.top, 8)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.goodreadsBeige,
                Color.goodreadsWarm.opacity(0.5)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func addBook() {
        let spineColors: [Color] = [
            Color(red: 0.2, green: 0.4, blue: 0.8),
            Color(red: 0.1, green: 0.7, blue: 0.3),
            Color(red: 0.9, green: 0.5, blue: 0.1),
            Color(red: 0.6, green: 0.2, blue: 0.8),
            Color(red: 0.8, green: 0.1, blue: 0.1),
            Color(red: 0.1, green: 0.6, blue: 0.7),
            Color(red: 0.7, green: 0.6, blue: 0.1),
            Color(red: 0.3, green: 0.1, blue: 0.6)
        ]

        let book = Book(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : author.trimmingCharacters(in: .whitespacesAndNewlines),
            totalPages: Int(pages) ?? 250,
            coverImageName: nil,
            coverImageURL: coverImageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : coverImageURL.trimmingCharacters(in: .whitespacesAndNewlines),
            googleBooksId: nil,
            spineColor: spineColors.randomElement() ?? Color.goodreadsBrown,
            difficulty: selectedDifficulty
        )

        onBookAdded(book)
    }
}

extension Book.ReadingDifficulty {
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}
