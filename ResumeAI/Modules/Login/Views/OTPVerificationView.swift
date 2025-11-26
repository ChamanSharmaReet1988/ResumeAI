//
//  OTPVerificationView.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 18/11/25.
//

import SwiftUI
//
struct OTPVerificationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(uiColor: backgroundColor)
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Verify OTP")
                    .font(.title.bold())
                    .foregroundColor(Color(uiColor: themColor))
                
                Text("We’ve sent a 6-digit code to \(authVM.phoneNumber)")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Enter OTP", text: $authVM.otpCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .foregroundColor(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                                
                Button {
                    authVM.verifyOTPAndLogin()
                } label: {
                    HStack {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verify & Continue")
                                .fontWeight(.semibold)
                                .foregroundColor(Color(uiColor: backgroundColor))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(uiColor: themColor))
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                }
                .disabled(authVM.isLoading)
                
                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red.opacity(0.9))
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 60)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    // Just pop back
                }
                .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    OTPVerificationView()
        .environmentObject(AuthViewModel())
}
