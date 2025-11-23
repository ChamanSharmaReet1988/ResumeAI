//
//  CreateResumeViewModel.swift
//  ResumeAI
//
//  Created by Chaman on 23/11/25.
//

import UIKit

class CreateResumeViewModel: ObservableObject {
    @Published var resumeSections: [ResumeSectionModel] = []
    
    init() {
        loadResumeSections()
    }
    
    func loadResumeSections() {
        let resumeSectionTable = ResumeSectionTable()
        resumeSections = resumeSectionTable.getResumeSections()
    }
}
 






