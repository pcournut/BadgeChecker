//
//  QRScanView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import SVGView
import CodeScanner

func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    return .none
}

struct MultipleSelectionBubble: View {
    var title: String
    var iconPath: String?
    var isSelected: Bool
    var isUsed: Bool
    var severalBadge: Bool
    var action: () -> Void

    var body: some View {
        VStack {
            Button(action: self.action) {
                RoundedIcon(size: 100, iconPath: iconPath, strokeBorderColor: Color("KentoBeige"))
                
                if severalBadge {
                    if self.isSelected {
                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color("KentoBeige"))
                            .frame(maxWidth: 120, maxHeight: 120, alignment: .topTrailing)
                    } else {
                        Image(systemName: "square")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color("KentoBeige"))
                            .frame(maxWidth: 120, maxHeight: 120, alignment: .topTrailing)
                    }
                }
            }
            .padding(.top, 10)
            
            Text(self.title)
                .font(.title3)
                .padding([.bottom, .leading, .trailing], 10)
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(isUsed ? Color("KentoGreen") : Color(.clear)))
    }
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
    
    @State var isPresented: Bool = false
    
    var scannerSheet : some View {
        CodeScannerView(
            codeTypes: [.qr],
            scanMode: .continuous,
            isGalleryPresented: $viewModel.isPresentingPhotoGallery,
            completion: viewModel.handleScan)
    }
    
    var resultStack: some View {
        ZStack {
            VStack {
                // Result info stack
                HStack {
                    VStack {
                        if viewModel.scannedFirstName.count > 0  && viewModel.scannedLastName.count > 0 {
                            Text("\(viewModel.scannedFirstName), \(viewModel.scannedLastName)")
                                .foregroundColor(Color("KentoBeige"))
                                .font(.title2)
                                .frame(minWidth: 0, maxWidth: 350, alignment: .leading)
                                .padding(5)
                        }
                        if viewModel.scannedEmail.count > 0 {
                            Text("\(viewModel.scannedEmail)")
                                .foregroundColor(Color("KentoBeige"))
                                .font(.callout)
                                .frame(minWidth: 0, maxWidth: 350, alignment: .leading)
                                .padding(2)
                        }
                        if viewModel.scannedBadgeName.count > 0 {
                            Text("\(viewModel.scannedBadgeName)")
                                .foregroundColor(Color("KentoBeige"))
                                .font(.callout)
                                .frame(minWidth: 0, maxWidth: 350, alignment: .leading)
                        }
                    }
                    .frame(alignment: .topLeading)
                    
                    Button(action: viewModel.dismissResultStack) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color("KentoBeige"))
                    }
                    .frame(minWidth: 0, maxWidth: 350, alignment: .trailing)
                    
                }
                .padding(.top, 10)
                .frame(minWidth: 0, maxWidth: 350, alignment: .top)
                
                
                Spacer()
                
                // Result pictograms stack
                VStack {
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
                    }
                }
                .frame(alignment: .center)
                
                Spacer()
                
                // Badge list stacks
                VStack {
                    if viewModel.scannedParticipantAndBadges != nil {
                        if viewModel.scannedParticipantAndBadges!.badges.count > 1 {
                            ScrollView(.horizontal) {
                                LazyHStack {
                                    ForEach(viewModel.scannedParticipantAndBadges!.badges, id: \.badgeEntityId) { badge in
                                        if let row = scanInfo.badges!.firstIndex(where: {$0.id == badge.badgeId}) {
                                            MultipleSelectionBubble(
                                                title: scanInfo.badges![row].name,
                                                iconPath: scanInfo.badges![row].iconPath,
                                                isSelected: viewModel.selectedBadgeEntitiesIds.contains(badge.badgeEntityId),
                                                isUsed: badge.isUsed,
                                                severalBadge: true
                                            ) {
                                                if !badge.isUsed {
                                                    if viewModel.selectedBadgeEntitiesIds.contains(badge.badgeEntityId) {
                                                        viewModel.selectedBadgeEntitiesIds.removeAll(where: { $0 == badge.badgeEntityId })
                                                    } else {
                                                        viewModel.selectedBadgeEntitiesIds.append(badge.badgeEntityId)
                                                        
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .listRowBackground(Color("KentoBlueGrey"))
                                }
                            }
                            .listStyle(.plain)
                            .frame(minWidth: 0, maxWidth: 350)
                        } else if viewModel.scannedParticipantAndBadges!.badges.count == 1 {
                            let badge = viewModel.scannedParticipantAndBadges!.badges[0]
                            if let row = scanInfo.badges!.firstIndex(where: {$0.id == badge.badgeId}) {
                                MultipleSelectionBubble(
                                    title: scanInfo.badges![row].name,
                                    iconPath: scanInfo.badges![row].iconPath,
                                    isSelected: viewModel.selectedBadgeEntitiesIds.contains(badge.badgeEntityId),
                                    isUsed: badge.isUsed,
                                    severalBadge: false
                                ) {
                                }
                            }
                        }
                    }
                }
                .frame(alignment: .center)
                
                Spacer()
                
                // Validate stack
                VStack {
                    if viewModel.scannedParticipantAndBadges != nil {
                        if viewModel.selectedBadgeEntitiesIds.count > 0 {
                            Button(action: {
                                viewModel.validateSelection()
                            }) {
                                Text("Validate \(viewModel.selectedBadgeEntitiesIds.count > 1 ? "("+String(viewModel.selectedBadgeEntitiesIds.count)+" kentos selected)":"")")
                                    .font(.title3)
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .padding()
                                    .frame(minWidth: 0, maxWidth: 350)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoGreen")))
                            }
                        } else if viewModel.scannedParticipantAndBadges!.badges.filter({!$0.isUsed }).count > 0 {
                            Text("Select the pass to validate")
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoLune")))
                        }
                    }
                }
                .frame(alignment: .bottom)
            } // VStack
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color("KentoBlueGrey"))
        } // ZStack
    } // some View
    
    var body: some View {
        
        ZStack {
            VStack {
                // Server synchronization stack
                EmptyView()
                    .onReceive(viewModel.timer) { time in
                        viewModel.participantListUpdate(
                            changedBadgeEntities: viewModel.changedBadgeEntities,
                            scanTerminal: viewModel.scanTerminal,
                            badges: viewModel.badges.flatMap( {$0.id} ),
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
                
                Divider().padding(.top)
                
                VStack {
                    // Scanner stack
                    if viewModel.isPresentingScanner {
                            self.scannerSheet
                    }
                    // List selection stack
                    if viewModel.isPresentingList {
                        TextField("Search participants", text: $viewModel.searchText)
                            .onChange(of: viewModel.searchText) { newValue in
                                viewModel.updateFilteredParticipantAllBadgesList()
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
                            .contentShape(Rectangle()) // so that empty part of line is selectable
                            .onTapGesture {
                                viewModel.selectParticipant(participant: &viewModel.filteredParticipantAllBadgesList[i])
                            }
                            .listRowBackground(Color("KentoBeige"))
                        }
                        .listStyle(.plain)
                        .background(Color("KentoBeige"))
                        
                    }
                } // VStack
                .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
                
                Spacer()
                
                Divider()
                
                // Toggle menu
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Button {
                            viewModel.setupScanView()
                            viewModel.isPresentingPhotoGallery.toggle()
                        } label: {
                            Label("Scan", systemImage: "qrcode.viewfinder")
                                .font(.title2)
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
                .frame(height: 50)
                
            } // VStack
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .edgesIgnoringSafeArea([.top, .bottom])

            
        } // ZStack
        .onAppear {
            UIApplication.shared.addTapGestureRecognizer()
            viewModel.setupScanningVariables(
                token: loginInfo.token,
                scanTerminal: scanInfo.scanTerminal!,
                badges: scanInfo.badges!,
                enrichedBadgeEntities: scanInfo.enrichedBadgeEntities!
            )
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $viewModel.isPresentingResultStack, onDismiss: viewModel.resetScannedAndInfographyVariables) {
            if #available(iOS 16, *) {
                resultStack
                    .presentationDetents([.medium])
            } else {
                resultStack
            }
        }
    } // some View
} // View

struct QRScanView_Previews: PreviewProvider {
    static var previews: some View {
        QRScanView()
    }
}
