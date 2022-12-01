//
//  QRScanView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import CodeScanner
import Popovers

func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    return .none
}

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
    var status: String?
    var statusCode: String?
    var response: ScanWalletResponse?
}

struct CheckByNameResponse: Codable {
    var badgeEntityIds: [String]?
    var debug: String?
}

struct CheckByNameResult: Codable {
    var status: String?
    var statusCode: String?
    var response: CheckByNameResponse?
}

struct QRScanView: View {
    
    @EnvironmentObject var loginInfo: LoginInfo
    @EnvironmentObject var scanInfo: ScanInfo
    
    @State var scannedUserId: String? = nil
    @State var badgeEntities: [BadgeEntity]?
    @State var badgeEntityIds: [String]?
    @State var debug: String = ""
    @State var isPresentingScanner = false
    @State var successScan = false
    @State var failScan = false
    @State var isPresentingListArgs = false
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var showPopover = false
    
    var scannerSheet : some View {
        CodeScannerView(codeTypes: [.qr], completion: handleScan)
    }
        
    var body: some View {
        
        ZStack {
            VStack {
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        
                        HStack {
                            if successScan {
                                Image(systemName: "person.fill.checkmark")
                                    .foregroundColor(.green)
                                    .font(.system(size: 60))
                                    .padding(30)
                                    .hoverEffect(.lift)

                                if (badgeEntities != nil && badgeEntities!.isEmpty) || (badgeEntityIds != nil && badgeEntityIds!.isEmpty) {
                                    Image(systemName: "text.badge.xmark")
                                        .foregroundColor(.red)
                                        .font(.system(size: 60))
                                        .padding(30)

                                } else {
                                    Image(systemName: "text.badge.checkmark")
                                        .foregroundColor(.green)
                                        .font(.system(size: 60))
                                        .padding(30)
                                }
                            }
                            
                            if failScan {
                                Image(systemName: "person.fill.xmark")
                                    .foregroundColor(.red)
                                    .font(.system(size: 60))
                                    .padding(30)
                            }
                                
                        }
                        .frame(height: geometry.size.width * 0.50, alignment: .top)
                        .onTapGesture {
                            showPopover = true
                        }
                        .popover(present: $showPopover,
                                 attributes: {
                                         $0.position = .absolute(
                                             originAnchor: .center,
                                             popoverAnchor: .center
                                         )
                                         $0.sourceFrameInset.top = -5
                                     }) {
                            Text(debug)
                                .font(.title3)
                                .padding()
                                .frame(maxWidth: 350)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                        }
                        
                    
                        VStack {
                            if isPresentingListArgs {
                                TextField("First name", text: $firstName)
                                    .disableAutocorrection(true)
                                    .foregroundColor(Color("KentoBeige"))
                                    .autocapitalization(.none)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 350, height: 40)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                                TextField("Last name", text: $lastName)
                                    .disableAutocorrection(true)
                                    .foregroundColor(Color("KentoBeige"))
                                    .autocapitalization(.none)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 350, height: 40)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                                if firstName.count > 0 && lastName.count > 0 {
                                    Button("Check list") {
                                        checkParticipantByName(firstName: firstName, lastName: lastName, scanTerminal: scanInfo.scanTerminal!.id, scanLocation: scanInfo.scanTerminal!.scanLocationId) { result in
                                            switch result {
                                            case .success(_):
                                                successScan = true
                                                failScan = false
                                            case .failure(_):
                                                successScan = false
                                                failScan = true
                                            }
                                        }
                                    }
                                    .font(.title3)
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .padding()
                                    .frame(minWidth: 0, maxWidth: 350)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                                }
                            }
                        }
                        .frame(height: geometry.size.width * 0.50, alignment: .top)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                    }
                }
                
                
                    
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Button {
                            isPresentingScanner = true
                            isPresentingListArgs = false
                        } label: {
                            Label("Scan", systemImage: "qrcode.viewfinder")
                                .font(.title2)
                        }
                        .sheet(isPresented: $isPresentingScanner) {
                            self.scannerSheet
                        }
                        .frame(width: geometry.size.width * 0.50, alignment: .center)
                    
                        Divider()
                        
                        Button {
                            isPresentingListArgs = true
                        } label : {
                            Label("List", systemImage: "list.dash")
                                .font(.title2)
                        }
                        .frame(width: geometry.size.width * 0.50, alignment: .center)
                    }
                }
                .frame(height: 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
                
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
            scanWallet(userId: scannedUserId!, scanTerminalId: scanInfo.scanTerminal!.id) { result in
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
                    if scanWalletResult.response?.badgeEntities! != nil {
                        badgeEntities = scanWalletResult.response?.badgeEntities!
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
    
    func checkParticipantByName(firstName: String, lastName: String, scanTerminal: String, scanLocation: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }
        
        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/ScanWallet"
        let parameters = [
          [
            "key": "firstName",
            "value": firstName,
            "type": "text"
          ],
          [
            "key": "lastName",
            "value": lastName,
            "type": "text"
          ],
          [
            "key": "scanTerminal",
            "value": scanTerminal,
            "type": "text"
          ],
          [
            "key": "scanLocation",
            "value": scanLocation,
            "type": "text"
          ]
        ] as [[String : Any]]
        let request = multipartRequest(urlString: urlString, parameters: parameters, token: loginInfo.token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    let dataString = String(data: data!, encoding: .utf8),
                    let result = try? JSONDecoder().decode(CheckByNameResult.self, from: data!)
                else {
                    print("error")
                    print(response.debugDescription)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }
                DispatchQueue.main.async {
                    print("dispatch")
                    print(dataString)
                    badgeEntityIds = result.response!.badgeEntityIds
                    if result.response!.debug != nil {
                        debug = result.response!.debug!
                    }
                }
                print("success")
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
