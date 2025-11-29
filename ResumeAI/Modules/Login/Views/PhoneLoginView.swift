//
//  PhoneLoginView.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 18/11/25.
//

import SwiftUI

struct PhoneLoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var navigateToOTP = false
    
    var body: some View {
        ZStack {
            Color(uiColor: backgroundColor)
                    .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("ResumeAI")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(uiColor: themColor))
                    
                    Text("AI-powered ATS-friendly resumes")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Glass Card
                VStack(spacing: 18) {
                    HStack {
                        Text("+91")
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .padding(.leading, 12)
                        
                        Divider()
                            .background(Color.white.opacity(0.4))
                            .frame(height: 26)
                        
                        TextField("Enter phone number", text: $authVM.phoneNumber)
                            .keyboardType(.numberPad)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                    }
                    .padding()
                    .background(
                        LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.6)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    
                    Button {
                        authVM.sendOTP()
                    } label: {
                        HStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send OTP")
                                    .fontWeight(.semibold)
                                    .foregroundColor((Color(uiColor: backgroundColor)))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColor: themColor))
                        .foregroundColor(.black)
                        .cornerRadius(16)
                    }
                    .disabled(authVM.isLoading)
                    
                    if let error = authVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red.opacity(0.9))
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack {
                        Rectangle().frame(height: 1).opacity(0.4)
                        Text("OR CONTINUE WITH")
                            .foregroundColor(.black)
                            .font(.caption)
                        Rectangle().frame(height: 1).opacity(0.4)
                    }
                    .padding(.vertical, 8)
                    
                    SocialLoginButtonsView()
                }
                
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .navigationDestination(isPresented: $navigateToOTP) {
            OTPVerificationView()
        }
        .onChange(of: authVM.verificationID) {
            if authVM.verificationID != nil {
                navigateToOTP = true
            }
        }
    }
}

#Preview {
    PhoneLoginView()
        .environmentObject(AuthViewModel())
}
