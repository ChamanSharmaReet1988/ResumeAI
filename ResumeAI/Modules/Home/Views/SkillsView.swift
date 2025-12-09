//
//  SkillsView.swift
//  ResumeAI
//
//  Created by Sakshi on 03/12/25.
//

import Foundation
import SwiftUI

struct SkillsView: View {
    var section: ResumeSectionModel

    var body: some View {
        Text("Skills Info Screen")
            .navigationTitle(section.name ?? "")
    }
}
