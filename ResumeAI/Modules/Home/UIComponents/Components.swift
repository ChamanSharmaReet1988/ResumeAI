//
//  CommonUIComponent.swift
//  ResumeAI
//
//  Created by Chaman on 04/05/25.
//

import SwiftUI

struct CreateResumePopup: View {
    @Binding var show: Bool
    @Binding var name: String
    @Binding var showToast: Bool
    var headerTitle: String
    var onSave: (String) -> Void   // callback to parent

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
            
            VStack(spacing: 0) {
                Text(headerTitle)
                    .font(.headline)
                    .padding(.top)
                
                Spacer(minLength: 15)
                
                TextField("Resume name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocapitalization(.words)
                
                Spacer(minLength: 20)
                
                Divider()
                
                HStack {
                    Button("Cancel") {
                        show = false
                        name = empty
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                    
                    Button("OK") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if trimmed.isEmpty {
                            showToast = false
                            showToast = true
                        } else {
                            onSave(trimmed)
                            show = false
                        }
                        name = empty
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 44)
            }
            .frame(width: 300, height: 160)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(radius: 10)
            .transition(.scale)
        }
    }
}

struct FloatingAddButton: View {
    var action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
}

struct ResumeSegmentControl: View {
    @Binding var selectedIndex: Int
    
    var body: some View {
        Picker("", selection: $selectedIndex) {
            Text("Resumes").tag(0)
            Text("Cover Letters").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .tint(.blue)
    }
}

func emptyStateView(title: String, subtitle: String) -> some View {
    VStack(spacing: 8) {
        Spacer()
        
        Image(systemName: "doc.text.magnifyingglass")
            .font(.system(size: 35))
            .foregroundColor(.gray.opacity(0.6))
        
        Text(title)
            .font(.system(size: 18, weight: .thin))
            .foregroundColor(.gray)
        
        Text(subtitle)
            .font(.system(size: 15))
            .foregroundColor(.gray.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        
        Spacer()
    }
}

extension UISegmentedControl {
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        // Selected text color = Blue
        setTitleTextAttributes([.foregroundColor: themColor], for: .selected)
        // Unselected text color = Gray
        setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
    }
}


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
                                viewModel.deleteResume(id)   // ✅ run delete here
                            }
                        }
                }
            }
           
            if showRenameResume || showDuplicateResume {
                CreateResumePopup(
                    show: showRenameResume ? $showRenameResume : $showDuplicateResume,
                    name: $renameText,
                    showToast: $showToast,
                    headerTitle: showRenameResume ? "Rename" : "Duplicate Resume"
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


struct CoverLetterSection: View {
    @Binding var coverLetters: [CoverLeter]
    
    var body: some View {
        Group {
            if coverLetters.isEmpty {
                emptyStateView(
                    title: "No resumes available",
                    subtitle: "Click on the + button to create a new resume"
                )
            } else {
                List {
                    ForEach(coverLetters) { resume in
                        ZStack {
                            NavigationLink(destination: CreateResumeView()) {
                                EmptyView()
                            }
                            .opacity(0)
                            .buttonStyle(.plain)
                            
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
            }
        }
    }
}
