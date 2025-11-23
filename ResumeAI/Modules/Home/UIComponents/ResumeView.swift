//
//  ResumeView.swift
//  ResumeAI
//
//  Created by Chaman on 23/11/25.
//

import UIKit
import SwiftUI

struct ResumeListSection: View {
    @Binding var showToast: Bool
    @ObservedObject var viewModel: HomeViewModel
    @State private var showOptions: Bool = false
    @State private var selectedResume: Resume?
    @State private var renameText = empty
    @State private var showRenameResume = false
    @State private var goToCreateResume = false
    @State private var showDuplicateResume = false
    @State private var showDeleteAlert = false
 
    var body: some View {
        ZStack {
            if viewModel.resumes.isEmpty {
                emptyStateView(
                    title: "No resumes available",
                    subtitle: "Click on the + button to create a new resume"
                )
            } else {
                List {
                    ForEach(viewModel.resumes) { resume in
                        ZStack {
                            NavigationLink(
                                destination: CreateResumeView(resume: selectedResume),
                                isActive: $goToCreateResume
                            ) { EmptyView() }
                            .hidden()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resume.name ?? "")
                                        .font(.body)
                                    
                                    Text("Last edited: \(resume.updatedAt ?? "")")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            
                        }
                       
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.white))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.3), lineWidth:0.5)
                        )
                        .onTapGesture {
                            selectedResume = resume
                            showOptions = true
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                    }
                }
                .environment(\.defaultMinListRowHeight, 0)
                .listStyle(.plain)
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 5)
                }
                .confirmationDialog(
                    selectedResume?.name ?? "",
                    isPresented: $showOptions,
                    titleVisibility: .visible
                ) {
                    Button("Open") {
                        goToCreateResume = true
                    }
                    Button("Rename") {
                        renameText = selectedResume?.name ?? ""
                        showRenameResume = true
                    }
                    Button("Duplicate") {
                        renameText = empty
                        showDuplicateResume = true
                    }
                    Button("Delete", role: .destructive) {
                        showDeleteAlert = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .alert("Are you sure you want to delete this resume?", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) { }

                        Button("Delete", role: .destructive) {
                            if let id = selectedResume?.id {
                                viewModel.deleteResume(id) 
                            }
                        }
                }
            }
           
            if showRenameResume || showDuplicateResume {
                CreateResumePopup(
                    show: showRenameResume ? $showRenameResume : $showDuplicateResume,
                    name: $renameText,
                    placeHolder: .constant("Resume name"),
                    showToast: $showToast,
                    headerTitle: showRenameResume ? "Rename" : "Duplicate"
                ) { resumeName in
                    if showRenameResume {
                        viewModel
                            .renameResume(
                                id: selectedResume?.id ?? 0,
                                newName: resumeName
                            )
                    } else {
                        if let id = selectedResume?.id {
                            viewModel.duplicateResume(resumeName: resumeName, id: id)
                        }
                    }
                }
            }
        }
    }
}
 
