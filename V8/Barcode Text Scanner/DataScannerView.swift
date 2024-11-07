import Foundation
import SwiftUI
import VisionKit

struct DataScannerView: UIViewControllerRepresentable {
    
    @EnvironmentObject var vm: AppViewModel
    @Binding var recognizedItems: [RecognizedItem]
    let recognizedDataType: DataScannerViewController.RecognizedDataType
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [recognizedDataType],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        try? uiViewController.startScanning()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedItems: $recognizedItems, vm: vm)
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        
        @Binding var recognizedItems: [RecognizedItem]
        var vm: AppViewModel

        init(recognizedItems: Binding<[RecognizedItem]>, vm: AppViewModel) {
            self._recognizedItems = recognizedItems
            self.vm = vm
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            print("didTapOn \(item)")
        }
        
        private func isNumberString(_ str: String) -> Bool {
            let numberRegex = try? NSRegularExpression(pattern: "^[0-9()\\-]+$")
            return numberRegex?.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)) != nil
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !vm.isPausedForAlert else { return }
            
            for item in addedItems {
                if case .barcode(let barcode) = item {
                    vm.currentBarcode = barcode.payloadStringValue ?? "Unknown"
                    vm.showingRecordAlert = true
                    vm.isPausedForAlert = true
                    vm.showPhotoButton = true
                    recognizedItems.append(item)
                    break
                } else if case .text(let text) = item {
                    vm.currentText = text.transcript
                    recognizedItems.append(item)
                    break
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            self.recognizedItems = recognizedItems.filter { item in
                !removedItems.contains(where: {$0.id == item.id })
            }
            print("didRemovedItems \(removedItems)")
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("became unavailable with error \(error.localizedDescription)")
        }
        
    }
    
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
