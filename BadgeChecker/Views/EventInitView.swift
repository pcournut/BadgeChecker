//
//  EventInitView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import Foundation


struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
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

struct EventInitView: View {
    
    // Environment variables
    @EnvironmentObject var loginInfo: LoginInfo
    @StateObject var scanInfo = ScanInfo()
    
    // View model
    @ObservedObject var viewModel = EventInitViewModel()
    
    var body : some View {
        
        NavigationView {
            ZStack {
                VStack {
                    NavigationLink(destination: QRScanView(), isActive: $viewModel.isShowingQRScanView) {
                        EmptyView()
                    }
                    
                    // Selected variables stack
                    VStack {
                        if viewModel.selectedOrg != nil {
                            HStack {
                                VStack{
                                    Text("Organisation: ")
                                        .font(.title3)
                                        .foregroundColor(Color("KentoRedFont"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(viewModel.selectedOrg!.name)")
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
                                        viewModel.title = "organisation"
                                        viewModel.selectedOrg = nil
                                        viewModel.selectedEvent = nil
                                        viewModel.selectedBadges = []
                                        viewModel.selectedBadgesIds = []
                                        viewModel.orgs = nil
                                        viewModel.events = nil
                                        viewModel.badges = nil
                                    }
                                
                            }
                            .frame(maxWidth: 350)
                        } else if viewModel.orgs != nil && viewModel.orgs!.count == 0 {
                            HStack{
                                Text("No organisation were found associated to your profile.")
                                    .font(.title3)
                                    .foregroundColor(Color("KentoRedFont"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(width: 350)
                        }
                        
                        if viewModel.selectedEvent != nil {
                            HStack {
                                VStack{
                                    Text("Event: ")
                                        .font(.title3)
                                        .foregroundColor(Color("KentoRedFont"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(viewModel.selectedEvent!.name)")
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
                                        viewModel.title = "event"
                                        viewModel.selectedEvent = nil
                                        viewModel.selectedBadges = []
                                        viewModel.selectedBadgesIds = []
                                        viewModel.badges = nil
                                    }
                                
                            }
                            .frame(maxWidth: 350)
                        } else if viewModel.events != nil && viewModel.events!.count == 0 {
                            HStack{
                                Text("No future event was found associated to this organisation.")
                                    .font(.title3)
                                    .foregroundColor(Color("KentoRedFont"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(width: 350)
                        }
                        
                        if viewModel.badges != nil {
                            HStack {
                                if viewModel.badges!.count == 0 {
                                    Text("No badge was found associated to this event.")
                                        .font(.title3)
                                        .foregroundColor(Color("KentoRedFont"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    VStack {
                                        Text("Badges: ")
                                            .font(.title3)
                                            .foregroundColor(Color("KentoRedFont"))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        if viewModel.selectedBadges.count == 0 {
                                            Text("Select at least one badge to Scan.")
                                                .font(.title3)
                                                .foregroundColor(Color("KentoBlueGrey"))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                            .frame(width: 350)
                        }
                            
                    }
                    
                    // Selection stack
                    VStack {
                        
                        if viewModel.selectedOrg == nil {
                            if viewModel.selectedOrg != nil {
                                // Select organisation
                                if viewModel.orgs!.count > 1 {
                                    ForEach(viewModel.orgs!, id: \.id) { org in
                                        Button("\(org.name)"){
                                            // Fetch events
                                            viewModel.selectedOrg = org
                                            viewModel.eventInit(orgId: org.id) { result in
                                                switch result {
                                                case .success(_):
                                                    DispatchQueue.main.async {
                                                        scanInfo.scanTerminal = viewModel.scanTerminal
                                                        print("Scan terminal setup: \(viewModel.scanTerminal)")
                                                    }
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
                        }
                        
                        // Select event
                        if viewModel.selectedEvent == nil {
                            if viewModel.events != nil {
                                if viewModel.events!.count > 1 {
                                    ForEach(viewModel.events!, id: \.id) { event in
                                        Button("\(event.name)"){
                                            viewModel.selectedEvent = event
                                            viewModel.eventInit(eventId: event.id) { result in
                                                switch result {
                                                case .success(_):
                                                    DispatchQueue.main.async {
                                                        scanInfo.scanTerminal = viewModel.scanTerminal
                                                        print("Scan terminal setup: \(viewModel.scanTerminal)")
                                                    }
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
                        }
                        
                        // Select badges
                        if viewModel.badges != nil {
                            if viewModel.badges!.count > 1 {
                                List {
                                    ForEach(viewModel.badges!, id: \.id) { badge in
                                        MultipleSelectionRow(title: badge.name, isSelected: viewModel.selectedBadgesIds.contains(badge.id)) {
                                            if viewModel.selectedBadgesIds.contains(badge.id) {
                                                viewModel.selectedBadges.removeAll(where: { $0 == badge })
                                                viewModel.selectedBadgesIds.removeAll(where: { $0 == badge.id })
                                            }
                                            else {
                                                viewModel.selectedBadges.append(badge)
                                                viewModel.selectedBadgesIds.append(badge.id)
                                            }
                                        }
                                    }
                                    .listRowBackground(Color("KentoBeige"))
                                }
                                .listStyle(.plain)
                                .background(Color("KentoBeige"))
                                
                                if viewModel.selectedBadges.count > 0 {
                                    Button("Confirm"){
                                        viewModel.selectedBadge(badgeIds: viewModel.selectedBadgesIds) { result in
                                            switch result {
                                            case .success(_):
                                                if viewModel.participantsAndBadges.count > 0 {
                                                    scanInfo.badges = viewModel.selectedBadges
                                                    scanInfo.participantsAndBadges = viewModel.participantsAndBadges
                                                    viewModel.isShowingQRScanView = true
                                                } else {
                                                    viewModel.selectedBadges = []
                                                    viewModel.selectedBadgesIds = []
                                                    HStack{
                                                        Text("No partipcant was found associated to those badges.")
                                                            .font(.title3)
                                                            .foregroundColor(Color("KentoRedFont"))
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                    }
                                                    .frame(width: 350)
                                                }
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
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoGreen")))
                                }
                                
                            }
                        }
                        
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    
                }
                .navigationTitle(Text("Select \(viewModel.title)"))
            
                
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
            
        }
        // Fetch organisations at init
        .onAppear {
            viewModel.setupTokenFetchOrgs(token: loginInfo.token)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .environmentObject(scanInfo)
        .accentColor(Color("KentoRed"))
        
    }
    
}

struct EventInitView_Previews: PreviewProvider {
    static var previews: some View {
        EventInitView()
    }
}
