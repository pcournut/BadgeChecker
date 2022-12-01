//
//  EventInitView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import Foundation

class ScanInfo: ObservableObject {
    @Published var scanTerminal: ScanTerminal?
    @Published var badges: [Badge]?
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
    var icon: String
    
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case icon = "Icon"
    }
}

struct ScanTerminal: Codable {
    var id: String
    var volunteerName: String
    var scanLocationId: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case volunteerName = "VolunteerName"
        case scanLocationId = "ScanLocation"
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
    @State var title = "volunteer"
    @State var volunteerName = ""
    @State var orgIds: [String]?
    @State var orgNames: [String]?
    @State var orgs: [Organisation]?
    @State var events: [Event]?
    @State var scanLocations: [ScanLocation]?
    
    @State var showVolunteerField = true
    
    @State private var isShowingQRScanView = false

    @StateObject var scanInfo = ScanInfo()
    
    var body : some View {
        
        NavigationView {
            ZStack {
                VStack {
                    NavigationLink(destination: QRScanView(), isActive: $isShowingQRScanView) {
                        EmptyView()
                    }
                    
                    // Selected fields stack
                    VStack {
                        if !showVolunteerField {
                            HStack {
                                VStack{
                                    Text("Volunteer: ")
                                    .font(.title3)
                                    .foregroundColor(Color("KentoRedFont"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(volunteerName)")
                                        .font(.title3)
                                        .foregroundColor(Color("KentoBlueGrey"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Image(systemName: "xmark")
                                    .foregroundColor(Color("KentoRedFont"))
                                    .font(.system(size: 20))
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .onTapGesture {
                                        title = "volunteer"
                                        volunteerName = ""
                                        showVolunteerField = true
                                        orgIds = nil
                                        orgNames = nil
                                        events = nil
                                        scanLocations = nil
                                    }
                            
                            }
                            .frame(maxWidth: 350)
                        }
                        
                        if orgIds != nil {
                            if orgIds!.count == 1 {
                                HStack {
                                    VStack{
                                        Text("Organisation: ")
                                        .font(.title3)
                                        .foregroundColor(Color("KentoRedFont"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text("\(orgNames![0])")
                                            .font(.title3)
                                            .foregroundColor(Color("KentoBlueGrey"))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    Image(systemName: "xmark")
                                        .foregroundColor(Color("KentoRedFont"))
                                        .font(.system(size: 20))
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .onTapGesture {
                                            title = "organisation"
                                            orgIds = nil
                                            orgNames = nil
                                            events = nil
                                            scanLocations = nil
                                        }
                                
                                }
                                .frame(maxWidth: 350)
                            } else if orgIds!.count == 0 {
                                HStack{
                                    Text("No organisation found.")
                                    .font(.title3)
                                    .foregroundColor(Color("KentoRedFont"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(width: 350)
                            }
                        }
                        
                        if events != nil {
                            if events!.count == 1 {
                                HStack {
                                    VStack {
                                        Text("Event: ")
                                            .font(.title3)
                                            .foregroundColor(Color("KentoRedFont"))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("\(events![0].name)")
                                            .font(.title3)
                                            .foregroundColor(Color("KentoBlueGrey"))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    Image(systemName: "xmark")
                                        .foregroundColor(Color("KentoRedFont"))
                                        .font(.system(size: 20))
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .onTapGesture {
                                            title = "event"
                                            events = nil
                                            scanLocations = nil
                                            eventInit(volunteerName: volunteerName, orgId: orgIds) { result in
                                                switch result {
                                                case .success(_):
                                                    return
                                                case .failure(let error):
                                                    print("error: \(error)")
                                                }
                                            }
                                        }
                                }
                                .frame(maxWidth: 350)
                            } else if events!.count == 0 {
                                HStack{
                                    Text("No event found.")
                                    .font(.title3)
                                    .foregroundColor(Color("KentoRedFont"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(width: 350)
                            }
                        }
                        
                        if scanLocations != nil && scanLocations!.count == 0 {
                            HStack{
                                Text("No scan location found.")
                                .font(.title3)
                                .foregroundColor(Color("KentoRedFont"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(width: 350)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    
                    VStack {
                        if showVolunteerField {
                            TextField("Volunteer name", text: $volunteerName)
                                .disableAutocorrection(true)
                                .foregroundColor(Color("KentoBeige"))
                                .multilineTextAlignment(.center)
                                .frame(width: 350, height: 40)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                                .padding()
                        }
                        
                        // Fetch orgnisations
                        if orgIds == nil  {
                            if events == nil && scanLocations == nil && !volunteerName.isEmpty {
                                Button("Fetch organisations") {
                                    eventInit(volunteerName: volunteerName) { result in
                                        switch result {
                                        case .success(_):
                                            showVolunteerField = false
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
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    
                }
                .navigationTitle(Text("Select \(title)"))
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
            
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .environmentObject(scanInfo)
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
                    _ = String(data: data!, encoding: .utf8)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }
                DispatchQueue.main.async {
                    // Debug
                    print("\(dataString)")
                    if eventInitResult.response.orgIds != nil {
                        title = "organisation"
                        orgIds = eventInitResult.response.orgIds
                    }
                    if eventInitResult.response.orgNames != nil {
                        orgNames = eventInitResult.response.orgNames
                    }
                    if eventInitResult.response.events != nil {
                        title = "event"
                        events = eventInitResult.response.events
                    }
                    if eventInitResult.response.scanLocations != nil {
                        title = "location"
                        scanLocations = eventInitResult.response.scanLocations
                    }
                    if eventInitResult.response.badges != nil {
                        scanInfo.badges = eventInitResult.response.badges
                    }
                    if eventInitResult.response.scanTerminal != nil {
                        scanInfo.scanTerminal = eventInitResult.response.scanTerminal!
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
