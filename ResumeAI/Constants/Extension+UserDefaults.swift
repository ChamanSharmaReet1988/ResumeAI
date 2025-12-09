//
//  Extension+UserDefaults.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 26/11/25.
//

import Foundation

extension UserDefaults {
    static let isLoggedInKey = "isLoggedIn"
}

extension Date {
    func toString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
