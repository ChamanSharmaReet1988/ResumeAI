//
//  OtherActivitiesView.swift
//  ResumeAI
//
//  Created by Sakshi on 03/12/25.
//

import Foundation
import SwiftUI

struct OtherActivitiesView: View {
    var section: ResumeSectionModel

    var body: some View {
        Text("OtherActivities Info Screen")
            .navigationTitle(section.name ?? "")
    }
}
