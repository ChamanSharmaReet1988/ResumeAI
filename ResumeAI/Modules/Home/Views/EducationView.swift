//
//  EducationView.swift
//  ResumeAI
//
//  Created by Sakshi on 03/12/25.
//

import Foundation
import SwiftUI

struct EducationView: View {
    var section: ResumeSectionModel

    var body: some View {
        Text("Education Info Screen")
            .navigationTitle(section.name ?? "")
    }
}

