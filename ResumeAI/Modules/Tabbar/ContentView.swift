//
//  ContentView.swift
//  ResumeAI
//
//  Created by Chaman on 22/02/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ResumeBuilderView()
                .tabItem {
                    Label("Templates", systemImage: "doc.text.fill")
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
