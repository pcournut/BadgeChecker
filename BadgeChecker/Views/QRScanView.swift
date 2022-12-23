//
//  QRScanView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import CodeScanner

func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    return .none
}

struct QRScanView: View {
    
    
    @EnvironmentObject var loginInfo: LoginInfo
    @EnvironmentObject var scanInfo: ScanInfo
    
    @ObservedObject var viewModel = QRScanViewModel()
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        viewModel.isPresentingScanner = false
        
        switch result {
        case .success(let result):
            let scannedParticipantAllBadges = viewModel.participantAllBadgesList.filter { $0.userId == result.string }
            
            if scannedParticipantAllBadges.count == 1 {
                viewModel.scannedFirstName = scannedParticipantAllBadges[0].firstName
                viewModel.scannedLastName = scannedParticipantAllBadges[0].lastName
                
                let scannedUnusedBadges = scannedParticipantAllBadges[0].badges.filter { !$0.isUsed }
                if scannedUnusedBadges.count == 0 {
                    viewModel.alreadyValidatedKento = true
                } else if scannedUnusedBadges.count == 1 {
                    if let participantRow = viewModel.participantAllBadgesList.firstIndex(where: {$0.userId == result.string}) {
                        if let badgeRow = viewModel.participantAllBadgesList[participantRow].badges.firstIndex(where: {!$0.isUsed}) {
                            viewModel.participantAllBadgesList[participantRow].badges[badgeRow].isUsed = true
                            viewModel.scannedParticipantBadgeList.append(
                                ParticipantScanInfo(
                                    userId: viewModel.participantAllBadgesList[participantRow].userId,
                                    firstName: viewModel.participantAllBadgesList[participantRow].firstName,
                                    lastName: viewModel.participantAllBadgesList[participantRow].lastName,
                                    badgeEntityId: viewModel.participantAllBadgesList[participantRow].badges[badgeRow].badgeEntityId,
                                    badgeId: viewModel.participantAllBadgesList[participantRow].badges[badgeRow].badgeId, isUsed: true
                                )
                            )
                        }
 
                    }
                    viewModel.validatedBadgesCount += 1
                    viewModel.validatedKento = true
                } else {
                    viewModel.scannedParticipantAndUnusedBadges = ParticipantAllBadges(
                        userId: scannedParticipantAllBadges[0].userId,
                        firstName: scannedParticipantAllBadges[0].firstName,
                        lastName: scannedParticipantAllBadges[0].lastName,
                        badges: scannedUnusedBadges
                    )
                }
            } else {
                viewModel.notFoundKento = true
            }

        case .failure(let error):
            viewModel.scanFailed = true
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    var scannerSheet : some View {
        CodeScannerView(codeTypes: [.qr], completion: handleScan)
    }
        
    var body: some View {
        
        ZStack {
            VStack {
                Text("\(viewModel.validatedBadgesCount) / \(viewModel.badgesCount) kentos scanned")
                    .font(.title3)
                    .foregroundColor(Color("KentoBlueGrey"))
                Divider().frame(maxHeight: 30)
                
                // Display name of person scanned
                HStack {
                    if viewModel.scannedFirstName.count > 0  && viewModel.scannedLastName.count > 0 {
                        Text("\(viewModel.scannedFirstName), \(viewModel.scannedLastName)")
                            .foregroundColor(Color("KentoBlueGrey"))
                            .font(.title2)
                            .frame(minWidth: 0, maxWidth: 350, alignment: .leading)
                    }
                }
                
                if viewModel.scanFailed {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundColor(Color("KentoError"))
                        .padding()
                    Text("Scan failed")
                        .font(.title3)
                        .foregroundColor(Color("KentoError"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                if viewModel.notFoundKento {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundColor(Color("KentoError"))
                        .padding()
                    Text("The kento wasn't found")
                        .font(.title3)
                        .foregroundColor(Color("KentoError"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                if viewModel.alreadyValidatedKento {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundColor(Color("KentoError"))
                        .padding()
                    Text("Kento already validated")
                        .font(.title3)
                        .foregroundColor(Color("KentoError"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                if viewModel.validatedKento {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundColor(Color("KentoSuccess"))
                        .padding()
                    Text("Validated")
                        .font(.title3)
                        .foregroundColor(Color("KentoSuccess"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                if viewModel.scannedParticipantAndUnusedBadges != nil {
                    if viewModel.scannedParticipantAndUnusedBadges!.badges.count > 1 {
                        VStack {
                            List {
                                ForEach(viewModel.scannedParticipantAndUnusedBadges!.badges, id: \.badgeEntityId) { badge in
                                    if let row = scanInfo.badges!.firstIndex(where: {$0.id == badge.badgeId}) {
                                        MultipleSelectionRow(title: scanInfo.badges![row].name, isSelected: viewModel.selectedBadgeEntitiesIds.contains(badge.badgeEntityId)) {
                                            if viewModel.selectedBadgeEntitiesIds.contains(badge.badgeEntityId) {
                                                viewModel.selectedBadgeEntitiesIds.removeAll(where: { $0 == badge.badgeEntityId })
                                            }
                                            else {
                                                viewModel.selectedBadgeEntitiesIds.append(badge.badgeEntityId)
                                            }
                                        }
                                    }
                                }
                                .listRowBackground(Color("KentoBeige"))
                            }
                            .listStyle(.plain)
                            .background(Color("KentoBeige"))
                            
                            if viewModel.selectedBadgeEntitiesIds.count > 0 {
                                Button("Confirm"){
                                    for badgeEntityId in viewModel.selectedBadgeEntitiesIds {
                                        if let participantRow = viewModel.participantAllBadgesList.firstIndex(where: {$0.userId == viewModel.scannedParticipantAndUnusedBadges!.userId}) {
                                            if let badgeRow = viewModel.participantAllBadgesList[participantRow].badges.firstIndex(where: {$0.badgeEntityId == badgeEntityId}) {
                                                viewModel.participantAllBadgesList[participantRow].badges[badgeRow].isUsed = true
                                                viewModel.scannedParticipantBadgeList.append(
                                                    ParticipantScanInfo(
                                                        userId: viewModel.participantAllBadgesList[participantRow].userId,
                                                        firstName: viewModel.participantAllBadgesList[participantRow].firstName,
                                                        lastName: viewModel.participantAllBadgesList[participantRow].lastName,
                                                        badgeEntityId: viewModel.participantAllBadgesList[participantRow].badges[badgeRow].badgeEntityId,
                                                        badgeId: viewModel.participantAllBadgesList[participantRow].badges[badgeRow].badgeId, isUsed: true
                                                    )
                                                )
                                            }
                                        }
                                    }
                                    viewModel.validatedBadgesCount += viewModel.selectedBadgeEntitiesIds.count
                                    viewModel.validatedKento = true
                                    viewModel.scannedParticipantAndUnusedBadges = nil
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
                
                if viewModel.isPresentingList {
                    TextField("Search participants", text: $viewModel.name)
                        .disableAutocorrection(true)
                        .foregroundColor(Color("KentoBeige"))
                        .autocapitalization(.none)
                        .multilineTextAlignment(.center)
                        .frame(width: 350, height: 40)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                    
                    if viewModel.name.count > 0 {
                        List(0..<viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }.count, id: \.self) { i in
                            HStack {
                                Text("\(viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }[i].lastName), \(viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }[i].firstName)")
                                    .foregroundColor(Color("KentoBlueGrey"))
                                Text("\(viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }[i].badges.filter { $0.isUsed }.count)/\(viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }[i].badges.count)")
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                if viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }[i].badges.filter { $0.isUsed }.count == viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }[i].badges.count {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color("KentoSuccess"))
                                        .frame(alignment: .trailing)
                                } else if viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }[i].badges.filter { $0.isUsed }.count > 0 {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color("KentoWarning"))
                                        .frame(alignment: .trailing)
                                }
                            }
                            .listRowBackground(Color("KentoBeige"))
                        }
                        .listStyle(.plain)
                        .background(Color("KentoBeige"))
                    } else {
                        List(0..<viewModel.participantAllBadgesList.count, id: \.self) { i in
                            HStack {
                                Text("\(viewModel.participantAllBadgesList[i].lastName), \(viewModel.participantAllBadgesList[i].firstName)")
                                    .foregroundColor(Color("KentoBlueGrey"))
                                Text("\(viewModel.participantAllBadgesList[i].badges.filter { $0.isUsed }.count)/\(viewModel.participantAllBadgesList[i].badges.count)")
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                if viewModel.participantAllBadgesList[i].badges.filter { $0.isUsed }.count == viewModel.participantAllBadgesList[i].badges.count {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color("KentoSuccess"))
                                        .frame(alignment: .trailing)
                                } else if viewModel.participantAllBadgesList[i].badges.filter { $0.isUsed }.count > 0 {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color("KentoWarning"))
                                        .frame(alignment: .trailing)
                                }
                            }
                            .onTapGesture {
                                viewModel.isPresentingList = false
                                let scannedUnusedBadges = viewModel.participantAllBadgesList[i].badges.filter { !$0.isUsed }
                                if scannedUnusedBadges.count == 1 {
                                    viewModel.scannedFirstName = viewModel.participantAllBadgesList[i].firstName
                                    viewModel.scannedLastName = viewModel.participantAllBadgesList[i].lastName
                                    if let badgeRow = viewModel.participantAllBadgesList[i].badges.firstIndex(where: {!$0.isUsed}) {
                                        viewModel.participantAllBadgesList[i].badges[badgeRow].isUsed = true
                                        viewModel.scannedParticipantBadgeList.append(
                                            ParticipantScanInfo(
                                                userId: viewModel.participantAllBadgesList[i].userId,
                                                firstName: viewModel.participantAllBadgesList[i].firstName,
                                                lastName: viewModel.participantAllBadgesList[i].lastName,
                                                badgeEntityId: viewModel.participantAllBadgesList[i].badges[badgeRow].badgeEntityId,
                                                badgeId: viewModel.participantAllBadgesList[i].badges[badgeRow].badgeId, isUsed: true
                                            )
                                        )
                                    }
                                    viewModel.validatedBadgesCount += 1
                                    viewModel.validatedKento = true
                                } else if scannedUnusedBadges.count > 1 {
                                    viewModel.scannedFirstName = viewModel.participantAllBadgesList[i].firstName
                                    viewModel.scannedLastName = viewModel.participantAllBadgesList[i].lastName
                                    viewModel.scannedParticipantAndUnusedBadges = ParticipantAllBadges(
                                        userId: viewModel.participantAllBadgesList[i].userId,
                                        firstName: viewModel.participantAllBadgesList[i].firstName,
                                        lastName: viewModel.participantAllBadgesList[i].lastName,
                                        badges: scannedUnusedBadges
                                    )
                                }
                            }
                            .listRowBackground(Color("KentoBeige"))
                        }
                        .listStyle(.plain)
                        .background(Color("KentoBeige"))
                    }
                    
                }
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Button {
                            viewModel.scannedFirstName = ""
                            viewModel.scannedLastName = ""
                            viewModel.scanFailed = false
                            viewModel.isPresentingScanner = true
                            viewModel.isPresentingList = false
                            viewModel.scannedParticipantAndUnusedBadges = nil
                            viewModel.validatedKento = false
                            viewModel.alreadyValidatedKento = false
                            viewModel.notFoundKento = false
                        } label: {
                            Label("Scan", systemImage: "qrcode.viewfinder")
                                .font(.title2)
                        }
                        .sheet(isPresented: $viewModel.isPresentingScanner) {
                            self.scannerSheet
                        }
                        .frame(width: geometry.size.width * 0.50, alignment: .center)
                    
                        Divider()
                        
                        Button {
                            viewModel.scannedFirstName = ""
                            viewModel.scannedLastName = ""
                            viewModel.scanFailed = false
                            viewModel.isPresentingScanner = false
                            viewModel.scannedParticipantAndUnusedBadges = nil
                            viewModel.validatedKento = false
                            viewModel.alreadyValidatedKento = false
                            viewModel.notFoundKento = false
                            viewModel.isPresentingList = true
                        } label : {
                            Label("List", systemImage: "list.dash")
                                .font(.title2)
                        }
                        .frame(width: geometry.size.width * 0.50, alignment: .center)
                    }
                }
                .frame(height: 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
                
            }
        }
        .onAppear {
            viewModel.setupView(token: loginInfo.token, participantBadgeList: scanInfo.participantsAndBadges!)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
    }
    
        
}

struct QRScanView_Previews: PreviewProvider {
    static var previews: some View {
        QRScanView()
    }
}
