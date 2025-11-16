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
    var onSave: (String) -> Void   // callback to parent

    var body: some View {
        ZStack {
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
                        show = false
                        name = ""
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
                        name = ""
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
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
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
