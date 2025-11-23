//
//  CreateResumeViewModel.swift
//  ResumeAI
//
//  Created by Chaman on 23/11/25.
//

import UIKit

class CreateResumeViewModel: ObservableObject {
    @Published var resumeSections: [ResumeSectionModel] = []
    let resumeId: String?

     init(resumeId: String?) {
         self.resumeId = resumeId
         loadResumeSections()
     }
    
    func loadResumeSections() {
        let resumeSectionTable = ResumeSectionTable()
        resumeSections = resumeSectionTable.getResumeSections(resumeId: self.resumeId ?? empty)
    }
    
    func saveSection( section: ResumeSectionModel) {
        let resumeSectionTable = ResumeSectionTable()
        resumeSectionTable.saveResumeSection(resumeSectionModel: section) { succes, error in
            self.loadResumeSections()
        }
    }
    
    func deleteResumeSection(_ id: Int) {
        let resumeSectionTable = ResumeSectionTable()
        resumeSectionTable.deletegetResumeSection(id: id)
        loadResumeSections()
    }
    
    func updateResumeSequence() {
        let resumeSectionTable = ResumeSectionTable()
        for (index, value) in resumeSections.enumerated() {
            resumeSectionTable
                .updateResumeSectionSequence(
                    id: value.id ?? 0,
                    squence: "\(index)"
                )
        }
     }
}
 






