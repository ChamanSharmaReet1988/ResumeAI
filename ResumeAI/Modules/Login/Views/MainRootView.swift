//
//  MainRootView.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 18/11/25.
//

import SwiftUI
struct MainRootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    var body: some View {
        Group {
            switch authVM.authState {
            case .loading:
                ProgressView("Checking session…")
            case .unauthenticated:
                NavigationStack {
                    PhoneLoginView()
                }
            case .authenticated:
                ContentView()
            }
        }
        .onAppear {
            authVM.checkExistingSession()
        }
    }
}
