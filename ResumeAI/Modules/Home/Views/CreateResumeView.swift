//
//  CreateResumeView.swift
//  ResumeAI
//
//  Created by Chaman on 31/08/25.
//

import SwiftUI

struct CreateResumeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CreateResumeViewModel
    @State private var showCreateResume = false
    @State private var showToast = false
    var resume: Resume?
    @State private var name = empty
    @State private var isEditing = false
    
    init(resume: Resume?) {
        self.resume = resume
        viewModel = CreateResumeViewModel(resumeId: "\(resume?.id ?? 0)")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    listView()
                        .background(Color(uiColor: backgroundColor))
                }
                if showCreateResume {
                    CreateResumePopup(
                        show: $showCreateResume,
                        name: $name,
                        placeHolder: .constant("Resume name"),
                        showToast: $showToast,
                        headerTitle: "Section"
                    ) { resumeName in
                        viewModel.saveSection(section: ResumeSectionModel(id: 0,
                                                                          resumeId: "\(self.resume?.id ?? 0)",
                                                                          name: resumeName,
                                                                          sequence: "\(viewModel.resumeSections.count)"))
                    }
                }
            }
        } .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    func sectionRow(_ section: String) -> some View {
        HStack {
            Text(section)
                .font(.body)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func addSectionButton() -> some View {
        VStack {
            Spacer(minLength: 25)
            HStack(spacing: 17) {
                Button(action: {
                    showCreateResume = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                        Text("Add section")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }.buttonStyle(.borderless)
                
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 22)
                
                Button(action: {
                    isEditing.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isEditing ? "checkmark.circle" : "square.and.pencil")
                            .foregroundColor(.blue)
                        Text(isEditing ? "Done" : "Edit section")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }.buttonStyle(.borderless)
                
            }
            .frame(maxWidth: .infinity)
            Spacer(minLength: 35)
        }  .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func listView() -> some View {
        List {
            ForEach(viewModel.resumeSections) { resumeSection in
                NavigationLink(
                    destination: destinationView(for: resumeSection)
                ) {
                    sectionRow(resumeSection.name ?? "")
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                let resumeSection = viewModel.resumeSections[indexSet.first ?? 0]
                viewModel.deleteResumeSection(resumeSection.id ?? 0)
            }
            .onMove { from, to in
                viewModel.resumeSections.move(fromOffsets: from, toOffset: to)
                viewModel.updateResumeSequence()
            }
            .deleteDisabled(!isEditing)
             .moveDisabled(!isEditing)
            addSectionButton()
        }
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 5)
        }
        .navigationTitle(resume?.name ?? empty)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    print("Preview tapped")
                }) {
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 15))
                }
            }
        }
        
    }
    
    @ViewBuilder
    func destinationView(for section: ResumeSectionModel) -> some View {
        switch section.name {
        case "Personal Info":
            PersonalInfoView(section: section)

        case "Summary":
            SummaryView(section: section)

        case "Work Experience":
            WorkExperienceView(section: section)

        case "Skills":
            SkillsView(section: section)

        case "Education":
            EducationView(section: section)

        case "Other Activities":
            OtherActivitiesView(section: section)

        default:
            Text("Coming soon")
        }
    }
}

