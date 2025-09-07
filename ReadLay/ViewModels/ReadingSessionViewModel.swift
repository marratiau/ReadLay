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
    @Published var displayTime: String = "00:00" // NEW: Only update this
    
    @Published var startingPageText: String = ""
    @Published var endingPageText: String = ""
    @Published var validationError: String?
    
    @Published var showingStartPageConfirmation: Bool = false
    @Published var calculatedNextPage: Int = 1
    
    private var currentBook: Book?
    private var lastReadPage: Int = 1
    private var timer: Timer?
    
    var isValidStartingInput: Bool {
        validateStartingPageInput() == nil
    }
    
    var isValidEndingInput: Bool {
        validateEndingPageInput() == nil
    }
    
    var isFirstRead: Bool {
        guard let book = currentBook else { return true }
        return lastReadPage < book.readingStartPage
    }
    
    func startReadingSession(for betId: UUID, book: Book, lastReadPage: Int = 1) {
        self.currentBook = book
        self.lastReadPage = lastReadPage
        
        let session = ReadingSession(betId: betId, startTime: Date())
        currentSession = session
        
        let isFirstSession = lastReadPage < book.readingStartPage
        
        if isFirstSession {
            let nextPage = book.readingStartPage
            self.calculatedNextPage = nextPage
            self.startingPageText = String(nextPage)
            showingStartPageInput = true
            showingStartPageConfirmation = false
        } else {
            let nextPage = lastReadPage + 1
            self.calculatedNextPage = nextPage
            showingStartPageConfirmation = true
            showingStartPageInput = false
        }
    }
    
    func startReadingSessionDirect(for betId: UUID, book: Book, startingPage: Int) {
        self.currentBook = book
        self.lastReadPage = startingPage
        
        var session = ReadingSession(betId: betId, startTime: Date())
        session.startingPage = startingPage
        currentSession = session
        
        showingStartPageConfirmation = false
        showingStartPageInput = false
        showingEndPageInput = false
        showingCommentInput = false
        
        isReading = true
        startTimer()
        
        startingPageText = String(startingPage)
        validationError = nil
    }
    
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
    
    func setStartingPageText(_ text: String) {
        startingPageText = text
        validationError = validateStartingPageInput()
    }
    
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
    
    func setEndingPageText(_ text: String) {
        endingPageText = text
        validationError = validateEndingPageInput()
    }
    
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
    }
    
    func cancelSession() {
        currentSession = nil
        isReading = false
        showingStartPageInput = false
        showingEndPageInput = false
        showingCommentInput = false
        showingStartPageConfirmation = false
        
        startingPageText = ""
        endingPageText = ""
        validationError = nil
        currentBook = nil
        lastReadPage = 1
        calculatedNextPage = 1
        displayTime = "00:00"
        
        stopTimer()
    }
    
    private func validateStartingPageInput() -> String? {
        guard let book = currentBook else { return "Book information not available" }
        
        let trimmedText = startingPageText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return "Please enter a page number" }
        guard let page = Int(trimmedText) else { return "Please enter a valid number" }
        guard page > 0 else { return "Page number must be greater than 0" }
        guard page >= book.readingStartPage else {
            return "Page must be at least \(book.readingStartPage) (reading start page)"
        }
        guard page <= book.readingEndPage else {
            return "Page cannot exceed \(book.readingEndPage) (reading end page)"
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
        guard !trimmedText.isEmpty else { return "Please enter a page number" }
        guard let page = Int(trimmedText) else { return "Please enter a valid number" }
        guard page >= startingPage else {
            return "Ending page must be greater than or equal to starting page (\(startingPage))"
        }
        guard page <= book.readingEndPage else {
            return "Page cannot exceed \(book.readingEndPage) (reading end page)"
        }
        
        return nil
    }
    
    // CRITICAL FIX: Only update display time, not entire object
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let session = self.currentSession else { return }
            // Only update the display string
            let duration = Date().timeIntervalSince(session.startTime)
            self.displayTime = self.formatDuration(duration)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    deinit {
        stopTimer()
    }
}
