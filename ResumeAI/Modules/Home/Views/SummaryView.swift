//
//  SummaryView.swift
//  ResumeAI
//
//  Created by Sakshi on 03/12/25.
//

import SwiftUI

struct SummaryView: View {
    var section: ResumeSectionModel
    
    @State private var summaryText: String = ""
    @State private var textHeight: CGFloat = 100
    
    let maxCharacters = 2000
    let summaryTable = SummaryTable()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                ZStack(alignment: .topLeading) {
                    
                    if summaryText.isEmpty {
                        Text("Enter your summary here...")
                            .foregroundColor(Color.gray.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    
                    TextEditor(text: $summaryText)
                        .frame(minHeight: 100, maxHeight: textHeight)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                .background(Color.white)
                        )
                        .onChange(of: summaryText) { _ in
                            if summaryText.count > maxCharacters {
                                summaryText = String(summaryText.prefix(maxCharacters))
                            }
                        }
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ViewHeightKey.self, value: geo.size.height)
                            }
                        )
                }
                
                Text("\(summaryText.count)/\(maxCharacters)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Button(action: saveSummary) {
                    Text("Save")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
            }
            .padding()
        }
        .navigationTitle(section.name ?? "Summary")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onPreferenceChange(ViewHeightKey.self) { value in
            if value > 100 {
                textHeight = value
            }
        }
    }
    
    func saveSummary() {
        let dateString = Date().toString()  

        let summaryModel = SummaryModel(
            id: nil,
            summary: summaryText,
            createdAt: dateString,
            updatedAt: dateString
        )

        SummaryTable().saveSummary(summary: summaryModel) { success, error, insertedId in
            if success {
                print("✅ Summary saved successfully with ID: \(insertedId ?? 0)")
            } else {
                print("❌ Failed to save summary: \(error ?? "Unknown error")")
            }
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 100
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SummaryView(section: ResumeSectionModel(name: "Summary"))
        }
    }
}
