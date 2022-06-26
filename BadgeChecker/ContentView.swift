//
//  ContentView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 03/04/2022.
//

import SwiftUI
import CodeScanner

struct ContentView: View {
    @State var isPresentingScanner = false
    @State var scannedCode: String = "Scan a QR code to get started."
    
    var scannerSheet : some View {
        CodeScannerView(codeTypes: [.qr], completion: handleScan)
    }
        
    var body: some View {
        
        // Title stack
        Group {
            Text("Badge Checker")
                .font(.title)
                .foregroundColor(.blue)
            Divider()
        }
        
        //  QR code stack
        Group {
            Text(scannedCode)
            
            Button {
                isPresentingScanner = true
            } label: {
                Label("Scan", systemImage: "qrcode.viewfinder")
            }
            .sheet(isPresented: $isPresentingScanner) {
                self.scannerSheet
            }
        }
        
        
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isPresentingScanner = false
        
        switch result {
        case .success(let result):
            self.scannedCode = result.string
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
