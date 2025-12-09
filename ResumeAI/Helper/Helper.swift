//
//  Helper.swift
//  ResumeAI
//
//  Created by Sakshi on 05/12/25.
//

import Foundation
import UIKit

func saveImageToDocuments(_ image: UIImage) -> String? {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
    
    let filename = UUID().uuidString + ".jpg"
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(filename)
    
    do {
        try data.write(to: url)
        return url.path
    } catch {
        print("❌ Error saving image:", error)
        return nil
    }
}
