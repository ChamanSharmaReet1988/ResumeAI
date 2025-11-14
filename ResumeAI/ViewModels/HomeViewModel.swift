//
//  HomeViewModel.swift
//  ResumeAI
//
//  Created by Chaman on 04/05/25.2
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var recentResumes: [Resume] = []

    init() {
        loadRecentResumes()
     }

    func loadRecentResumes() {
        let resumeTable = ResumeTable()
        recentResumes = resumeTable.getResumes()
    }
}
