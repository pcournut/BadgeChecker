//
//  EventInitView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import Foundation

class ScanTerminalObservable: ObservableObject {
    @Published var id : String = ""
    @Published var volunteerName: String = ""
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}


struct Organisation : Codable {
    var id: String
    var name: String?
}

struct Event : Codable {
    var id: String
    var name: String
    var mainPicture: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        
        case name
        case mainPicture
    }
}

struct ScanLocation : Codable {
    var name: String
    var id: String
    var eventID: String?
    
    private enum CodingKeys: String, CodingKey {
        case eventID = "EventId"
        case name = "Name"
        case id = "_id"
    }
}

struct Badge: Codable {
    var name: String
    
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
    }
}

struct ScanTerminal: Codable {
    var id: String
    var volunteerName: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case volunteerName = "VolunteerName"
    }
}

struct EventInitResponse: Codable {
    var orgIds: [String]?
    var orgNames: [String]?
    var events: [Event]?
    var scanLocations: [ScanLocation]?
    var badges: [Badge]?
    var scanTerminal: ScanTerminal?
}

struct EventInitResult: Codable {
    var status: String
    var response: EventInitResponse
}

struct EventInitView: View {
    
    @EnvironmentObject var loginInfo: LoginInfo
    @State var title = "organisation"
    @State var volunteerName = ""
    @State var orgIds: [String]?
    @State var orgNames: [String]?
    @State var orgs: [Organisation]?
    @State var events: [Event]?
    @State var scanLocations: [ScanLocation]?
    @State var badges: [Badge]?
    @StateObject var scanTerminal = ScanTerminalObservable()
    @State private var isShowingQRScanView: Bool = false
    
    var body : some View {
        
        NavigationView {
            ZStack {
                VStack {
                    NavigationLink(destination: QRScanView(), isActive: $isShowingQRScanView) {
                        EmptyView()
                    }
                    
                    TextField("Volunteer name", text: $volunteerName)
                        .disableAutocorrection(true)
                        .foregroundColor(Color("KentoBeige"))
                        .multilineTextAlignment(.center)
                        .frame(width: 350, height: 40)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                        .padding()
                    
                    // Fetch orgnisations
                    if orgIds == nil  {
                        if events == nil && scanLocations == nil && !volunteerName.isEmpty {
                            Button("Fetch organisations") {
                                eventInit(volunteerName: volunteerName) { result in
                                    switch result {
                                    case .success(_):
                                        return
                                    case .failure(let error):
                                        print("error: \(error)")
                                    }
                                    // TODO: handle case where the is no organisation
                                }
                            }
                            .font(.title3)
                            .foregroundColor(Color("KentoBlueGrey"))
                            .padding()
                            .frame(minWidth: 0, maxWidth: 350)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                        }
                    } else {
                        // Organisation selection
                        if orgIds!.count > 1 {
                            ForEach(orgIds!, id: \.self) { orgId in
                                let index = orgIds!.firstIndex(of: orgId)
                                let orgName = orgNames![index!]
                                Button("\(orgName)"){
                                    orgIds = [orgId]
                                    orgNames = [orgName]
                                    // Fetch events
                                    eventInit(volunteerName: volunteerName, orgId: orgIds) { result in
                                        switch result {
                                        case .success(_):
                                            return
                                        case .failure(let error):
                                            print("error: \(error)")
                                        }
                                        // TODO: handle case where the is no events
                                    }
                                }
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                            }
                                
                        } else {
                            Text("Selected organisation: \(orgNames![0])")
                                .font(.title3)
                                .foregroundColor(Color("KentoRed"))
                        }

                    }
                
                    // Event selection
                    if events != nil {
                        if events!.count > 1 {
                            ForEach(events!, id: \.id) { event in
                                Button("\(event.name)"){
                                    events = [event]
                                    // Fetch scan locations
                                    eventInit(volunteerName: volunteerName, orgId: orgIds, eventId: event.id) { result in
                                        switch result {
                                        case .success(_):
                                            return
                                        case .failure(let error):
                                            print("error: \(error)")
                                        }
                                    }
                                }
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                            }
                        } else {
                            Text("Selected event: \(events![0].name)")
                                .font(.title3)
                                .foregroundColor(Color("KentoRed"))
                            if events![0].mainPicture != nil {
                                let imageURLString = "https://\(events![0].mainPicture!.deletingPrefix("//"))"
                                AsyncImage(url: URL(string: imageURLString)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)

                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 200, height: 200)
                            }
                        }
                    }
                    
                    // Scan location selection
                    if scanLocations != nil && !volunteerName.isEmpty {
                        ForEach(scanLocations!, id: \.id) { scanLocation in
                            
                            Button("\(scanLocation.name)"){
                                eventInit(volunteerName: volunteerName, orgId: orgIds, eventId: events![0].id, scanLocationId: scanLocation.id) { result in
                                    switch result {
                                    case .success(_):
                                        return
                                    case .failure(let error):
                                        print("Error: \(error)")
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
                .navigationTitle(Text("Select \(title)"))
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
            
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .environmentObject(scanTerminal)
        .accentColor(Color("KentoRed"))
        
    }
    
    func eventInit(volunteerName: String, orgId: [String]?=nil, eventId:String?=nil, scanLocationId: String?=nil, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }
        
        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/kentoEventInit"
        var parameters = [
          [
            "key": "volunteerName",
            "value": "\(volunteerName)",
            "type": "text"
          ]] as [[String : Any]]
        if orgId != nil {
            parameters.append([
                "key": "orgId",
                "value": "\(orgId![0])",
                "type": "text"
              ])
        }
        if eventId != nil {
            parameters.append([
                "key": "eventId",
                "value": "\(eventId!)",
                "type": "text"
              ])
        }
        if scanLocationId != nil {
            parameters.append([
                "key": "scanLocationId",
                "value": "\(scanLocationId!)",
                "type": "text"
              ])
        }
        let request = multipartRequest(urlString: urlString, parameters: parameters, token: loginInfo.token)
        print("token", loginInfo.token)
        print("parameters", parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    // Debug
                    let dataString = String(data: data!, encoding: .utf8),
                    let eventInitResult = try? JSONDecoder().decode(EventInitResult.self, from: data!)
                else {
                    print(response.debugDescription)
                    let dataString = String(data: data!, encoding: .utf8)
                    print(dataString)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }
                DispatchQueue.main.async {
                    // Debug
                    print("\(dataString)")
                    if eventInitResult.response.orgIds != nil && eventInitResult.response.orgIds!.count > 0 {
                        title = "organisation"
                        orgIds = eventInitResult.response.orgIds
                    }
                    if eventInitResult.response.orgNames != nil && eventInitResult.response.orgNames!.count > 0 {
                        orgNames = eventInitResult.response.orgNames
                    }
                    if eventInitResult.response.events != nil && eventInitResult.response.events!.count > 0 {
                        title = "event"
                        events = eventInitResult.response.events
                    }
                    if eventInitResult.response.scanLocations != nil && eventInitResult.response.scanLocations!.count > 0 {
                        title = "location"
                        scanLocations = eventInitResult.response.scanLocations
                    }
                    if eventInitResult.response.badges != nil {
                        badges = eventInitResult.response.badges
                    }
                    if eventInitResult.response.scanTerminal != nil {
                        scanTerminal.id = eventInitResult.response.scanTerminal!.id
                        scanTerminal.volunteerName = eventInitResult.response.scanTerminal!.volunteerName
                        isShowingQRScanView = true
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

struct EventInitView_Previews: PreviewProvider {
    static var previews: some View {
        EventInitView()
    }
}
