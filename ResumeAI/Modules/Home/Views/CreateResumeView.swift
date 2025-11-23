//
//  CreateResumeView.swift
//  ResumeAI
//
//  Created by Chaman on 31/08/25.
//

import SwiftUI

struct CreateResumeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel = CreateResumeViewModel()
    var resume: Resume?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    List {
                        ForEach(viewModel.resumeSections) { section in
                            sectionRow(section.name ?? empty)
                        }
                        addSectionButton()
                    }
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
                    
                } .background(Color(uiColor: backgroundColor))
            }
        }
         .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    func sectionRow(_ section: String) -> some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(section)
                        .font(.body)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func addSectionButton() -> some View {
        VStack {
            Spacer(minLength: 30)
            HStack(spacing: 17) {
                Button(action: {
                    
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                        Text("Add section")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 22)
                
                Button(action: {
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.blue)
                        Text("Edit section")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }  .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
     }
}
