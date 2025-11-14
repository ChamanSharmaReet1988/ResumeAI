//
//  HomeView.swift
//  ResumeAI
//
//  Created by Chaman on 03/05/25.
//

import SwiftUI

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showCreateResume = false
    @State private var name = ""
    @State private var showToast = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Your list
                List {
                    ForEach(viewModel.recentResumes) { resume in
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(resume.title ?? empty)
                                    .font(.body)
                                Spacer(minLength: 0)
                                Text(
                                    "Last edited: \(resume.lastEdited ?? empty)"
                                )
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 40)  // fixed height
                        .padding(.vertical, 0) // adds ~10px space between rows
                        .contentShape(Rectangle())
                    }
                }
                .listStyle(PlainListStyle()) // clean list, no grouping style
                .navigationTitle("Resumes")
                
                // Floating Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showCreateResume = true
                        }) {
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
                
                if showCreateResume {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: 0) {
                        Text("Enter Resume Name")
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
                                withAnimation {
                                    showCreateResume = false
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                            
                            Button("OK") {
                                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    withAnimation {
                                        showToast = true
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showCreateResume = false
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: 44)
                    }
                    .frame(width: 300)
                    .frame(height: 160)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .shadow(radius: 10)
                    .transition(.scale)
                }
                
            }
            .toast(
                message: "Data saved successfully!",
                isShowing: $showToast,
                icon: "checkmark.circle.fill"
            )
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

#Preview {
    HomeView()
}
