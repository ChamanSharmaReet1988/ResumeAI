//
//  PersonalInfoView.swift
//  ResumeAI
//
//  Created by Sakshi on 03/12/25.
//

import SwiftUI
import PhotosUI

struct PersonalInfoView: View {
    var section: ResumeSectionModel

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    
    @State private var selectedImage: UIImage? = nil
    @State private var isShowingImagePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                RoundedTextField("Name", text: $name)
                RoundedTextField("Address", text: $address)
                RoundedTextField("Phone Number", text: $phoneNumber, keyboard: .phonePad)
                RoundedTextField("Email", text: $email, keyboard: .emailAddress)
                
                VStack(spacing: 12) {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Text("Select Image")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                .padding(.top, 20)
                
                Button(action: {
                    savePersonalInfo()
                }) {
                    Text("Save")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 30)
                
            }
            .padding()
        }
        .navigationTitle(section.name ?? "Personal Info")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    func savePersonalInfo() {
        
        let imagePath = selectedImage != nil ? saveImageToDocuments(selectedImage!) : nil
        
        let info = PersonalInfoModel(
            id: nil,
            name: name,
            phone: phoneNumber,
            email: email,
            address: address,
            imagePath: imagePath,
            createdAt: Date().description,
            updatedAt: Date().description
        )
        
        PersonalInfoTable().savePersonalInfo(info) { success, error in
            if success {
                print("✅ Personal Info Saved")
            } else {
                print("❌ Save Failed:", error ?? "")
            }
        }
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> some UIViewController {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonalInfoView(section: ResumeSectionModel(name: "Personal Info"))
        }
    }
}
