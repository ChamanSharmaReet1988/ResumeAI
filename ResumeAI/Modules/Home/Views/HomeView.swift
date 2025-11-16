//
//  HomeView.swift
//  ResumeAI
//
//  Created by Chaman on 03/05/25.
//

import SwiftUI

import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0
    @State private var showCreateResume = false
    @State private var name = ""
    @State private var showToast = false
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ResumeSegmentControl(selectedIndex: $selectedTab)
                .padding(.top, 8)

            ZStack {
                if selectedTab == 0 {
                    resumeListSection
                } else {
                    coverLetterSection
                }
                FloatingAddButton {
                    showCreateResume = true
                }
                if showCreateResume {
                    CreateResumePopup(
                        show: $showCreateResume,
                        name: $name,
                        showToast: $showToast
                    ) { resumeName in
                        viewModel.saveResume(resumeName)
                    }
                }
            }
            .toast(
                message: "Please enter resume name",
                isShowing: $showToast,
                icon: ""
            )
        }
    }

    // MARK: - Resume List Section
    private var resumeListSection: some View {
        Group {
            if viewModel.recentResumes.isEmpty {
                emptyStateView(
                    title: "No resumes available",
                    subtitle: "Click on the + button to create a new resume"
                )
            } else {
                List {
                    ForEach(viewModel.recentResumes) { resume in
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(resume.name ?? "")
                                    .font(.body)

                                Spacer(minLength: 0)

                                Text("Last edited: \(resume.updatedAt ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 40)
                        .padding(.vertical, 0)
                    }
                }
                .listStyle(PlainListStyle())
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 5)
                }
              }
        }
    }

    // MARK: - Cover Letter Placeholder Section
    private var coverLetterSection: some View {
        emptyStateView(
            title: "No cover letters available",
            subtitle: "Click on the + button to create a new cover letter"
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
 

