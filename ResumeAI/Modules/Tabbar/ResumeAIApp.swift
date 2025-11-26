//
//  ResumeAIApp.swift
//  ResumeAI
//
//  Created by Chaman on 22/02/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
#if DEBUG
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
#endif
        Database.createDatabase()
        debugPrint("Firebase configured:", FirebaseApp.app() != nil)
        debugPrint("Verification disabled:", Auth.auth().settings?.isAppVerificationDisabledForTesting ?? false)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // Determine the APNs environment based on the build configuration.
        #if DEBUG
            // Use .sandbox for development, debugging, and the iOS Simulator
            let apnsType: AuthAPNSTokenType = .sandbox
        #else
            // Use .prod for production (App Store or TestFlight builds)
            let apnsType: AuthAPNSTokenType = .prod
        #endif
        
        // Forward the device token and the determined environment type to Firebase Auth.
        Auth.auth().setAPNSToken(deviceToken, type: apnsType)
        
    }
    
    // Required method for notification data
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Forward the remote notification to Firebase Auth
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
    }
}

@main
struct ResumeAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainRootView()
                .environmentObject(authViewModel)
        }
    }
}
