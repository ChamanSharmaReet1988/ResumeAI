//
//  HomeViewModel.swift
//  ResumeAI
//
//  Created by Chaman on 04/05/25.2
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var resumes: [Resume] = []
    @Published var coverLetters: [CoverLeter] = []

    init() {
        loadRecentResumes()
     }

    func loadRecentResumes() {
        let resumeTable = ResumeTable()
        resumes = resumeTable.getResumes()
    }
    
    func saveResume(_ resumeName: String) {
        let resumeTable = ResumeTable()
        resumeTable.saveResume(
            resume: Resume(
                name: resumeName,
                createdAt: DateFormatter.localizedString(
                    from: Date(),
                    dateStyle: .medium,
                    timeStyle: .short
                ),
                updatedAt: DateFormatter.localizedString(
                    from: Date(),
                    dateStyle: .medium,
                    timeStyle: .short
                )
            )
        ) { success, result in
            self.loadRecentResumes()
        }
    }
}
