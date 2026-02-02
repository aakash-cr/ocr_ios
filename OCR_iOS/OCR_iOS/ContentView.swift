import SwiftUI
import PhotosUI
import UIKit
import Combine

struct ContentView: View {
    @StateObject private var viewModel = OCRViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var showPhotosPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    // Content area
                    if viewModel.isProcessing {
                        // Loading state
                        VStack(spacing: 20) {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Processing OCR...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if viewModel.form != nil {
                        // Results form
                        Form {
                            Section(header: Text("Consumer Details")) {
                                TextField("Consumer Name", text: Binding(
                                    get: { viewModel.form?.consumerName ?? "" },
                                    set: { viewModel.updateConsumerName($0) }
                                ))
                                
                                TextField("Mobile Number", text: Binding(
                                    get: { viewModel.form?.mobileNumber ?? "" },
                                    set: { viewModel.updateMobileNumber($0) }
                                ))
                                .keyboardType(.phonePad)
                            }
                            
                            Section(header: Text("Meter Details")) {
                                TextField("Meter Number", text: Binding(
                                    get: { viewModel.form?.meterNumber ?? "" },
                                    set: { viewModel.updateMeterNumber($0) }
                                ))
                                
                                TextField("KWH Reading", text: Binding(
                                    get: { viewModel.form?.reading ?? "" },
                                    set: { viewModel.updateReading($0) }
                                ))
                                .keyboardType(.decimalPad)
                            }
                            
                            Section {
                                Button("Save Form") {
                                    viewModel.saveForm()
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity)
                                
                                Button("Scan Another Form") {
                                    viewModel.resetForm()
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    } else {
                        // Initial empty state
                        VStack(spacing: 30) {
                            Spacer()
                            
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                            
                            Text("Utility Form Scanner")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Scan or select a utility form to extract consumer and meter information")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                    }
                    
                    // Large Scan Form button at bottom
                    if !viewModel.isProcessing {
                        VStack(spacing: 0) {
                            Divider()
                            
                            Button(action: {
                                showActionSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Scan Form")
                                        .fontWeight(.semibold)
                                }
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color.blue)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle("OCR Scanner")
            .confirmationDialog("Select Image Source", isPresented: $showActionSheet, titleVisibility: .visible) {
                Button("Photo Library") {
                    showPhotosPicker = true
                }
                
                Button("Camera") {
                    showImagePicker = true
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { oldValue, newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.processImage(image)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                CameraPickerView { image in
                    if let image = image {
                        Task {
                            await viewModel.processImage(image)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Camera Picker
struct CameraPickerView: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage?) -> Void
        
        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true) {
                self.completion(image)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.completion(nil)
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
class OCRViewModel: ObservableObject {
    @Published var form: UtilityForm?
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let ocrProcessor = OCRProcessor()
    
    func processImage(_ image: UIImage) async {
        await MainActor.run {
            isProcessing = true
            showError = false
        }
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ocrProcessor.processImage(image) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    
                    self.isProcessing = false
                    
                    switch result {
                    case .success(let extractedForm):
                        self.form = extractedForm
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    func updateConsumerName(_ value: String) {
        guard var currentForm = form else { return }
        currentForm.consumerName = value
        form = currentForm
    }
    
    func updateMobileNumber(_ value: String) {
        guard var currentForm = form else { return }
        currentForm.mobileNumber = value
        form = currentForm
    }
    
    func updateMeterNumber(_ value: String) {
        guard var currentForm = form else { return }
        currentForm.meterNumber = value
        form = currentForm
    }
    
    func updateReading(_ value: String) {
        guard var currentForm = form else { return }
        currentForm.reading = value
        form = currentForm
    }
    
    func saveForm() {
        guard let form = form else { return }
        print("Form saved:")
        print("  Consumer Name: \(form.consumerName)")
        print("  Mobile Number: \(form.mobileNumber)")
        print("  Meter Number: \(form.meterNumber)")
        print("  Reading: \(form.reading)")
        // Add your save logic here (Core Data, API call, etc.)
    }
    
    func resetForm() {
        form = nil
    }
}

#Preview {
    ContentView()
}
