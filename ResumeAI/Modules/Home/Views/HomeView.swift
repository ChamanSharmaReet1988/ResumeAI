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
    @State private var showCreateCoverLetter = false
    @State private var name = empty
    @State private var showToast = false
    @StateObject var viewModel = HomeViewModel()
    
    init() {
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    ResumeSegmentControl(selectedIndex: $selectedTab)
                        .padding(.top, 8)
                    
                    ZStack {
                        if selectedTab == 0 {
                            ResumeListSection(
                                showToast: $showToast,
                                viewModel: viewModel
                            )
                        } else {
                            CoverLetterSection(coverLetters: $viewModel.coverLetters,
                                               viewModel: viewModel)
                        }
                        FloatingAddButton {
                            if selectedTab == .zero {
                                showCreateResume = true
                            } else {
                                showCreateCoverLetter = true
                            }
                        }
                    }
                    .toast(
                        message: "Please enter resume name",
                        isShowing: $showToast,
                        icon: empty
                    )
                    
                } .background(Color(uiColor: backgroundColor))
                // Create Resume Popup
                if showCreateResume {
                    CreateResumePopup(
                        show: $showCreateResume,
                        name: $name,
                        placeHolder: .constant("Resume name"),
                        showToast: $showToast,
                        headerTitle: "Resume"
                    ) { resumeName in
                        viewModel.saveResume(resumeName)
                    }
                }
                
                // Create Cover Letter Popup
                if showCreateCoverLetter {
                    CreateResumePopup(
                        show: $showCreateCoverLetter,
                        name: $name,
                        placeHolder: .constant("Cover Letter Name"),
                        showToast: $showToast,
                        headerTitle: "Cover Letter"
                    ) { coverLetterName in
                        viewModel.saveCoverLetter(coverLetterName)
                    }
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


