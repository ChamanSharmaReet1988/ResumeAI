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
        loadCoverLetters()
    }
    
    // MARK: - Load Resume
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
        ) { success, result, id  in
            if success {
                self.loadRecentResumes()
                let sections = [
                    "Personal Info",
                    "Summary",
                    "Work Experience",
                    "Skills",
                    "Education",
                    "Other Activities"
                ]
                for (index, value) in sections.enumerated() {
                    let resumeSectionTable = ResumeSectionTable()
                    var section = ResumeSectionModel()
                    section.resumeId = "\(id ?? 0)"
                    section.name = value
                    section.sequence = "\(index)"
                    resumeSectionTable
                        .saveResumeSection(resumeSectionModel: section) { success, result in
                        }
                }
            }
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
        
        let resumeSectionTable = ResumeSectionTable()
        resumeSectionTable.deletegetResumeSection(resumeId: "\(id)")
    }
    
    func renameResume(id: Int, newName: String) {
        let table = ResumeTable()
        table.updateResumeName(id: id, newName: newName)
        loadRecentResumes()
    }
    
    // MARK: - Cover Letter CRUD
    func loadCoverLetters() {
        let coverLetterTable = CoverLetterTable()
        coverLetters = coverLetterTable.getCoverLetters()
    }
    
    func saveCoverLetter(_ name: String) {
        let table = CoverLetterTable()
        
        let model = CoverLeter(
            name: name,
            createdAt: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short),
            updatedAt: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        )
        
        table.saveCoverLetter(model: model) { success, error, id in
            if success {
                self.loadCoverLetters()
            }
        }
    }
    
    func updateCoverLetter(id: Int, name: String, details: CoverLeterDetail? = nil) {
        let table = CoverLetterTable()
        table.updateCoverLetter(id: id, name: name, details: details)
        table.debugFetchCoverLetter(id: id)
        loadCoverLetters()
    }
    
    func deleteCoverLetter(_ id: Int) {
        let table = CoverLetterTable()
        table.deleteCoverLetter(id: id)
        loadCoverLetters()
    }
}
