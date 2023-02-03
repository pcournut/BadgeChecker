//
//  EventInitViewModel.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 11/12/2022.
//

import Foundation


class EventInitViewModel: ObservableObject {
    
    @Published var token = ""
    
    // Selection variables
    @Published var orgs: [Organisation]?
    @Published var events: [Event]?
    @Published var badges: [Badge]?
    @Published var scanTerminal: String?
    @Published var enrichedBadgeEntities: [EnrichedBadgeEntity] = []
    
    // Selected variables
    @Published var selectedOrg: Organisation?
    @Published var selectedEvent: Event?
    @Published var selectedBadges: [Badge] = []
    @Published var selectedBadgesIds: [String] = []
    @Published var selectedBadgesCount: Int = 0
    
    // View state variables
    @Published var mainViewOpacity = 1.0
    @Published var isShowingQRScanView = false
    @Published var isShowingWaitingView = false
    
    let varDownloader = FileDownloader()
    
    func setupTokenFetchOrgs(token: String) {
        self.token = token
        self.mainViewOpacity = 0.5
        self.isShowingWaitingView = true
        eventInit() { result in
            switch result {
            case .success(_):
                self.mainViewOpacity = 1.0
                self.isShowingWaitingView = false
                return
            case .failure(let error):
                self.mainViewOpacity = 1.0
                self.isShowingWaitingView = false
                print("error: \(error)")
            }
        }
    }
    
    func downloadIcon(iconURLString: String) -> String? {
        var iconURLString: String? = "https:\(iconURLString)"
        if NSString(string: iconURLString!).pathExtension == "svg" {
            let iconURL = URL(string: iconURLString!)!
            FileDownloader.loadFileAsync(url: iconURL) { (path, error) in
                print("\(iconURLString): \(path)")
                iconURLString = path
            }
        }
        return iconURLString
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
        print("KentoEventInit request: \(parameters)")

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
                        self.orgs = eventInitResult.response.orgs
                        if eventInitResult.response.orgs!.count == 1 {
                            self.selectedOrg = eventInitResult.response.orgs![0]
                        }
                        
                        // Handle icon
                        for orgIdx in self.orgs!.indices {
                            if self.orgs![orgIdx].iconURL != nil {
                                self.orgs![orgIdx].iconPath = self.downloadIcon(iconURLString: self.orgs![orgIdx].iconURL!)
                            }
                        }
                    }
                    if eventInitResult.response.events != nil {
                        self.events = eventInitResult.response.events
                        if eventInitResult.response.events!.count == 1 {
                            self.selectedEvent = eventInitResult.response.events![0]
                        }
                        
                        // Handle icon
                        for eventIdx in self.events!.indices {
                            if self.events![eventIdx].iconURL != nil {
                                self.events![eventIdx].iconPath = self.downloadIcon(iconURLString: self.events![eventIdx].iconURL!)
                            }
                        }
                    }
                    if eventInitResult.response.badges != nil {
                        self.badges = eventInitResult.response.badges!
                        
                        // Handle icon
                        for badgeIdx in self.badges!.indices {
                            if self.badges![badgeIdx].iconURL != nil {
                                self.badges![badgeIdx].iconPath = self.downloadIcon(iconURLString: self.badges![badgeIdx].iconURL!)
                            }
                        }
                    }
                    if eventInitResult.response.scanTerminal != nil {
                        self.scanTerminal = eventInitResult.response.scanTerminal!
                    }
                    completion(.success(true))
                } // DispatchQueue.main.async
            } else {
                if let error = error {
                    completion(.failure(error))
                }
            }
        }.resume() // URLSession.shared.data
    }
    
    func selectedBadge(completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }
        
        // Construct request
        let n_requests = Int(ceil(Double(self.selectedBadgesCount) / Double(100)))
        var requests: [URLRequest] = []
        for cursor in 0..<n_requests {
            requests.append(getDataRequest(table: "BadgeEntity", key: "parent_badge", values: self.selectedBadgesIds, cursor: 100*cursor, token: token))
        }

        // Prepare parallel job
        self.enrichedBadgeEntities = []
        let urlFetchQueue = DispatchQueue(label: "com.urlFetcher.urlqueue")
        let urlFetchGroup = DispatchGroup()
        
        // Parallel requests
        let start = DispatchTime.now()
        requests.forEach { (request) in
            urlFetchGroup.enter()
            
            // Check BadgeEntity database
            URLSession.shared.dataTask(with: request) { [self] data, response, error in
                if error == nil {
                    // JSON parsing
                    guard
                        // Debug
                        let fetchBadgeEntitiesDataString = String(data: data!, encoding: .utf8),
                        let fetchBadgeEntitiesResult = try? JSONDecoder().decode(FetchBadgeEntitiesResult.self, from: data!)
                    else {
                        print("response", response.debugDescription)
                        urlFetchQueue.async {
                            urlFetchGroup.leave()
                        }
                        completion(.failure(JSONDecodingError.failed))
                        return
                    }
                    
                    if fetchBadgeEntitiesResult.response.results.count > 0 {
                        // Check User database
                        let request = getDataRequest(table: "User", key: "_id", values: fetchBadgeEntitiesResult.response.results.map( {$0.ownerId }), cursor: 0, token: token)
                        
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            if error == nil {
                                guard
                                    // Debug
                                    let fetchUserDataString = String(data: data!, encoding: .utf8),
                                    let fetchUsersResult = try? JSONDecoder().decode(FetchUsersResult.self, from: data!)
                                else {
                                    print("response", response.debugDescription)
                                    urlFetchQueue.async {
                                        urlFetchGroup.leave()
                                    }
                                    completion(.failure(JSONDecodingError.failed))
                                    return
                                }
                                
                                // Gather BadgeEntities and Users
                                urlFetchQueue.async {
                                    var user: User
                                    var enrichedBadgeEntities: [EnrichedBadgeEntity] = []
                                    for badgeEntity in fetchBadgeEntitiesResult.response.results {
                                        if let userIndex = fetchUsersResult.response.results.firstIndex(where: {$0.id == badgeEntity.ownerId}) {
                                            user = fetchUsersResult.response.results[userIndex]
                                            let enrichedBadgeEntity = EnrichedBadgeEntity(
                                                userId: badgeEntity.ownerId,
                                                firstName: user.firstName,
                                                lastName: user.lastName,
                                                email: user.authentication.email.email ?? "",
                                                badgeEntityId: badgeEntity.id,
                                                badgeId: badgeEntity.parentBadgeId,
                                                isUsed: badgeEntity.scanTerminal != nil)
                                            enrichedBadgeEntities.append(enrichedBadgeEntity)
                                        }
                                    }
                                    self.enrichedBadgeEntities += enrichedBadgeEntities
                                    print("EnrichedBadgeEntities: \(enrichedBadgeEntities)")
                                    urlFetchGroup.leave()
                                }
                            } else {
                                if let error = error {
                                    print("Error fetching users: \(error)")
                                    urlFetchQueue.async {
                                        urlFetchGroup.leave()
                                    }
                                    completion(.failure(error))
                                }
                            }
                        }.resume() // URLSession.shared.data
                        
                    } else { // fetchBadgeEntitiesResult.response.results.count == 0
                        urlFetchQueue.async {
                            urlFetchGroup.leave()
                        }
                    }
                    
                } else {
                    if let error = error {
                        print("Error fetching badge entities: \(error)")
                        urlFetchQueue.async {
                            urlFetchGroup.leave()
                        }
                        completion(.failure(error))
                    }
                }
            }.resume() // URLSession.shared.data
        }
        
        urlFetchGroup.notify(queue: DispatchQueue.global()) {
            DispatchQueue.main.async {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("Compute time: \(timeInterval)")
                completion(.success(true))
            }
        }
    }
}
