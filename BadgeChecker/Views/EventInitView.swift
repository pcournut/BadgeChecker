//
//  EventInitView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import SVGView
import Foundation


struct RoundedIcon: View {
    let size: CGFloat
    let iconPath: String?
    let strokeBorderColor: Color
    
    var body: some View {
        ZStack {
            if iconPath != nil{
                if NSString(string: iconPath!).pathExtension == "svg" {
                    if #available(iOS 16.0, *) {
                        SVGView(contentsOf: URL(filePath: iconPath!))
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        SVGView(contentsOf: URL(string: iconPath!)!)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    }
                } else if URL(string: iconPath!) != nil {
                    AsyncImage(url: URL(string: iconPath!)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                }
            }
            
            Circle()
                .strokeBorder(strokeBorderColor, lineWidth: 1)
                .background(Circle().fill(.clear))
                .frame(width:size, height: size)
        }
    }
}

struct SelectionOrgCell: View {

    let org: Organisation
    let viewModel: EventInitViewModel
    
    @Binding var selectedOrg: Organisation?
    
    var body: some View {
        Button(action: {
            if !viewModel.isShowingWaitingView {
                selectedOrg = self.org
                viewModel.events = nil
                viewModel.badges = nil
                viewModel.selectedEvent = nil
                viewModel.selectedBadges = []
                viewModel.selectedBadgesIds = []
                viewModel.selectedBadgesCount = 0
                viewModel.scanTerminal = nil
                viewModel.mainViewOpacity = 0.5
                viewModel.isShowingWaitingView = true
                viewModel.eventInit(orgId: org.id) { result in
                    switch result {
                    case .success(_):
                        viewModel.mainViewOpacity = 1.0
                        viewModel.isShowingWaitingView = false
                        return
                    case .failure(let error):
                        viewModel.mainViewOpacity = 1.0
                        viewModel.isShowingWaitingView = false
                        print("error: \(error)")
                    }
                }
            }
        }) {
            VStack {
                Text(self.org.name)
                    .font(.callout)
                    .foregroundColor(Color("KentoCharbon"))
                    .padding([.top, .leading, .trailing], 10)
                
                RoundedIcon(size: 70, iconPath: org.iconPath, strokeBorderColor: Color("KentoCharbon"))
                    .padding(.bottom, 10)

            } // VStack
            .background(RoundedRectangle(cornerRadius: 20).fill(self.selectedOrg != nil && self.selectedOrg!.id == self.org.id ? Color("KentoGreen") : Color(.clear)))
        } // Button
    } // View
}

struct SelectionEventCell: View {

    let event: Event
    let viewModel: EventInitViewModel
    
    @Binding var selectedEvent: Event?
    

    var body: some View {
        
        Button(action: {
            if !viewModel.isShowingWaitingView {
                selectedEvent = self.event
                viewModel.badges = nil
                viewModel.selectedBadges = []
                viewModel.selectedBadgesIds = []
                viewModel.selectedBadgesCount = 0
                viewModel.scanTerminal = nil
                viewModel.mainViewOpacity = 0.5
                viewModel.isShowingWaitingView = true
                viewModel.eventInit(orgId: viewModel.selectedOrg!.id, eventId: event.id) { result in
                    switch result {
                    case .success(_):
                        viewModel.mainViewOpacity = 1.0
                        viewModel.isShowingWaitingView = false
                        return
                    case .failure(let error):
                        viewModel.mainViewOpacity = 1.0
                        viewModel.isShowingWaitingView = false
                        print("error: \(error)")
                    }
                }
            }
        }) {
            HStack {
                RoundedIcon(size: 50, iconPath: event.iconPath, strokeBorderColor: Color("KentoCharbon"))
                
                Text(self.event.name)
                    .font(.callout)
                    .foregroundColor(Color("KentoCharbon"))
                
                Spacer()
                
                if self.selectedEvent != nil && self.selectedEvent!.id == self.event.id {
                    Image(systemName: "circle.inset.filled")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color("KentoCharbon"))
                        .frame(maxWidth: 50, maxHeight: 50, alignment: .trailing)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color("KentoCharbon"))
                        .frame(maxWidth: 50, maxHeight: 50, alignment: .trailing)
                }
            } // HStack
        } // Button
    } // View
}

struct MultipleSelectionBadgeCell: View {
    var title: String
    var iconPath: String?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        
        Button(action: self.action) {
            HStack {
                RoundedIcon(size: 50, iconPath: iconPath, strokeBorderColor: Color("KentoCharbon"))
                
                Text(self.title)
                    .font(.callout)
                    .foregroundColor(Color("KentoCharbon"))
                
                Spacer()
                
                if self.isSelected {
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color("KentoCharbon"))
                        .frame(maxWidth: 50, maxHeight: 50, alignment: .trailing)
                } else {
                    Image(systemName: "square")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color("KentoCharbon"))
                        .frame(maxWidth: 50, maxHeight: 50, alignment: .trailing)
                }
            }
        }
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
                if viewModel.isShowingWaitingView {
                    WaitingView()
                }
                
                GeometryReader { geometry in
                    VStack {
                        NavigationLink(destination: QRScanView(), isActive: $viewModel.isShowingQRScanView) {
                            EmptyView()
                        }
                        
                        // Title stack
                        HStack {
                            Text("Configure your scan")
                                .bold()
                                .font(.title)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .frame(height: geometry.size.height * 0.08)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            
                        }
                        
                        // Organisation stack
                        if viewModel.orgs != nil {
                            VStack {
                                Text("\(viewModel.orgs!.count > 1 ? "Select an organisation" : "Your organisation")")
                                    .bold()
                                    .font(.title3)
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                
                                if viewModel.orgs!.count > 0 {
                                    ScrollView(.horizontal) {
                                        LazyHStack {
                                            ForEach(viewModel.orgs!, id: \.self) { org in
                                                SelectionOrgCell(
                                                    org: org,
                                                    viewModel: viewModel,
                                                    selectedOrg: $viewModel.selectedOrg
                                                )
                                            }
                                            .listRowBackground(Color("KentoCharbon"))
                                        }
                                    }
                                    .listStyle(.plain)
                                    .frame(minWidth: 0, maxWidth: 350)
                                } else if !viewModel.isShowingWaitingView {
                                    HStack{
                                        Text("No organisation was found associated to your profile.")
                                            .font(.callout)
                                            .padding()
                                            .foregroundColor(Color("KentoError"))
                                            .frame(minWidth: 0, maxWidth: 350, alignment: .center)
                                    }
                                } else {
                                    Spacer()
                                }
                            }
                            .frame(height: geometry.size.height * 0.26)
                        }
                        
                        // Event stack
                        if viewModel.selectedOrg != nil {
                            VStack {
                                Text("\(viewModel.events?.count ?? 0 > 1 ? "Select an event" : "Your event")")
                                    .bold()
                                    .font(.title3)
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                
                                if viewModel.events != nil && viewModel.events!.count > 0 {
                                    ScrollView() {
                                        ForEach(viewModel.events!, id: \.self) { event in
                                            SelectionEventCell(
                                                event: event,
                                                viewModel: viewModel,
                                                selectedEvent: $viewModel.selectedEvent
                                            )
                                        }
                                        .listRowBackground(Color("KentoCharbon"))
                                    }
                                    .listStyle(.plain)
                                    .frame(minWidth: 0, maxWidth: 350)
                                } else if !viewModel.isShowingWaitingView {
                                    HStack{
                                        Text("No future event was found associated to this organisation.")
                                            .font(.callout)
                                            .padding()
                                            .foregroundColor(Color("KentoError"))
                                            .frame(minWidth: 0, maxWidth: 350, alignment: .center)
                                    }
                                }
                                
                                Spacer()
                            }
                            .frame(height: geometry.size.height * 0.24)
                        }
                        
                        
                        // Badge stack
                        if viewModel.selectedEvent != nil {
                            VStack {
                                Text("Select \(viewModel.badges?.count ?? 0 > 1 ? "passes": "the pass") you want to scan")
                                    .bold()
                                    .font(.title3)
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                
                                if viewModel.badges != nil && viewModel.badges!.count > 0 {
                                    ScrollView(.vertical, showsIndicators: true) {
                                        ForEach(viewModel.badges!, id: \.self) { badge in
                                            MultipleSelectionBadgeCell(
                                                title: badge.name,
                                                iconPath: badge.iconPath,
                                                isSelected: viewModel.selectedBadgesIds.contains(badge.id)) {
                                                    if !viewModel.isShowingWaitingView {
                                                        if viewModel.selectedBadgesIds.contains(badge.id) {
                                                            viewModel.selectedBadges.removeAll(where: { $0 == badge })
                                                            viewModel.selectedBadgesIds.removeAll(where: { $0 == badge.id })
                                                            viewModel.selectedBadgesCount -= badge.maxSupply
                                                        }
                                                        else {
                                                            viewModel.selectedBadges.append(badge)
                                                            viewModel.selectedBadgesIds.append(badge.id)
                                                            viewModel.selectedBadgesCount += badge.maxSupply
                                                        }
                                                    }
                                                }
                                        }
                                        .listRowBackground(Color("KentoCharbon"))
                                    }
                                    .listStyle(.plain)
                                    .frame(minWidth: 0, maxWidth: 350)
                                } else if !viewModel.isShowingWaitingView {
                                    HStack{
                                        Text("No badge was found associated to this event.")
                                            .font(.callout)
                                            .padding()
                                            .foregroundColor(Color("KentoError"))
                                            .frame(minWidth: 0, maxWidth: 350, alignment: .center)
                                    }
                                }
                                
                                Spacer()
                            }
                            .frame(height: geometry.size.height * 0.24)
                        }
                        
                        // Start to scan stack
                        if viewModel.selectedOrg != nil && viewModel.selectedEvent != nil {
                            VStack {
                                if viewModel.selectedBadges.count > 0 {
                                    Button(action: {
                                        viewModel.mainViewOpacity = 0.5
                                        viewModel.isShowingWaitingView = true
                                        viewModel.selectedBadge() { result in
                                            switch result {
                                            case .success(_):
                                                scanInfo.scanTerminal = viewModel.scanTerminal
                                                scanInfo.badges = viewModel.selectedBadges
                                                scanInfo.enrichedBadgeEntities = viewModel.enrichedBadgeEntities
                                                viewModel.mainViewOpacity = 1.0
                                                viewModel.isShowingQRScanView = true
                                                viewModel.isShowingWaitingView = false
                                            case .failure(let error):
                                                viewModel.mainViewOpacity = 1.0
                                                viewModel.isShowingWaitingView = false
                                                print("error: \(error)")
                                            }
                                        }
                                    }) {
                                        Text("Start to scan")
                                            .font(.title3)
                                            .foregroundColor(Color("KentoCharbon"))
                                            .padding()
                                            .frame(minWidth: 0, maxWidth: 350)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoGreen")))
                                    }
                                } else {
                                    Text("Select the pass to validate")
                                        .font(.title3)
                                        .foregroundColor(Color("KentoBlueGrey"))
                                        .padding()
                                        .frame(minWidth: 0, maxWidth: 350)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoLune")))
                                }
                            }
                            .frame(height: geometry.size.height * 0.08)
                        }
                        
                    } // VStack
                    .frame(width: 350)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                } // GeometryReader
                .opacity(viewModel.mainViewOpacity)
                
            } // ZStack
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
            
        } // NavigationView
        // Fetch organisations at init
        .onAppear {
            viewModel.setupTokenFetchOrgs(token: loginInfo.token)
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .edgesIgnoringSafeArea([.top, .bottom])
        .environmentObject(scanInfo)
        .accentColor(Color("KentoRed"))
        
    } // some View
    
} // View

struct EventInitView_Previews: PreviewProvider {
    static var previews: some View {
        EventInitView()
    }
}
