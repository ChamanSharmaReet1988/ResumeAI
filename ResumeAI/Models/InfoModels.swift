//
//  InfoModels.swift
//  ResumeAI
//
//  Created by Sakshi on 05/12/25.
//

import Foundation
import UIKit

struct PersonalInfoModel: Identifiable {
    var id: Int?
    var name: String?
    var phone: String?
    var email: String?
    var address: String?
    var imagePath: String?
    var createdAt: String?
    var updatedAt: String?
}

struct SummaryModel: Identifiable {
    var id: Int?
    var summary: String?
    var createdAt: String?
    var updatedAt: String?
}
