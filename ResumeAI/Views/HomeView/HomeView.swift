//
//  HomeView.swift
//  ResumeAI
//
//  Created by Chaman on 03/05/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel = HomeViewModel()

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Welcome back, Chaman 👋")
                        .font(.title)
                        .bold()

                    Text("Your Recent Resumes")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.recentResumes) { resume in
                                ResumeCardView(resume: resume)
                            }
                        }
                    }

                    Text("Quick Actions")
                        .font(.headline)

                    HStack {
                        HomeActionButton(title: "New Resume", icon: "plus.circle")
                        HomeActionButton(title: "AI Assist", icon: "sparkles")
                        HomeActionButton(title: "ATS Check", icon: "chart.bar.doc.horizontal")
                    }

                    Text("💡 Resume Tip")
                        .font(.headline)
                    Text(viewModel.dailyTip)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)

                    if !viewModel.isProUser {
                        Button("Upgrade to Pro 🚀") {
                            // handle upgrade
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding()
            }
        }
}

#Preview {
    HomeView()
}
