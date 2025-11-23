//
//  CoverLetterView.swift
//  ResumeAI
//
//  Created by Chaman on 23/11/25.
//

import UIKit
import SwiftUI


struct CoverLetterSection: View {
    @Binding var coverLetters: [CoverLeter]
    
    var body: some View {
        ZStack {
            if coverLetters.isEmpty {
                emptyStateView(
                    title: "No resumes available",
                    subtitle: "Click on the + button to create a new resume"
                )
            } else {
                List {
                    ForEach(coverLetters) { resume in
                        NavigationLink {
                         } label: {
                            CoverLetterRow(resume: resume)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
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

struct CoverLetterRow: View {
    let resume: CoverLeter

    var body: some View {
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
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
}
