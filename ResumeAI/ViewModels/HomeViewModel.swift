//
//  HomeViewModel.swift
//  ResumeAI
//
//  Created by Chaman on 04/05/25.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var recentResumes: [Resume] = []
    @Published var dailyTip: String = ""
    @Published var isProUser: Bool = false

    // MARK: - Init

    init() {
        loadRecentResumes()
        loadDailyTip()
        checkProStatus()
    }

    // MARK: - Mock Loaders

    private func loadRecentResumes() {
        // TODO: Replace with real data (from CoreData, file storage, or Firebase)
        recentResumes = [
            Resume(id: 1, title: "iOS Developer Resume", lastEdited: ""),
            Resume(id: 2, title: "Project Manager Resume", lastEdited: "")
        ]
    }

    private func loadDailyTip() {
        // You could also call OpenAI here to generate a daily tip
        let tips = [
            "Use strong action verbs like 'Developed', 'Led', and 'Implemented'.",
            "Tailor your resume for each job with matching keywords.",
            "Keep formatting simple for ATS compatibility.",
            "Quantify achievements: e.g. 'Increased performance by 25%'."
        ]
        dailyTip = tips.randomElement() ?? ""
    }

    private func checkProStatus() {
        // TODO: Replace with real check (UserDefaults, Subscription Manager, Firebase, etc.)
        isProUser = false
    }
}
