//
//  QRScanView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import CodeScanner


struct BadgeEntity: Codable {
    var id: String
    var parentBadgeId: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case parentBadgeId = "ParentBadge"
    }
}

struct ScanWalletResponse: Codable {
    var badgeEntities: [BadgeEntity]?
}

struct ScanWalletResult: Codable {
    var status: String
    var response: ScanWalletResponse
    
}

struct QRScanView: View {
    
    @EnvironmentObject var loginInfo: LoginInfo
    @EnvironmentObject var scanTerminal: ScanTerminalObservable
    @State var scannedUserId: String? = nil
    @State var badgeEntites: [BadgeEntity]?
    @State var isPresentingScanner = false
    @State var successScan = false
    @State var failScan = false
    
    var scannerSheet : some View {
        CodeScannerView(codeTypes: [.qr], completion: handleScan)
    }
        
    var body: some View {
        
        ZStack {
            VStack {
                
                if successScan {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.green)
                        .font(.system(size: 60))
                        .padding(30)
                }
                
                if failScan {
                    Image(systemName: "person.fill.xmark")
                        .foregroundColor(.red)
                        .font(.system(size: 60))
                        .padding(30)
                }
                
                Button {
                    isPresentingScanner = true
                } label: {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                        .font(.title3)
                }
                .sheet(isPresented: $isPresentingScanner) {
                    self.scannerSheet
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
        
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        successScan = false
        failScan = false
        isPresentingScanner = false
        
        switch result {
        case .success(let result):
            self.scannedUserId = result.string
            scanWallet(userId: scannedUserId!, scanTerminalId: scanTerminal.id) { result in
                switch result {
                case .success(_):
                    successScan = true
                    failScan = false
                case .failure(_):
                    successScan = false
                    failScan = true
                }
            }
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    func scanWallet(userId: String, scanTerminalId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }
        
        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/ScanWallet"
        let parameters = [
          [
            "key": "UserId",
            "value": userId,
            "type": "text"
          ],
          [
            "key": "ScanTerminalId",
            "value": scanTerminalId,
            "type": "text"
          ]] as [[String : Any]]
        let request = multipartRequest(urlString: urlString, parameters: parameters, token: loginInfo.token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    let dataString = String(data: data!, encoding: .utf8),
                    let scanWalletResult = try? JSONDecoder().decode(ScanWalletResult.self, from: data!)
                else {
                    print(response.debugDescription)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }
                DispatchQueue.main.async {
                    print(dataString)
                    if scanWalletResult.response.badgeEntities != nil {
                        badgeEntites = scanWalletResult.response.badgeEntities
                    } else {
                        print("Badge entities empty")
                    }
                }
                completion(.success(true))
            } else {
                if let error = error {
                    completion(.failure(error))
                }
            }
            
        }.resume()
    }
}

struct QRScanView_Previews: PreviewProvider {
    static var previews: some View {
        QRScanView()
    }
}
