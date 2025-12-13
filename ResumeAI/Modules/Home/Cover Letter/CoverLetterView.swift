//
//  CoverLetterView.swift
//  ResumeAI
//
//  Created by Chaman on 23/11/25.
//

import UIKit
import SwiftUI

enum CoverLetterRoute {
    case generate
    case edit
}

struct CoverLetterSection: View {
    @Binding var coverLetters: [CoverLeter]
    @ObservedObject var viewModel: HomeViewModel

    @State private var showOptions = false
    @State private var selectedCoverLetter: CoverLeter?
    @State private var renameText = ""
    @State private var showRenamePopup = false
    @State private var showDeleteAlert = false

    @State private var route: CoverLetterRoute?
    @State private var navigate = false

    var body: some View {
        ZStack {

            NavigationLink(isActive: $navigate) {
                destinationView()
            } label: {
                EmptyView()
            }
            .hidden()

            if coverLetters.isEmpty {
                emptyStateView(
                    title: "No cover letters available",
                    subtitle: "Click on the + button to create a new cover letter"
                )
            } else {
                List {
                    ForEach(coverLetters) { letter in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(letter.name ?? "")
                                    .font(.body)

                                Text("Last edited: \(letter.updatedAt ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.3))
                        )
                        .onTapGesture {
                            selectedCoverLetter = letter
                            showOptions = true
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                    }
                }
                .listStyle(.plain)
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 5)
                }
                .confirmationDialog(
                    selectedCoverLetter?.name ?? "",
                    isPresented: $showOptions
                ) {
                    Button("Open") {
                        openCoverLetter()
                    }
                    Button("Rename") {
                        renameText = selectedCoverLetter?.name ?? ""
                        showRenamePopup = true
                    }
                    Button("Delete", role: .destructive) {
                        showDeleteAlert = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .alert("Are you sure you want to delete this cover letter?",
                       isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        if let id = selectedCoverLetter?.id {
                            viewModel.deleteCoverLetter(id)
                        }
                    }
                }
            }

            // Rename popup
            if showRenamePopup {
                CreateResumePopup(
                    show: $showRenamePopup,
                    name: $renameText,
                    placeHolder: .constant("Cover Letter Name"),
                    showToast: .constant(false),
                    headerTitle: "Rename"
                ) { updatedName in
                    if let id = selectedCoverLetter?.id {
                        viewModel.updateCoverLetter(
                            id: id,
                            name: updatedName
                        )
                    }
                }
            }
        }
    }

    // MARK: - Navigation Logic

    func openCoverLetter() {
        guard let letter = selectedCoverLetter else { return }

        if let body = letter.details?.coverLetterBody,
           !body.isEmpty {
            //  Go directly to editor
            route = .edit
        } else {
            //  Go to generator
            route = .generate
        }

        navigate = true
    }

    @ViewBuilder
    func destinationView() -> some View {
        if let letter = selectedCoverLetter {
            switch route {
            case .edit:
                CoverLetterEditorScreen(
                    text: letter.details?.coverLetterBody ?? "",
                    coverLetter: letter
                )

            case .generate:
                CoverLetterScreen(
                    viewModel: viewModel,
                    coverLetter: letter
                )

            case .none:
                EmptyView()
            }
        }
    }
}
