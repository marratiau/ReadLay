//
//  ISBNLookupView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//

//
//  ISBNLookupView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//

import SwiftUI
import VisionKit
import AVFoundation

struct ISBNLookupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isbnText = ""
    @State private var isSearching = false
    @State private var searchResults: [SearchResult] = []
    @State private var hasSearched = false
    @State private var showingScanner = false
    @State private var errorMessage: String?

    let onBookSelected: (Book) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                isbnInputSection

                if isSearching {
                    searchingView
                } else if hasSearched && searchResults.isEmpty {
                    noResultsView
                } else if !searchResults.isEmpty {
                    resultsView
                } else {
                    instructionsView
                }

                Spacer()
            }
            .background(backgroundGradient)
            .navigationTitle("Find Exact Edition")
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
        .sheet(isPresented: $showingScanner) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                ISBNScannerView { isbn in
                    isbnText = isbn
                    showingScanner = false
                    searchByISBN()
                }
            } else {
                Text("Camera scanning not available on this device")
                    .padding()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 40))
                .foregroundColor(.goodreadsBrown)

            Text("Find Your Exact Book")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.goodreadsBrown)

            Text("Scan or enter the ISBN to find your specific edition")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var isbnInputSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                TextField("Enter ISBN (13 or 10 digits)", text: $isbnText)
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
                    .onSubmit {
                        searchByISBN()
                    }

                Button(action: {
                    searchByISBN()
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isValidISBN ? Color.goodreadsBrown : Color.goodreadsAccent.opacity(0.5))
                        )
                }
                .disabled(!isValidISBN)
            }

            // Only show scan button if device supports it
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                Button(action: {
                    showingScanner = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 16, weight: .medium))
                        Text("Scan Barcode")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.goodreadsBrown)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
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

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal, 24)
    }

    private var searchingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Looking up ISBN...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.goodreadsAccent)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            Text("No books found")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)
            Text("Double-check the ISBN or try a regular search")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults, id: \.id) { result in
                    ISBNSearchResultRowView(
                        result: result,
                        onSelect: {
                            let book = result.toBook()
                            onBookSelected(book)
                            dismiss()
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private var instructionsView: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                Text("Where to find the ISBN:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 20))
                            .foregroundColor(.goodreadsAccent)
                        Text("Back cover near the barcode")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 20))
                            .foregroundColor(.goodreadsAccent)
                        Text("Copyright page (first few pages)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "ipad")
                            .font(.system(size: 20))
                            .foregroundColor(.goodreadsAccent)
                        Text("Digital books: Details or About page")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.goodreadsWarm)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            Spacer()
        }
        .padding(.horizontal, 24)
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

    private var isValidISBN: Bool {
        let cleaned = isbnText.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        return cleaned.count == 10 || cleaned.count == 13
    }

    private func searchByISBN() {
        guard isValidISBN else {
            errorMessage = "Please enter a valid 10 or 13 digit ISBN"
            return
        }

        errorMessage = nil
        isSearching = true
        hasSearched = true
        searchResults = []

        Task {
            async let googleResult = GoogleBooksAPI.shared.searchByISBN(isbn: isbnText)
            async let openLibraryResult = OpenLibraryAPI.shared.searchByISBN(isbn: isbnText)

            var results: [SearchResult] = []

            if let googleBook = try? await googleResult {
                results.append(.googleBooks(googleBook))
            }

            if let openLibraryBook = try? await openLibraryResult {
                results.append(.openLibrary(openLibraryBook))
            }

            await MainActor.run {
                self.searchResults = results
                self.isSearching = false

                if results.isEmpty {
                    self.errorMessage = "No books found with this ISBN"
                }
            }
        }
    }
}

// MARK: - ISBN Scanner View
struct ISBNScannerView: UIViewControllerRepresentable {
    let onISBNFound: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = [
            .barcode(symbologies: [.ean13, .ean8, .upce])
        ]

        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: ISBNScannerView

        init(_ parent: ISBNScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let isbn = barcode.payloadStringValue {
                    parent.onISBNFound(isbn)
                }
            default:
                break
            }
        }
    }
}

// MARK: - Enhanced Search Result Row
struct ISBNSearchResultRowView: View {
    let result: SearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Book cover
                AsyncImage(url: URL(string: result.coverURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.goodreadsBeige)
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.title2)
                                .foregroundColor(.goodreadsAccent)
                        )
                }
                .frame(width: 60, height: 85)
                .cornerRadius(8)

                // Book details
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let author = result.author {
                        Text(author)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Text("\(result.pageCount) pages")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsAccent.opacity(0.8))

                        Text("ISBN Match")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                            )

                        Text(result.source)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(result.source == "Open Library" ? Color.green.opacity(0.7) : Color.blue.opacity(0.7))
                            )
                    }
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.goodreadsWarm)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
