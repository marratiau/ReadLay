//
//  ReadingSessionViewModel.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI
import Combine

class ReadingSessionViewModel: ObservableObject {
    @Published var currentSession: ReadingSession?
    @Published var isReading: Bool = false
    @Published var showingStartPageInput: Bool = false
    @Published var showingEndPageInput: Bool = false
    @Published var showingCommentInput: Bool = false
    
    // Page input management
    @Published var startingPageText: String = ""
    @Published var endingPageText: String = ""
    @Published var validationError: String? = nil
    
    // ADDED: Confirmation flow properties
    @Published var showingStartPageConfirmation: Bool = false
    @Published var calculatedNextPage: Int = 1
    
    // Book context for validation
    private var currentBook: Book?
    private var lastReadPage: Int = 1
    
    private var timer: Timer?
    
    // Computed properties for validation and first read detection
    var isValidStartingInput: Bool {
        validateStartingPageInput() == nil
    }
    
    var isValidEndingInput: Bool {
        validateEndingPageInput() == nil
    }
    
    var isFirstRead: Bool {
        lastReadPage <= 1
    }
    
    // CHANGED: First session starts immediately, subsequent sessions show confirmation
    func startReadingSession(for betId: UUID, book: Book, lastReadPage: Int = 1) {
        self.currentBook = book
        self.lastReadPage = lastReadPage
        
        let session = ReadingSession(betId: betId, startTime: Date())
        currentSession = session
        
        // Calculate next page automatically
        let nextPage = lastReadPage == 1 ? 1 : lastReadPage + 1
        self.calculatedNextPage = nextPage
        
        // First session: start immediately, subsequent sessions: show confirmation
        if lastReadPage <= 1 {
            // First reading session - start immediately from page 1
            setStartingPage(nextPage)
        } else {
            // Subsequent sessions - show confirmation dialog
            showingStartPageConfirmation = true
        }
    }
    
    // ADDED: Method to confirm and start reading
    func confirmStartingPage(_ page: Int) {
        setStartingPage(page)
        showingStartPageConfirmation = false
    }
    
    func setStartingPage(_ page: Int) {
        guard var session = currentSession else { return }
        session.startingPage = page
        currentSession = session
        showingStartPageInput = false
        isReading = true
        startTimer()
    }
    
    // Method to handle starting page text changes with validation
    func setStartingPageText(_ text: String) {
        startingPageText = text
        validationError = validateStartingPageInput()
    }
    
    // Method to start reading with validation
    func startReading() {
        guard let page = Int(startingPageText),
              validateStartingPageInput() == nil else {
            validationError = validateStartingPageInput()
            return
        }
        
        setStartingPage(page)
    }
    
    func stopReadingSession() {
        guard var session = currentSession else { return }
        session.endTime = Date()
        currentSession = session
        isReading = false
        stopTimer()
        
        // Pre-fill ending page with starting page as default
        if session.startingPage > 0 {
            endingPageText = String(session.startingPage)
        }
        
        showingEndPageInput = true
    }
    
    func setEndingPage(_ page: Int) {
        guard var session = currentSession else { return }
        session.endingPage = page
        currentSession = session
        showingEndPageInput = false
        showingCommentInput = true
    }
    
    // Method to handle ending page text changes with validation
    func setEndingPageText(_ text: String) {
        endingPageText = text
        validationError = validateEndingPageInput()
    }
    
    // Method to finish reading with validation
    func finishReading() {
        guard let page = Int(endingPageText),
              validateEndingPageInput() == nil else {
            validationError = validateEndingPageInput()
            return
        }
        
        setEndingPage(page)
    }
    
    func setComment(_ comment: String) {
        guard var session = currentSession else { return }
        session.comment = comment
        session.isCompleted = true
        currentSession = session
        showingCommentInput = false
        
        // Session will be processed by ReadSlipViewModel
    }
    
    // CHANGED: Added confirmation state cleanup
    func cancelSession() {
        currentSession = nil
        isReading = false
        showingStartPageInput = false
        showingEndPageInput = false
        showingCommentInput = false
        showingStartPageConfirmation = false // ADDED
        
        // Clear input states
        startingPageText = ""
        endingPageText = ""
        validationError = nil
        currentBook = nil
        lastReadPage = 1
        calculatedNextPage = 1 // ADDED
        
        stopTimer()
    }
    
    // Validation methods
    private func validateStartingPageInput() -> String? {
        guard let book = currentBook else { return "Book information not available" }
        
        let trimmedText = startingPageText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else {
            return "Please enter a page number"
        }
        
        guard let page = Int(trimmedText) else {
            return "Please enter a valid number"
        }
        
        guard page > 0 else {
            return "Page number must be greater than 0"
        }
        
        guard page <= book.totalPages else {
            return "Page number cannot exceed \(book.totalPages)"
        }
        
        return nil
    }
    
    private func validateEndingPageInput() -> String? {
        guard let book = currentBook else { return "Book information not available" }
        guard let session = currentSession, session.startingPage > 0 else {
            return "Starting page not set"
        }
        
        let startingPage = session.startingPage
        let trimmedText = endingPageText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else {
            return "Please enter a page number"
        }
        
        guard let page = Int(trimmedText) else {
            return "Please enter a valid number"
        }
        
        guard page >= startingPage else {
            return "Ending page must be greater than or equal to starting page (\(startingPage))"
        }
        
        guard page <= book.totalPages else {
            return "Page number cannot exceed \(book.totalPages)"
        }
        
        return nil
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.objectWillChange.send()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopTimer()
    }
}
