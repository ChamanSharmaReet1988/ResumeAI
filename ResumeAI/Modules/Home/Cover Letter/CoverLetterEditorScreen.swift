//
//  CoverLetterEditorScreen.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 13/12/25.
//

import SwiftUI
import PDFKit

struct CoverLetterEditorScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    var selectedCoverLetter: CoverLeter

    @State private var coverLetterText: String
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var showPDFPreview = false
    @State private var pdfURL: URL?

    init(text: String, coverLetter: CoverLeter) {
        _coverLetterText = State(initialValue: text)
        self.selectedCoverLetter = coverLetter
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            VStack {
                TextEditor(text: $coverLetterText)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            }
            .padding(.bottom, keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .navigationTitle("Cover")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
            }
            // PDF Action
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    pdfURL = generatePDF(from: coverLetterText)
                    showPDFPreview = true
                } label: {
                    Image(systemName: "doc.richtext")
                }
            }
        }
        
        .sheet(isPresented: $showPDFPreview) {
            if let url = pdfURL {
                PDFPreviewView(pdfURL: url)
            }
        }
    }
    
    // MARK: - PDF Generate
    func generatePDF(from text: String) -> URL {
        let pdfMetaData = [
            kCGPDFContextCreator: "ResumeAI",
            kCGPDFContextAuthor: "Cover Letter"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let letterName = "\(selectedCoverLetter.name ?? "")_CoverLetter.pdf"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(letterName)

        try? renderer.writePDF(to: url) { context in
            context.beginPage()

            let textRect = CGRect(x: 40, y: 40, width: pageWidth - 80, height: pageHeight - 80)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]

            text.draw(in: textRect, withAttributes: attrs)
        }

        return url
    }
}

struct PDFPreviewView: View {
    let pdfURL: URL

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(url: pdfURL)
                .navigationTitle("PDF Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: pdfURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
