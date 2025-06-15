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
    
    private var timer: Timer?
    
    func startReadingSession(for betId: UUID) {
        let session = ReadingSession(betId: betId, startTime: Date())
        currentSession = session
        showingStartPageInput = true
    }
    
    func setStartingPage(_ page: Int) {
        guard var session = currentSession else { return }
        session.startingPage = page
        currentSession = session
        showingStartPageInput = false
        isReading = true
        startTimer()
    }
    
    func stopReadingSession() {
        guard var session = currentSession else { return }
        session.endTime = Date()
        currentSession = session
        isReading = false
        stopTimer()
        showingEndPageInput = true
    }
    
    func setEndingPage(_ page: Int) {
        guard var session = currentSession else { return }
        session.endingPage = page
        session.isCompleted = true
        currentSession = session
        showingEndPageInput = false
        
        // Session will be processed by ReadSlipViewModel
    }
    
    func cancelSession() {
        currentSession = nil
        isReading = false
        showingStartPageInput = false
        showingEndPageInput = false
        stopTimer()
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
