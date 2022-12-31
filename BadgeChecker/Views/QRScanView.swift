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

struct ErrorStack: View {
    
    var errorMessage: String = ""

    init(errorMessage: String) {
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        Image(systemName: "xmark.circle")
            .font(.system(size: 30, weight: .regular))
            .foregroundColor(Color("KentoError"))
            .padding()
        Text(errorMessage)
            .font(.title3)
            .foregroundColor(Color("KentoError"))
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
}

struct QRScanView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var loginInfo: LoginInfo
    @EnvironmentObject var scanInfo: ScanInfo
    
    @ObservedObject var viewModel = QRScanViewModel()
    
    var scannerSheet : some View {
        CodeScannerView(codeTypes: [.qr], completion: viewModel.handleScan)
    }
        
    var body: some View {
        
        ZStack {
            VStack {
                // Server synchronization stack
                EmptyView()
                    .onReceive(viewModel.timer) { time in
                        viewModel.participantListUpdate(
                            changedBadgeEntities: viewModel.changedBadgeEntities,
                            scanTerminal: viewModel.scanTerminal,
                            badges: viewModel.badges,
                            lastQueryUnixTimeStamp: viewModel.lastQueryUnixTimeStamp) { result in
                            switch result {
                            case .success(_):
                                print("ParticipantListUpdate success!")
                                return
                            case .failure(let error):
                                print("ParticipantListUpdate error: \(error)")
                            }
                        }
                    }
                
                // Kento scanned stack
                VStack {
                    Button(action: {
                        viewModel.timer.upstream.connect().cancel()
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .font(.system(size: 30, weight: .regular))
                            .foregroundColor(Color("KentoRed"))
                            .padding()
                    }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        
                    Text("\(viewModel.validatedBadgesCount) / \(viewModel.badgesCount) kentos scanned")
                        .font(.title3)
                        .foregroundColor(Color("KentoBlueGrey"))
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                }
                Divider().padding()
                
                // Result stack
                VStack {
                    if viewModel.scannedFirstName.count > 0  && viewModel.scannedLastName.count > 0 {
                        Text("\(viewModel.scannedFirstName), \(viewModel.scannedLastName)")
                            .foregroundColor(Color("KentoBlueGrey"))
                            .font(.title3)
                            .frame(minWidth: 0, maxWidth: 350, alignment: .leading)
                    }
                    
                    if viewModel.scanFailed {
                        ErrorStack(errorMessage: "Scan failed")
                    }
                    if viewModel.notFoundKento {
                        ErrorStack(errorMessage: "The kento wasn't found")
                    }
                    if viewModel.alreadyValidatedKento {
                        ErrorStack(errorMessage: "Kento already validated")
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
                }
                
                // Badge selection stack
                VStack {
                    if viewModel.scannedParticipantAndUnusedBadges != nil {
                        if viewModel.scannedParticipantAndUnusedBadges!.badges.count > 1 {
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
                                                viewModel.changedBadgeEntities.append(viewModel.participantAllBadgesList[participantRow].badges[badgeRow].badgeEntityId)
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
                
                // List selection stack
                VStack {
                    if viewModel.isPresentingList {
                        TextField("Search participants", text: $viewModel.name)
                            .onChange(of: viewModel.name) { newValue in
                                if viewModel.name.count > 0 {
                                    viewModel.filteredParticipantAllBadgesList = viewModel.participantAllBadgesList.filter { $0.firstName.contains(viewModel.name) || $0.lastName.contains(viewModel.name) }
                                } else {
                                    viewModel.filteredParticipantAllBadgesList = viewModel.participantAllBadgesList
                                }
                            }
                            .disableAutocorrection(true)
                            .foregroundColor(Color("KentoBeige"))
                            .autocapitalization(.none)
                            .multilineTextAlignment(.center)
                            .frame(width: 350, height: 40)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                        
                        List(0..<viewModel.filteredParticipantAllBadgesList.count, id: \.self) { i in
                            HStack {
                                Text("\(viewModel.filteredParticipantAllBadgesList[i].firstName), \(viewModel.filteredParticipantAllBadgesList[i].lastName)")
                                    .foregroundColor(Color("KentoBlueGrey"))
                                Text("\(viewModel.filteredParticipantAllBadgesList[i].badges.filter { $0.isUsed }.count)/\(viewModel.filteredParticipantAllBadgesList[i].badges.count)")
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                if viewModel.filteredParticipantAllBadgesList[i].badges.filter { $0.isUsed }.count == viewModel.filteredParticipantAllBadgesList[i].badges.count {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color("KentoSuccess"))
                                        .frame(alignment: .trailing)
                                } else if viewModel.filteredParticipantAllBadgesList[i].badges.filter { $0.isUsed }.count > 0 {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color("KentoWarning"))
                                        .frame(alignment: .trailing)
                                }
                            }
                            .onTapGesture {
                                viewModel.selectParticipant(participant: &viewModel.filteredParticipantAllBadgesList[i])
                            }
                            .listRowBackground(Color("KentoBeige"))
                        }
                        .listStyle(.plain)
                        .background(Color("KentoBeige"))
                        
                    }
                }
                
                // Toggle menu
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Button {
                            viewModel.setupScanView()
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
                            viewModel.setupListView()
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
            .navigationBarHidden(true)
            
        }
        .onAppear {
            viewModel.setupScanningVariables(
                token: loginInfo.token,
                scanTerminal: scanInfo.scanTerminal!,
                badges: scanInfo.badges!,
                participantBadgeList: scanInfo.participantsAndBadges!
            )
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
