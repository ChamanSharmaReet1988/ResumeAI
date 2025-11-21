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
 
    func duplicateResume(resumeName: String, id: Int) {
        let table = ResumeTable()
        table.duplicateResume(resumeName: resumeName, id: id) { success in
            if success {
                DispatchQueue.main.async {
                    self.loadRecentResumes()
                }
            }
        }
    }
    
    func deleteResume(_ id: Int) {
        let table = ResumeTable()
        table.deleteResume(id: id)
        loadRecentResumes()
    }
    
    func renameResume(id: Int, newName: String) {
        let table = ResumeTable()
        table.updateResumeName(id: id, newName: newName)
        loadRecentResumes()
    }
}
