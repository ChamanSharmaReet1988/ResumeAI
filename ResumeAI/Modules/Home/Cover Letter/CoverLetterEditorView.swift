//
//  CoverLetterEditorView.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 06/12/25.
//

import SwiftUI

struct CoverLetterScreen: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: HomeViewModel
    var coverLetter: CoverLeter

    @State private var companyName = ""
    @State private var jobPosition = ""
    @State private var skill = ""
    @State private var language = "English"

    @State private var showAlert = false
    @State private var alertMessage = ""

    @State private var navigateToEditor = false
    @State private var generatedText = ""

    let languages = ["English", "Hindi", "Spanish", "German"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // TOP DESCRIPTION
                Text("Leverage the most advanced Artificial Intelligence to create a unique Cover Letter.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                Text("Please mention the Company and Job Position you are applying to, as well as which specific skill you would like to highlight in this Cover Letter.")
                    .font(.body)
                    .multilineTextAlignment(.center)

                Text("Choose language then tap ‘Create my unique Cover Letter’. The AI will create it and you will then be able to Edit the text to further customize it.")
                    .font(.body)
                    .multilineTextAlignment(.center)

                formField(title: "Company name", placeholder: "Company name", text: $companyName)
                formField(title: "Job Position Name", placeholder: "Job position", text: $jobPosition)
                formField(title: "Skill to highlight", placeholder: "Eye for quality", text: $skill)

                VStack(alignment: .leading) {
                    Text("Language")
                    Picker("Language", selection: $language) {
                        ForEach(languages, id: \.self) { Text($0) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                Button {
                    validateAndGenerate()
                } label: {
                    Text("Create my unique Cover Letter")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
                .alert(alertMessage, isPresented: $showAlert) { Button("OK", role: .cancel) {} }

            }
            .padding()
        }
        .navigationTitle("Cover Letter")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .background(
            NavigationLink(
                destination: CoverLetterEditorScreen(text: generatedText,
                                                     coverLetter: coverLetter).id(UUID()),
                isActive: $navigateToEditor
            ) { EmptyView() }
            .hidden()
        )
    }

    func validateAndGenerate() {
        if companyName.isEmpty { alert("Please enter a company name.") ; return }
        if jobPosition.isEmpty { alert("Please enter a job position.") ; return }
        if skill.isEmpty { alert("Please enter a skill.") ; return }
        
        generatedText = generateCoverLetter(company: companyName,
                                            position: jobPosition,
                                            skill: skill)
        
        let details = CoverLeterDetail(companyName: companyName,
                                       jobPosition: jobPosition,
                                       skills: skill, language: language,
                                       coverLetterBody: generatedText)
        viewModel.updateCoverLetter(id: coverLetter.id ?? .zero,
                                    name: coverLetter.name ?? "",
                                    details: details)

        navigateToEditor = true
    }
    
    func generateCoverLetter(company: String, position: String, skill: String) -> String {
        """
        [Your Name]
        [Address]
        [City, State, Zip]
        [Email Address]
        [Phone Number]
        [Today’s Date]

        [Hiring Manager’s Name]
        \(company)
        [Company’s Address]
        [City, State, Zip]

        Dear [Hiring Manager’s Name],

        I am writing to express my interest in the \(position) position at \(company). With a strong background in \(skill), I am confident in my ability to contribute effectively to your team.

        Throughout my career, I have honed my skills by delivering impactful results and aligning with organizational goals. I am committed to bringing my experience and passion to \(company) and making a positive impact.

        Thank you for considering my application. I look forward to the opportunity to discuss how my qualifications align with your needs.

        Sincerely,
        [Your Name]
        """
    }

    func alert(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }

    func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
            TextField(placeholder, text: text)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}
