//
//  WorkExperienceView.swift
//  ResumeAI
//
//  Created by Sakshi on 03/12/25.
//

import Foundation
import SwiftUI

struct WorkExperienceView: View {
    var section: ResumeSectionModel

    var body: some View {
        Text("WorkExperience Info Screen")
            .navigationTitle(section.name ?? "")
    }
}

