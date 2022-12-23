//
//  QRScanViewModel.swift
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
    var badges: [BadgeInfo]
}

class QRScanViewModel: ObservableObject {
    
    @Published var token: String = ""
    
    // Offline scanning variables
    @Published var badgesCount = 0
    @Published var validatedBadgesCount = 0
    @Published var participantAllBadgesList: [ParticipantAllBadges] = []
    
    // Scan variables
    @Published var scannedFirstName: String = ""
    @Published var scannedLastName: String = ""
    @Published var scannedParticipantAndUnusedBadges: ParticipantAllBadges?
    @Published var scannedParticipantBadgeList: [ParticipantScanInfo] = []
    @Published var selectedBadgeEntitiesIds: [String] = []
    
    // List search
    @Published var name: String = ""
    
    // Iconography variables
    @Published var notFoundKento = false
    @Published var alreadyValidatedKento = false
    @Published var validatedKento = false
    @Published var scanFailed = false
    
    // View variables
    @Published var isPresentingScanner = false
    @Published var isPresentingList = false
    
    func setupView(token: String, participantBadgeList: [ParticipantScanInfo]) {
        self.token = token
        badgesCount = participantBadgeList.count
        self.participantAllBadgesList = []
        
        for participantBadge in participantBadgeList {
            if participantBadge.isUsed {
                validatedBadgesCount += 1
            }
            
            if self.participantAllBadgesList.filter { $0.userId == participantBadge.userId }.count > 0 {
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
                    badges: [BadgeInfo(
                        badgeEntityId: participantBadge.badgeEntityId,
                        badgeId: participantBadge.badgeId,
                        isUsed: participantBadge.isUsed)]
                    )
                )
            }
        }
    }
}
