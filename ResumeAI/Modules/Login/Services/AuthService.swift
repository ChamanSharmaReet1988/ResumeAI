//
//  AuthService.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 18/11/25.
//

import Foundation
import FirebaseAuth

enum AuthState {
    case loading
    case unauthenticated
    case authenticated
}

final class AuthService {
    
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Phone Auth
    
    func startPhoneNumberAuth(phoneNumber: String,
                              completion: @escaping (Result<String, Error>) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let verificationID = verificationID else {
                completion(.failure(NSError(domain: "AuthService",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Verification ID missing"])))
                return
            }
            completion(.success(verificationID))
        }
    }
    
    func verifyCode(verificationID: String,
                    smsCode: String,
                    completion: @escaping (Result<User, Error>) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID,
                                                                 verificationCode: smsCode)
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "AuthService",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "User missing"])))
                return
            }
            completion(.success(user))
        }
    }
    
    // MARK: - Google / Apple
    
    func setCurrentUser(_ user: User?) {
        // You can add extra logic to store user details in Firestore if needed.
    }
    
    func logout() throws {
        try Auth.auth().signOut()
    }
}
