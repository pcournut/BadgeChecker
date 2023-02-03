//
//  DataStructures.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 12/01/2023.
//

import Foundation


// Environment variables
class LoginInfo: ObservableObject {
    @Published var userFirstName: String = UserDefaults.standard.string(forKey: "userFirstName") ?? ""
    @Published var token: String = UserDefaults.standard.string(forKey: "token") ?? ""
    @Published var user_id: String = UserDefaults.standard.string(forKey: "user_id") ?? ""
    @Published var expires: Date = UserDefaults.standard.object(forKey: "expires") as? Date ?? Date.now
}

class ScanInfo: ObservableObject {
    @Published var scanTerminal: String?
    @Published var badges: [Badge]?
    @Published var enrichedBadgeEntities: [EnrichedBadgeEntity]?
}

// Data
struct Badge: Equatable, Codable, Hashable {
    var id: String
    var name: String
    var iconURL: String?
    var iconPath: String?
    var maxSupply: Int
    
    static func ==(lhs: Badge, rhs: Badge) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name = "name"
        case iconURL = "icon"
        case iconPath
        case maxSupply = "max_supply"
    }
}

struct BadgeEntity: Codable {
    var id: String
    var parentBadgeId: String
    var ownerId: String
    var scanTerminal: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case parentBadgeId = "parent_badge"
        case ownerId = "owner"
        case scanTerminal = "scan_information"
    }
}

struct EnrichedBadgeEntity: Codable {
    var userId: String
    var firstName: String
    var lastName: String
    var email: String
    var badgeEntityId: String
    var badgeId: String
    var isUsed: Bool
}

struct BadgeInfo: Codable {
    var badgeEntityId: String
    var badgeId: String
    var isUsed: Bool
}

struct Event : Codable, Hashable {
    var id: String
    var name: String
    var iconURL: String?
    var iconPath: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case iconURL = "main_picture"
        case name
        case iconPath
    }
}

struct Organisation : Codable, Hashable {
    var id: String
    var name: String
    var iconURL: String?
    var iconPath: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case iconURL = "logo"
        case iconPath
        case name
    }
}

struct ParticipantAllBadges: Codable {
    var userId: String
    var firstName: String
    var lastName: String
    var email: String
    var badges: [BadgeInfo]
}

struct Email: Codable {
    var email: String?
}

struct Authentification: Codable {
    var email: Email
}

struct User: Codable {
    var id: String
    var firstName: String
    var lastName: String
    var authentication: Authentification
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case authentication
    }
}

// API responses
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

struct NotTwilioResult: Codable {
    var status: String?
    var statusCode: String?
    var response: VerifyResponse?
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

struct SelectedBadgeResponse: Codable {
    var participants: [String]
}

struct SelectedBadgeResult: Codable {
    var status: String
    var response: SelectedBadgeResponse
}


struct SendResult: Codable {
    var status: String?
    var statusCode: String?
}

struct VerifyResponse: Codable {
    var userFirstName: String
    var token: String
    var user_id: String
    var expires: Int
}

struct VerifyResult: Codable {
    var status: String?
    var statusCode: String?
    var response: VerifyResponse?
}

struct FetchBadgeEntitiesResponse: Codable {
    var results: [BadgeEntity]
}

struct FetchBadgeEntitiesResult: Codable {
    var response: FetchBadgeEntitiesResponse
}



struct FetchUsersResponse: Codable {
    var results: [User]
}

struct FetchUsersResult: Codable {
    var response: FetchUsersResponse
}
