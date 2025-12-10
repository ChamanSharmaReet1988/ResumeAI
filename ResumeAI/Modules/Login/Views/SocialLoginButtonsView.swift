//
//  SocialLoginButtonsView.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 18/11/25.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct SocialLoginButtonsView: View {
    // Inject the AuthViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(spacing: 14) {
            
            // MARK: - Apple Official Button
            Button(action: {
                authVM.startAppleLogin()
            }) {
                HStack(spacing: 8) {
                    Spacer()

                    Image(systemName: "apple.logo")
                        .font(.title3)
                        .foregroundColor(.black)
                    

                    Text("Sign in with Apple")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: textCornerRadius)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(textCornerRadius)
            }
            
            // MARK: - Google Custom Button
            Button(action: {
                authVM.handleGoogleSignIn()
            }) {
                HStack {
                    Spacer()
                    
                    Image("google")
                        .resizable()
                        .frame(width: 17, height: 17)
                    
                    Text("Sign in with Google")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: textCornerRadius)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(textCornerRadius)
            }
        }
    }
}

#Preview {
    SocialLoginButtonsView()
        .environmentObject(AuthViewModel())
}

import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
                
                // You should generate and pass a cryptographically secure nonce here if you require it
                // request.nonce = // ... your nonce
                
            },
            onCompletion: { result in
                // Called when the sign-in flow completes
                //                authVM.handleAppleSignIn(result: result)
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(maxWidth: .infinity, minHeight: 48)
        .cornerRadius(14)
    }
}
