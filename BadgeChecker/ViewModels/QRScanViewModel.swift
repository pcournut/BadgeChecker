//
//  QRScanself.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 11/12/2022.
//

import Foundation
import CodeScanner

struct BadgeInfo: Codable {
    var badgeEntityId: String
    var badgeId: String
    var isUsed: Bool
}

struct ParticipantAllBadges: Codable {
    var userId: String
    var firstName: String
    var lastName: String
    var email: String
    var badges: [BadgeInfo]
}

struct ParticipantListUpdateResponse: Codable {
    var participantsUpdate: [String]
    var lastQueryUnixTimeStamp: Double
    
    private enum CodingKeys: String, CodingKey {
        case participantsUpdate
        case lastQueryUnixTimeStamp = "LastQueryUnixTimeStamp"
    }
}

struct ParticipantListUpdateResult: Codable {
    var status: String
    var response: ParticipantListUpdateResponse
}

class QRScanViewModel: ObservableObject {
    
    // Environment variables
    @Published var token: String = ""
    @Published var scanTerminal: String = ""
    @Published var badges: [Badge] = []
    
    // Scanning variables
    
    @Published var badgesCount = 0
    @Published var validatedBadgesCount = 0
    @Published var participantAllBadgesList: [ParticipantAllBadges] = []
    
    // Search variables
    @Published var filteredParticipantAllBadgesList: [ParticipantAllBadges] = []
    
    // Scan variables
    @Published var scannedFirstName: String = ""
    @Published var scannedLastName: String = ""
    @Published var scannedEmail: String = ""
    @Published var scannedBadgeName: String = ""
    @Published var scannedParticipantAndUnusedBadges: ParticipantAllBadges?
    @Published var selectedBadgeEntitiesIds: [String] = []
    
    // List search
    @Published var name: String = ""
    
    // Iconography variables
    @Published var notFoundKento = false
    @Published var alreadyValidatedKento = false
    @Published var validatedKento = false
    @Published var scanFailed = false
    
    // Server synchronisation variables
    @Published var timer = Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()
    @Published var changedBadgeEntities: [String] = []
    @Published var lastQueryUnixTimeStamp: Double = 0
    
    // View variables
    @Published var isPresentingScanner = false
    @Published var isPresentingList = false
    
    func setupScanningVariables(token: String, scanTerminal: String, badges: [Badge], participantBadgeList: [ParticipantScanInfo]) {
        // Retrieve environment variables
        self.token = token
        self.scanTerminal = scanTerminal
        self.badges = badges
        self.lastQueryUnixTimeStamp = NSDate().timeIntervalSince1970 * 1000

        // Rearrange list of participants and badges
        badgesCount = participantBadgeList.count
        self.participantAllBadgesList = []
        for participantBadge in participantBadgeList {
            if participantBadge.isUsed {
                validatedBadgesCount += 1
            }
            
            if self.participantAllBadgesList.filter({ $0.userId == participantBadge.userId }).count > 0 {
                if let row = self.participantAllBadgesList.firstIndex(where: {$0.userId == participantBadge.userId}) {
                    self.participantAllBadgesList[row].badges.append(BadgeInfo(
                        badgeEntityId: participantBadge.badgeEntityId,
                        badgeId: participantBadge.badgeId,
                        isUsed: participantBadge.isUsed))
                }
            } else {
                self.participantAllBadgesList.append(ParticipantAllBadges(
                    userId: participantBadge.userId,
                    firstName: participantBadge.firstName,
                    lastName: participantBadge.lastName,
                    email: participantBadge.email,
                    badges: [BadgeInfo(
                        badgeEntityId: participantBadge.badgeEntityId,
                        badgeId: participantBadge.badgeId,
                        isUsed: participantBadge.isUsed)]
                    )
                )
            }
        }
        self.filteredParticipantAllBadgesList = self.participantAllBadgesList
    }
    
    func setupScanView() {
        self.scannedFirstName = ""
        self.scannedLastName = ""
        self.scannedEmail = ""
        self.scannedBadgeName = ""
        self.scanFailed = false
        self.isPresentingScanner = true
        self.isPresentingList = false
        self.scannedParticipantAndUnusedBadges = nil
        self.validatedKento = false
        self.alreadyValidatedKento = false
        self.notFoundKento = false
    }
    
    func setupListView() {
        self.name = ""
        self.filteredParticipantAllBadgesList = self.participantAllBadgesList
        self.scannedFirstName = ""
        self.scannedLastName = ""
        self.scannedEmail = ""
        self.scannedBadgeName = ""
        self.scanFailed = false
        self.isPresentingScanner = false
        self.scannedParticipantAndUnusedBadges = nil
        self.validatedKento = false
        self.alreadyValidatedKento = false
        self.notFoundKento = false
        self.isPresentingList = true
    }
    
    func updateFilteredParticipantAllBadgesList() {
        if self.name.count > 0 {
            self.filteredParticipantAllBadgesList = self.participantAllBadgesList.filter { $0.firstName.contains(self.name) || $0.lastName.contains(self.name) }
        } else {
            self.filteredParticipantAllBadgesList = self.participantAllBadgesList
        }
    }
    
    func selectParticipant(participant: inout ParticipantAllBadges) {
        self.isPresentingList = false
        let scannedUnusedBadges = participant.badges.filter { !$0.isUsed }
        self.scannedFirstName = participant.firstName
        self.scannedLastName = participant.lastName
        self.scannedEmail = participant.email
        if scannedUnusedBadges.count == 0 {
            self.alreadyValidatedKento = true
        } else if scannedUnusedBadges.count == 1 {
            if let participantRow = self.participantAllBadgesList.firstIndex(where: {$0.userId == participant.userId}) {
                if let badgeRow = participant.badges.firstIndex(where: {!$0.isUsed}) {
                    // Participant in argument can be a filtered array but changed on isUsed must be done on true record
                    let badgeId = self.participantAllBadgesList[participantRow].badges[badgeRow].badgeId
                    if let badgeRow = self.badges.firstIndex(where: {$0.id == badgeId}) {
                        self.scannedBadgeName = self.badges[badgeRow].name
                    }
                    self.participantAllBadgesList[participantRow].badges[badgeRow].isUsed = true
                    self.changedBadgeEntities.append(participantAllBadgesList[participantRow].badges[badgeRow].badgeEntityId)
                    self.changedBadgeEntities.append(participant.badges[badgeRow].badgeEntityId)
                }
            }
            self.validatedBadgesCount += 1
            self.validatedKento = true
        } else {
            self.scannedParticipantAndUnusedBadges = ParticipantAllBadges(
                userId: participant.userId,
                firstName: participant.firstName,
                lastName: participant.lastName,
                email: participant.email,
                badges: scannedUnusedBadges
            )
        }
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        self.isPresentingScanner = false
        
        switch result {
        case .success(let result):
            var scannedParticipantAllBadges = self.participantAllBadgesList.filter { $0.userId == result.string }
            
            if scannedParticipantAllBadges.count == 1 {
                selectParticipant(participant: &scannedParticipantAllBadges[0])
            } else {
                self.notFoundKento = true
            }

        case .failure(let error):
            self.scanFailed = true
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    func participantListUpdate(changedBadgeEntities: [String], scanTerminal: String, badges: [String], lastQueryUnixTimeStamp: TimeInterval, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }

        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/ParticipantListUpdate"
        let parameters = [
          [
            "key": "ChangedBadgeEntities",
            "value": "\(changedBadgeEntities)",
            "type": "text"
          ],
          [
            "key": "ScanTerminal",
            "value": "\(scanTerminal)",
            "type": "text"
          ],
          [
            "key": "Badges",
            "value": "\(badges)",
            "type": "text"
          ],
          [
            "key": "LastQueryUnixTimeStamp",
            "value": "\(lastQueryUnixTimeStamp)",
            "type": "text"
          ]] as [[String : Any]]
        let request = multipartRequest(urlString: urlString, parameters: parameters, token: token)
        print("Parameters: \(parameters)")
            
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    // Debug
                    let dataString = String(data: data!, encoding: .utf8),
                    let participantListUpdateResult = try? JSONDecoder().decode(ParticipantListUpdateResult.self, from: data!)
                else {
                    print("response", response.debugDescription)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }

                DispatchQueue.main.async {
                    // Debug
                    print("\(dataString)")
                    for participant in participantListUpdateResult.response.participantsUpdate {
                        let participantDict = convertStringToDictionary(text: participant)
                        let participantScanInfo = ParticipantScanInfo(
                            userId: participantDict!["userId"] as! String,
                            firstName: participantDict!["firstName"] as! String,
                            lastName: participantDict!["lastName"] as! String,
                            email: participantDict!["email"] as! String,
                            badgeEntityId: participantDict!["badgeEntityId"] as! String,
                            badgeId: participantDict!["badgeId"] as! String,
                            isUsed: participantDict!["isUsed"] as! String == "oui")
                        if participantScanInfo.isUsed {
                            if let participantRow = self.participantAllBadgesList.firstIndex(where: {$0.userId == participantScanInfo.userId}) {
                                if let badgeRow = self.participantAllBadgesList[participantRow].badges.firstIndex(where: { $0.badgeEntityId == participantScanInfo.badgeEntityId}) {
                                    if !self.participantAllBadgesList[participantRow].badges[badgeRow].isUsed {
                                        self.participantAllBadgesList[participantRow].badges[badgeRow].isUsed = true
                                        self.validatedBadgesCount += 1
                                    }
                                }
                            }
                        }
                    }
                    self.updateFilteredParticipantAllBadgesList()
                    self.lastQueryUnixTimeStamp = participantListUpdateResult.response.lastQueryUnixTimeStamp + 0.001
                    self.changedBadgeEntities = []
                    
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
