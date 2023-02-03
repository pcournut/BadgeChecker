//
//  QRScanself.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 11/12/2022.
//

import Foundation
import CodeScanner


class QRScanViewModel: ObservableObject {
    
    // Environment variables
    @Published var token: String = ""
    @Published var scanTerminal: String = ""
    @Published var badges: [Badge] = []
    
    // Local scan variables
    @Published var badgesCount = 0
    @Published var validatedBadgesCount = 0
    @Published var participantAllBadgesList: [ParticipantAllBadges] = []
    
    // Search variables
    @Published var searchText: String = ""
    @Published var filteredParticipantAllBadgesList: [ParticipantAllBadges] = []
    
    // Scanned variables
    @Published var scannedFirstName: String = ""
    @Published var scannedLastName: String = ""
    @Published var scannedEmail: String = ""
    @Published var scannedBadgeName: String = ""
    @Published var scannedParticipantAndBadges: ParticipantAllBadges?
    @Published var selectedBadgeEntitiesIds: [String] = []
    
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
    @Published var isPresentingScanner = true
    // TODO: remove at release?
    @Published var isPresentingPhotoGallery = false
    @Published var isPresentingList = false
    @Published var isPresentingResultStack = false
    
    func setupScanningVariables(token: String, scanTerminal: String, badges: [Badge], enrichedBadgeEntities: [EnrichedBadgeEntity]) {
        // Retrieve environment variables
        self.token = token
        self.scanTerminal = scanTerminal
        self.badges = badges
        self.lastQueryUnixTimeStamp = NSDate().timeIntervalSince1970 * 1000

        // Rearrange list of participants and badges
        badgesCount = enrichedBadgeEntities.count
        self.participantAllBadgesList = []
        for enrichedBadgeEntity in enrichedBadgeEntities {
            if enrichedBadgeEntity.isUsed {
                validatedBadgesCount += 1
            }
            
            if self.participantAllBadgesList.filter({ $0.userId == enrichedBadgeEntity.userId }).count > 0 {
                if let row = self.participantAllBadgesList.firstIndex(where: {$0.userId == enrichedBadgeEntity.userId}) {
                    self.participantAllBadgesList[row].badges.append(BadgeInfo(
                        badgeEntityId: enrichedBadgeEntity.badgeEntityId,
                        badgeId: enrichedBadgeEntity.badgeId,
                        isUsed: enrichedBadgeEntity.isUsed))
                }
            } else {
                self.participantAllBadgesList.append(ParticipantAllBadges(
                    userId: enrichedBadgeEntity.userId,
                    firstName: enrichedBadgeEntity.firstName,
                    lastName: enrichedBadgeEntity.lastName,
                    email: enrichedBadgeEntity.email,
                    badges: [BadgeInfo(
                        badgeEntityId: enrichedBadgeEntity.badgeEntityId,
                        badgeId: enrichedBadgeEntity.badgeId,
                        isUsed: enrichedBadgeEntity.isUsed)]
                    )
                )
            }
        }
        self.filteredParticipantAllBadgesList = self.participantAllBadgesList
    }
    
    func resetScannedAndInfographyVariables() {
        self.scannedFirstName = ""
        self.scannedLastName = ""
        self.scannedEmail = ""
        self.scannedBadgeName = ""
        self.notFoundKento = false
        self.alreadyValidatedKento = false
        self.validatedKento = false
        self.scanFailed = false
        self.scannedParticipantAndBadges = nil
        self.selectedBadgeEntitiesIds = []
    }
    
    func dismissResultStack() {
        resetScannedAndInfographyVariables()
        self.isPresentingResultStack = false
    }
    
    func setupScanView() {
        resetScannedAndInfographyVariables()
        self.isPresentingScanner = true
        self.isPresentingList = false
    }
    
    func setupListView() {
        resetScannedAndInfographyVariables()
        self.isPresentingScanner = false
        self.isPresentingList = true
        self.searchText = ""
        self.filteredParticipantAllBadgesList = self.participantAllBadgesList
    }
    
    func standardizeString(str: String) -> String {
        return str.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }
    
    func updateFilteredParticipantAllBadgesList() {
        if self.searchText.count > 0 {
            self.filteredParticipantAllBadgesList = self.participantAllBadgesList.filter { standardizeString(str: $0.firstName).contains(standardizeString(str: self.searchText)) || standardizeString(str: $0.lastName).contains(standardizeString(str: self.searchText)) || standardizeString(str: $0.email).contains(standardizeString(str: self.searchText)) }
        } else {
            self.filteredParticipantAllBadgesList = self.participantAllBadgesList
        }
        
        validatedBadgesCount = 0
        for participantAllBadge in participantAllBadgesList {
            for badge in participantAllBadge.badges {
                if badge.isUsed {
                    validatedBadgesCount += 1
                }
            }
        }
    }
    
    func selectParticipant(participant: inout ParticipantAllBadges) {
        self.isPresentingResultStack = true
        self.scannedFirstName = participant.firstName
        self.scannedLastName = participant.lastName
        self.scannedEmail = participant.email
        self.scannedParticipantAndBadges = ParticipantAllBadges(
            userId: participant.userId,
            firstName: participant.firstName,
            lastName: participant.lastName,
            email: participant.email,
            badges: participant.badges
        )
        if participant.badges.filter( {!$0.isUsed} ).count == 1 {
            if let badgeRow = participant.badges.firstIndex(where: {!$0.isUsed}) {
                self.selectedBadgeEntitiesIds.append(participant.badges[badgeRow].badgeEntityId)
            }
        }
    }
    
    func validateSelection() {
        for badgeEntityId in self.selectedBadgeEntitiesIds {
            if let participantRow = self.participantAllBadgesList.firstIndex(where: {$0.userId == self.scannedParticipantAndBadges!.userId}) {
                if let badgeRow = self.participantAllBadgesList[participantRow].badges.firstIndex(where: {$0.badgeEntityId == badgeEntityId}) {
                    self.participantAllBadgesList[participantRow].badges[badgeRow].isUsed = true
                    self.changedBadgeEntities.append(self.participantAllBadgesList[participantRow].badges[badgeRow].badgeEntityId)
                }
            }
        }
        self.validatedBadgesCount += self.selectedBadgeEntitiesIds.count
        self.isPresentingResultStack = false
        self.validatedKento = false
        self.scannedParticipantAndBadges = nil
        self.updateFilteredParticipantAllBadgesList()
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        
        switch result {
        case .success(let result):
            var scannedParticipantAllBadges = self.participantAllBadgesList.filter { $0.userId == result.string }
            
            if scannedParticipantAllBadges.count == 1 {
                selectParticipant(participant: &scannedParticipantAllBadges[0])
            } else {
                self.notFoundKento = true
                self.isPresentingResultStack = true
            }

        case .failure(let error):
            self.scanFailed = true
            self.isPresentingResultStack = true
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
                    print("dataString: \(dataString)")
                    for badgeEntity in participantListUpdateResult.response.participantsUpdate {
                        let badgeEntityDict = convertStringToDictionary(text: badgeEntity)
                        let enrichedBadgeEntity = EnrichedBadgeEntity(
                            userId: badgeEntityDict!["userId"] as! String,
                            firstName: badgeEntityDict!["firstName"] as! String,
                            lastName: badgeEntityDict!["lastName"] as! String,
                            email: badgeEntityDict!["email"] as! String,
                            badgeEntityId: badgeEntityDict!["badgeEntityId"] as! String,
                            badgeId: badgeEntityDict!["badgeId"] as! String,
                            isUsed: badgeEntityDict!["isUsed"] as! String == "oui")
                        if enrichedBadgeEntity.isUsed {
                            if let participantRow = self.participantAllBadgesList.firstIndex(where: {$0.userId == enrichedBadgeEntity.userId}) {
                                if let badgeRow = self.participantAllBadgesList[participantRow].badges.firstIndex(where: { $0.badgeEntityId == enrichedBadgeEntity.badgeEntityId}) {
                                    if !self.participantAllBadgesList[participantRow].badges[badgeRow].isUsed {
                                        self.participantAllBadgesList[participantRow].badges[badgeRow].isUsed = true
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
