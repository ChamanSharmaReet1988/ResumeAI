//
//  CommonUIComponent.swift
//  ResumeAI
//
//  Created by Chaman on 04/05/25.
//

import SwiftUI

import SwiftUI

struct HomeActionButton: View {
    var title: String
    var icon: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(width: 100, height: 100)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}
