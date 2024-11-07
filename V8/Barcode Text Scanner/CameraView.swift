import SwiftUI
import AVFoundation
import VisionKit

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var camera = CameraModel()
    let scannedItem: RecognizedItem
    let onPhotoTaken: (Bool) -> Void
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Button {
                    camera.takePicture()
                    onPhotoTaken(true)
                    dismiss()
                } label: {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            camera.checkPermissions { error in
                if let error = error {
                    print("Camera permission error: \(error)")
                }
            }
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var showSuccessAlert = false
    
    let output = AVCapturePhotoOutput()
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func setupCamera() {
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                DispatchQueue.global(qos: .background).async {
                    self.session.startRunning()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func checkPermissions(completion: @escaping (String?) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(nil)
                    } else {
                        completion("Camera access is required to take photos")
                    }
                }
            }
        case .denied, .restricted:
            completion("Please enable camera access in Settings")
        @unknown default:
            completion("Unknown camera authorization status")
        }
    }
    
    func takePicture() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            if let image = UIImage(data: imageData) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                DispatchQueue.main.async {
                    self.showSuccessAlert = true
                }
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
