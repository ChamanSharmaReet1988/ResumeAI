//
//  Resume.swift
//  ResumeAI
//
//  Created by Chaman on 04/05/25.
//

import UIKit

struct Resume: Identifiable {
    var id: Int?
    var name: String?
    var createdAt: String?
    var updatedAt: String?
}


struct CoverLeter: Identifiable, Codable, Hashable {
    var id: Int?
    var name: String?
    
    var details: CoverLeterDetail?
    
    var createdAt: String?
    var updatedAt: String?
}

struct CoverLeterDetail: Codable, Hashable {
    
    var companyName: String?
    var jobPosition: String?
    var skills: String?
    var language: String?
    var coverLetterBody: String?
}
