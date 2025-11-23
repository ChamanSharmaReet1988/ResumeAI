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
}
