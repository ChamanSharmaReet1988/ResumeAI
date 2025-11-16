//
//  CreateResumeView.swift
//  ResumeAI
//
//  Created by Chaman on 31/08/25.
//

import SwiftUI

struct CreateResumeView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var fullName = empty
    @State private var email = empty
    @State private var phone = empty
    @State private var degree = empty
    @State private var university = empty
    @State private var graduationYear = empty
    @State private var jobTitle = empty
    @State private var company = empty
    @State private var yearsWorked = empty
    @State private var skills: [String] = []
    @State private var newSkill = empty
    @State private var summary = empty
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Personal Info") {
                }
                NavigationLink("Education") {
                }
                NavigationLink("Employer") {
                }
                NavigationLink("Work Experience") {
                }
                NavigationLink("Skills") {
                }
                NavigationLink("Summary") {
                }
            }
            .navigationTitle("Create Resume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Save action
                        dismiss()
                    }
                }
            }
        }
    }
}
