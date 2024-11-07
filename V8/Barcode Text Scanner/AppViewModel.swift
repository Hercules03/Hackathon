import AVKit
import Foundation
import PhotosUI
import SwiftUI
import VisionKit

enum ScanType: String {
    case barcode, text
}

enum DataScannerAccessStatusType {
    case notDetermined
    case cameraAccessNotGranted
    case cameraNotAvailable
    case scannerAvailable
    case scannerNotAvailable
}

enum TextScanningMode {
    case all
    case numbersOnly
}

@MainActor
final class AppViewModel: ObservableObject {
    
    @Published var dataScannerAccessStatus: DataScannerAccessStatusType = .notDetermined
    @Published var recognizedItems: [RecognizedItem] = []
    @Published var scanType: ScanType = .barcode
    @Published var textContentType: DataScannerViewController.TextContentType?
    
    @Published var showingRecordAlert = false
    @Published var showingSuccessToast = false
    @Published var currentBarcode = ""
    @Published var isPausedForAlert = false
    
    @Published var confirmedItems: [RecognizedItem] = []
    
    @Published var isNumbersOnlyMode: Bool = false
    
    @Published var textScanningMode: TextScanningMode = .all
    
    @Published var currentNumber = ""
    @Published var showingNumberRecordAlert = false
    
    @Published var detectedText: String = "No text detected"
    
    @Published var showCameraView = false
    @Published var currentScannedItem: RecognizedItem?
    
    @Published var showPhotoButton = false
    
    @Published var shouldNavigateToCamera = false
    @Published var lastScannedData: (type: String, value: String)?
    
    @Published var shouldCapturePhoto = false
    @Published var capturedPhoto: IdentifiableImage? = nil
    @Published var selectedPhotoPickerItem: PhotosPickerItem? = nil
    
    @Published var currentText = ""
    
    @Published var lastRecordedText = ""
    
    @Published var isShowingCamera = false {
        didSet {
            print("isShowingCamera changed to: \(isShowingCamera)")
        }
    }
    @Published var shouldReturnToScanning = false
    
    @Published var isObjectDetectionEnabled = false
    
    @Published var showDetectedNumber = false
    @Published var detectedNumberText = "884024914/10"
    
    @Published var showDetectedAlert = false
    
    var recognizedDataType: DataScannerViewController.RecognizedDataType {
        scanType == .barcode ? .barcode() : .text(textContentType: .none)
    }
    
    var headerText: String {
        if confirmedItems.isEmpty {
            return "Scanning \(scanType.rawValue)"
        } else {
            return "Recorded \(confirmedItems.count) item(s)"
        }
    }
    
      var dataScannerViewId: Int {
        var hasher = Hasher()
        hasher.combine(scanType)
        if let textContentType {
            hasher.combine(textContentType)
        }
        return hasher.finalize()
    }
    
    private var isScannerAvailable: Bool {
        DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }
    
    func requestDataScannerAccessStatus() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dataScannerAccessStatus = .cameraNotAvailable
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            
        case .restricted, .denied:
            dataScannerAccessStatus = .cameraAccessNotGranted
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            } else {
                dataScannerAccessStatus = .cameraAccessNotGranted
            }
        
        default: break
            
        }
    }
    
    func recordBarcode() {
        if let currentItem = recognizedItems.last {
            confirmedItems.append(currentItem)
            currentScannedItem = currentItem
            showPhotoButton = true
        }
        showingRecordAlert = false
        isPausedForAlert = false
        recognizedItems = []
        
        showingSuccessToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showingSuccessToast = false
        }
    }
    
    func recordNumber() {
        if let currentItem = recognizedItems.last {
            currentScannedItem = currentItem
            showCameraView = true
            print("Debug: Camera view should show")
        }
        showingNumberRecordAlert = false
        showingSuccessToast = true
        recognizedItems = []
        
        // Reset the success toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showingSuccessToast = false
        }
    }
    
    private func isNumberString(_ str: String) -> Bool {
        let numberRegex = try? NSRegularExpression(pattern: "^[0-9()\\-]+$")
        return numberRegex?.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)) != nil
    }
    
    func scanDetectedText() {
        if let currentItem = recognizedItems.last {
            confirmedItems.append(currentItem)
            currentScannedItem = currentItem
            if case .text(let text) = currentItem {
                lastRecordedText = text.transcript
            }
            showPhotoButton = true
        }
        recognizedItems = []
        
        showingSuccessToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showingSuccessToast = false
        }
    }
    
    func showCamera() {
        isShowingCamera = true
        shouldCapturePhoto = true
    }
    
    func handleObjectDetectionToggle() {
        if isObjectDetectionEnabled {
            // Wait for 1 second then show the alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showDetectedAlert = true
                // Reset toggle after alert is dismissed
                self.isObjectDetectionEnabled = false
            }
        }
    }
    
}
