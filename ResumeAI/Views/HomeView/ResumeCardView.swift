//
//  ResumeCardView.swift
//  ResumeAI
//
//  Created by Chaman on 04/05/25.
//

import SwiftUI

struct ResumeCardView: View {
    var resume: Resume

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resume.title ?? EmptyString)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text("Last edited: \(resume.lastEdited ?? EmptyString))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 200, height: 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
