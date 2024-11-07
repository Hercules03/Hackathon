import PhotosUI
import SwiftUI
import VisionKit

struct ContentView: View {
    
    @EnvironmentObject var vm: AppViewModel
    
    private let textScanningModes = [
        ("All", TextScanningMode.all),
        ("Numbers", TextScanningMode.numbersOnly)
    ]
    
    var body: some View {
        switch vm.dataScannerAccessStatus {
        case .scannerAvailable:
            mainView
        case .cameraNotAvailable:
            Text("Your device doesn't have a camera")
        case .scannerNotAvailable:
            Text("Your device doesn't have support for scanning barcode with this app")
        case .cameraAccessNotGranted:
            Text("Please provide access to the camera in settings")
        case .notDetermined:
            Text("Requesting camera access")
        }
    } 
    
    private var mainView: some View {
        liveImageFeed
            .background { Color.gray.opacity(0.3) }
            .ignoresSafeArea()
            .id(vm.dataScannerViewId)
            .sheet(isPresented: $vm.isShowingCamera) {
                // Return to scanning mode after camera is dismissed
                vm.showPhotoButton = false
                vm.currentText = ""
            } content: {
                if let currentScannedItem = vm.currentScannedItem {
                    CameraView(scannedItem: currentScannedItem) { success in
                        if success {
                            vm.isShowingCamera = false
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                bottomContainerView
                    .background(.ultraThinMaterial)
                    .frame(height: 250)
            }
            .onChange(of: vm.scanType) { _ in vm.recognizedItems = [] }
            .onChange(of: vm.textScanningMode) { _ in vm.recognizedItems = [] }
    }
    
    @ViewBuilder
    private var liveImageFeed: some View {
        DataScannerView(
            recognizedItems: $vm.recognizedItems,
            recognizedDataType: vm.recognizedDataType)
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 8)
            
            Picker("Scan Type", selection: $vm.scanType) {
                Text("Barcode").tag(ScanType.barcode)
                Text("Text").tag(ScanType.text)
            }.pickerStyle(.segmented)
            
            if vm.scanType == .text {
                Picker("Text content type", selection: $vm.textScanningMode) {
                    ForEach(textScanningModes, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(vm.headerText)
                        if vm.scanType == .text && !vm.currentText.isEmpty {
                            Button(action: {
                                vm.scanDetectedText()
                            }) {
                                Text("Scan")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    if !vm.currentBarcode.isEmpty && vm.scanType == .barcode {
                        Text("Last recorded: \(vm.currentBarcode)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else if vm.scanType == .text {
                        if !vm.currentText.isEmpty {
                            Text("Current text: \(vm.currentText)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        if !vm.lastRecordedText.isEmpty {
                            Text("Last recorded: \(vm.lastRecordedText)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
                
                if vm.showPhotoButton {
                    Button {
                        vm.isShowingCamera = true
                        print("Camera button tapped")
                    } label: {
                        Image(systemName: "camera.circle")
                            .imageScale(.large)
                    }
                }
            }
        }.padding(.horizontal)
    }
    
    private var bottomContainerView: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.bottom, 8)
                .padding(.bottom, 8)
            Divider()
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(vm.confirmedItems) { item in
                        switch item {
                        case .barcode(let barcode):
                            Text(barcode.payloadStringValue ?? "Unknown barcode")
                                .foregroundColor(.gray)
                        case .text(let text):
                            Text(text.transcript)
                                .foregroundColor(.gray)
                        @unknown default:
                            Text("Unknown")
                        }
                    }
                }
                .padding()
            }
            HStack {
                Text("Cargo Recognization")
                    .foregroundColor(.gray)
                Spacer()
                Toggle("", isOn: $vm.isObjectDetectionEnabled)
                    .labelsHidden()
                    .onChange(of: vm.isObjectDetectionEnabled) { newValue in
                        if newValue {
                            vm.handleObjectDetectionToggle()
                        }
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .alert("Detected Cargo", isPresented: $vm.showDetectedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.detectedNumberText)
            }
        }
        .alert("Record Barcode", isPresented: $vm.showingRecordAlert) {
            Button("Yes") {
                vm.recordBarcode()
            }
            Button("No", role: .cancel) {
                vm.showingRecordAlert = false
                vm.isPausedForAlert = false
                vm.recognizedItems = []
            }
        } message: {
            Text("Do you want to record \(vm.currentBarcode)?")
        }
        .overlay(alignment: .top) {
            if vm.showingSuccessToast {
                Text("Successfully recorded")
                    .padding()
                    .background(.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 20)
            }
        }
    }
}
