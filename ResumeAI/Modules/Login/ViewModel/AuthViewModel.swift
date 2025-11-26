//
//  AuthViewModel.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 18/11/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    
    // Phone
    @Published var phoneNumber: String = ""
    @Published var otpCode: String = ""
    @Published var verificationID: String?
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() { }
    
    func checkExistingSession() {
        if Auth.auth().currentUser != nil &&
            UserDefaults.standard.bool(forKey: UserDefaults.isLoggedInKey) {
            authState = .authenticated
        } else {
            authState = .unauthenticated
        }
    }
    
    // MARK: - Phone
    
    func sendOTP() {
        guard phoneNumber.count >= 10 else {
            errorMessage = "Please enter valid phone number"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let formatted = formatIndianPhone(phoneNumber)
        
        AuthService.shared.startPhoneNumberAuth(phoneNumber: formatted) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let id):
                    self.verificationID = id
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func verifyOTPAndLogin() {
        guard let verificationID else {
            errorMessage = "Missing verification ID"
            return
        }
        guard otpCode.count >= 6 else {
            errorMessage = "Please enter 6-digit OTP"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        AuthService.shared.verifyCode(verificationID: verificationID, smsCode: otpCode) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let user):
                    AuthService.shared.setCurrentUser(user)
                    UserDefaults.standard.set(true, forKey: UserDefaults.isLoggedInKey)
                    self.authState = .authenticated
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func formatIndianPhone(_ number: String) -> String {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("+") {
            return trimmed
        } else {
            return "+91" + trimmed
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        do {
            try AuthService.shared.logout()
            UserDefaults.standard.set(false, forKey: UserDefaults.isLoggedInKey)
            authState = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Google Sign In
    
    func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let idToken = result?.user.idToken?.tokenString,
                      let accessToken = result?.user.accessToken.tokenString else {
                    self.errorMessage = "Google Token missing"
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: accessToken)
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    if let user = authResult?.user {
                        AuthService.shared.setCurrentUser(user)
                        UserDefaults.standard.set(true, forKey: UserDefaults.isLoggedInKey)
                        self.authState = .authenticated
                    }
                }
            }
        }
    }
    
    // MARK: - Apple Sign In
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        //        switch result {
        //        case .success(let auth):
        //            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
        //               let identityToken = appleIDCredential.identityToken,
        //               let tokenString = String(data: identityToken, encoding: .utf8) {
        //
        //                // CORRECTED: Use AppleAuthProvider.credential dedicated method
        //                // Note: The 'rawNonce' can be passed as nil if you aren't using one.
        //                let credential = OAuthProvider.credential(providerID: AppleAuthProviderID,
        //                                                          idToken: tokenString, rawNonce: "")
        //
        //                isLoading = true
        //                Auth.auth().signIn(with: credential) { [weak self] authResult, error in
        //                    Task { @MainActor in
        //                        guard let self else { return }
        //                        self.isLoading = false
        //                        if let error = error {
        //                            self.errorMessage = error.localizedDescription
        //                            return
        //                        }
        //                        if let user = authResult?.user {
        //                            AuthService.shared.setCurrentUser(user)
        //                            self.authState = .authenticated
        //                        }
        //                    }
        //                }
        //            }
        //        case .failure(let error):
        //            // Note: You might want to filter out ASAuthorizationError.canceled errors here
        //            // as they are standard user actions, not actual failures.
        //            errorMessage = error.localizedDescription
        //        }
    }
}

extension AuthViewModel {
    func startAppleLogin() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = AppleAuthCoordinator(authVM: self)
        controller.presentationContextProvider = UIApplication.shared.windows.first?.rootViewController as? ASAuthorizationControllerPresentationContextProviding
        controller.performRequests()
    }
}

class AppleAuthCoordinator: NSObject, ASAuthorizationControllerDelegate {
    let authVM: AuthViewModel
    
    init(authVM: AuthViewModel) {
        self.authVM = authVM
    }
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        
        authVM.handleAppleSignIn(result: .success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        authVM.handleAppleSignIn(result: .failure(error))
    }
}
