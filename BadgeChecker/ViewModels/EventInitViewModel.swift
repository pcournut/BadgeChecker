//
//  EventInitViewModel.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 11/12/2022.
//

import Foundation

struct ParticipantScanInfo: Codable {
    var userId: String
    var firstName: String
    var lastName: String
    var badgeEntityId: String
    var badgeId: String
    var isUsed: Bool
}

class ScanInfo: ObservableObject {
    @Published var scanTerminal: String?
    @Published var badges: [Badge]?
    @Published var participantsAndBadges: [ParticipantScanInfo]?
}

struct Badge: Equatable, Codable {
    var id: String
    var name: String
    
    static func ==(lhs: Badge, rhs: Badge) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name
      }
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name = "Name"
    }
}

struct Event : Codable {
    var id: String
    var name: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }
}

struct Organisation : Codable {
    var id: String
    var name: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }
}

struct EventInitResponse: Codable {
    var orgs: [Organisation]?
    var events: [Event]?
    var badges: [Badge]?
    var scanTerminal: String?
}

struct EventInitResult: Codable {
    var status: String
    var response: EventInitResponse
}

struct Participants: Codable {
    var id: String
    var firstName: String
    var lastName: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
    }
}

struct BadgeEntity: Codable {
    var id: String
    var parentBadgeId: String
    var scanTerminal: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case parentBadgeId = "ParentBadge"
        case scanTerminal
    }
}

struct SelectedBadgeResponse: Codable {
    var participants: [String]
    
}

struct SelectedBadgeResult: Codable {
    var status: String
    var response: SelectedBadgeResponse
}


func convertStringToDictionary(text: String) -> [String:AnyObject]? {
   if let data = text.data(using: .utf8) {
       do {
           let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
           return json
       } catch {
           print("Something went wrong")
       }
   }
   return nil
}

class EventInitViewModel: ObservableObject {
    
    @Published var title = "organisation"
    @Published var token = ""
    
    // Selection variables
    @Published var orgs: [Organisation]?
    @Published var events: [Event]?
    @Published var badges: [Badge]?
    @Published var scanTerminal: String?
    @Published var participantsAndBadges: [ParticipantScanInfo] = []
    
    // Selected variables
    @Published var selectedOrg: Organisation?
    @Published var selectedEvent: Event?
    @Published var selectedBadges: [Badge] = []
    @Published var selectedBadgesIds: [String] = []
    
    // View state variables
    @Published var isShowingQRScanView = false
    
    func setupTokenFetchOrgs(token: String) {
        self.token = token
        eventInit() { result in
            switch result {
            case .success(_):
                
                return
            case .failure(let error):
                print("error: \(error)")
            }
        }
    }
    
    func eventInit(orgId: String?=nil, eventId:String?=nil, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }
    
        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/KentoEventInit"
        var parameters = [] as [[String : Any]]
        if orgId != nil {
            parameters.append([
                "key": "orgId",
                "value": "\(orgId!)",
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
        let request = multipartRequest(urlString: urlString, parameters: parameters, token: token)

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
                    if eventInitResult.response.orgs != nil {
                        if eventInitResult.response.orgs!.count == 1 {
                            self.title = "event"
                            self.selectedOrg = eventInitResult.response.orgs![0]
                        } else {
                            self.title = "organisation"
                            self.orgs = eventInitResult.response.orgs
                        }
                    }
                    if eventInitResult.response.events != nil {
                        if eventInitResult.response.events!.count == 1 {
                            self.title = "badges"
                            self.selectedEvent = eventInitResult.response.events![0]
                        } else {
                            self.title = "event"
                            self.events = eventInitResult.response.events
                        }
                    }
                    if eventInitResult.response.badges != nil {
                        if eventInitResult.response.badges!.count == 1 {
                            self.selectedBadges = [eventInitResult.response.badges![0]]
                        } else {
                            self.title = "badges"
                            self.badges = eventInitResult.response.badges
                        }
                    }
                    if eventInitResult.response.scanTerminal != nil {
                        self.scanTerminal = eventInitResult.response.scanTerminal!
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
    
    func selectedBadge(badgeIds: [String]?, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }

        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/SelectedBadge"
        var parameters = [] as [[String : Any]]
        if badgeIds != nil {
            parameters.append([
                "key": "Badges",
                "value": "\(badgeIds!)",
                "type": "text"
              ])
        }
        let request = multipartRequest(urlString: urlString, parameters: parameters, token: token)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    // Debug
                    let dataString = String(data: data!, encoding: .utf8),
                    let selectedBadgeResult = try? JSONDecoder().decode(SelectedBadgeResult.self, from: data!)
                else {
                    print("response", response.debugDescription)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }

                DispatchQueue.main.async {
                    // Debug
                    print("\(dataString)")
                    self.participantsAndBadges = []
                    for participant in selectedBadgeResult.response.participants {
                        let participantDict = convertStringToDictionary(text: participant)
                        let participantScanInfo = ParticipantScanInfo(
                            userId: participantDict!["userId"] as! String,
                            firstName: participantDict!["firstName"] as! String,
                            lastName: participantDict!["lastName"] as! String,
                            badgeEntityId: participantDict!["badgeEntityId"] as! String,
                            badgeId: participantDict!["badgeId"] as! String,
                            isUsed: participantDict!["isUsed"] as! String == "oui")
                        self.participantsAndBadges.append(participantScanInfo)
                    }
                    completion(.success(true))
                }
            } else {
                if let error = error {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

}

