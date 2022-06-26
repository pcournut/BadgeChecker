//
//  MockServer.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 19/04/2022.
//

import Foundation

let PrivateKey = "1db3cd70ef43142b00672c7b02d0cde5"

class MockBubbleDataAPI {
    
    func endpoint(obj: String, typename: String) -> String {
        return "https://club-soda-2.bubbleapps.io/version-test/api/1.1/\(obj)/\(typename)"
    }
    
    func connect(email: String, password: String) -> Bool {
        var isLogged = true
        // this might be where token generation occurs, if so return would include it
        return isLogged
    }
    
    func checkPermission() {
        return Void()
    }
    
}

class MockBubbleWorkflowAPI {
    
    func endpoint(workflowName: String) -> String {
        return "https://club-soda-2.bubbleapps.io/version-test/api/1.1/wf/\(workflowName)"
    }
    
    func connect
    
}
