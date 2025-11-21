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
    @State private var name = empty
    @State private var showToast = false
    @ObservedObject var viewModel = HomeViewModel()
    
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
                            CoverLetterSection(coverLetters: $viewModel.coverLetters)
                        }
                        FloatingAddButton {
                            showCreateResume = true
                        }
                    }
                    .toast(
                        message: "Please enter resume name",
                        isShowing: $showToast,
                        icon: empty
                    )
                    
                } .background(Color(uiColor: backgroundColor))
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
 

