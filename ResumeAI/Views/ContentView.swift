//
//  ContentView.swift
//  ResumeAI
//
//  Created by Chaman on 22/02/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ResumeBuilderView()
                .tabItem {
                    Label("Builder", systemImage: "doc.text.fill")
                }

            AIAssistantView()
                .tabItem {
                    Label("AI Assist", systemImage: "sparkles")
                }

            ATSCheckerView()
                .tabItem {
                    Label("ATS Score", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
