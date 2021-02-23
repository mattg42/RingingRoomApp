//
//  RingView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import Combine
import Network

struct RingView: View {
    
    //    init() {
    //         UIScrollView.appearance().bounces = false
    //    }
    
    //    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
    
    @State private var comController:CommunicationController!
    
    @State private var towerListSelection:Int = 0
    var towerLists = ["Recents", "Favourites", "Created", "Host"]
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCancelButton = Alert.Button.cancel()
    
    @ObservedObject var user = User.shared
    
    @ObservedObject var manager = SocketIOManager.shared
    
    @State private var ringingRoomView = RingingRoomView()
    
    @State var presentingRingingRoomView = false
    
    @State private var joinTowerYPosition:CGFloat = 0
    @State private var keyboardHeight:CGFloat = 0
    
    @State private var towerID = ""
    @State private var towerName = ""
    
    @State private var viewOffset:CGFloat = 0
    
    @State private var isRelevant = false
    
    @State var response = [String:Any]()
    
    @State var monitor = NWPathMonitor()
    
    @State private var buttonHeight:CGFloat = 0
    
    @State private var createTowerShowing = false
    @State private var showingTowerIDField = false
    
    var body: some View {
        //        if !BellCircle.current.ringingroomIsPresented {
        NavigationView {
            VStack(spacing: 8) {
                //            Picker("Tower list selection", selection: $towerListSelection) {
                //                ForEach(0 ..< towerLists.count) {
                //                    Text(self.towerLists[$0])
                //                }
                //            }
                //            .pickerStyle(SegmentedPickerStyle())
                HStack {
                    Text("Recent towers - tap to join").font(.headline)
                    Spacer()
                }
                ScrollView {
                    ScrollViewReader { reader in
                        VStack {
                            //                    if User.shared.myTowers[0].tower_id != 0 {
                            ForEach(User.shared.myTowers) { tower in
                                
                                if tower.tower_id != 0 {
                                    Button(action: {
                                        joinTower(id: tower.tower_id)
                                    }) {
                                        HStack() {
                                            Text(String(tower.tower_name))
                                            Spacer()
                                        }
                                    }
                                    .frame(height: 40)
                                    .padding(.horizontal)
                                    .contentShape(Rectangle())
                                    .cornerRadius(10)
                                    .id(tower.tower_id)
                                } else {
                                    /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
                                }
                            }
                            //                    }
                        }
                        //                        .onChange(of: User.shared.myTowers, perform: { value in
                        //                            reader.scrollTo(user.myTowers.first!.tower_id)
                        //                        })
                        //                        //                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name.gotMyTowers)) { _ in
                        //                        //                        reader.scrollTo(user.myTowers.last!.tower_id)
                        //                        //                    }
                        //                        .onAppear {
                        //                            reader.scrollTo(user.myTowers.first!.tower_id)
                        //                        }
                    }
                }
                .padding(.bottom, 5)
                
                Delimiter()
                
                DisclosureGroup(
                    isExpanded: $showingTowerIDField,
                    content: {
                        HStack {
                            ZStack {
                                TextField("Tower ID", text: $towerID)
                                    .disabled(!User.shared.loggedIn)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                                    .onChange(of: towerID, perform: { value in
                                        if Int(towerID) == nil || towerID.contains("0") {
                                            towerID = towerID.filter("123456789".contains)
                                        }
                                        print(towerID)
                                    })
                                if towerID.count > 0 {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            towerID = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(5)
                                }
                            }
                            GeometryReader { geo in
                                Button(action: { self.joinTower(id: Int(towerID)!) } ) {
                                    ZStack {
                                        Color.main
                                            .cornerRadius(5)
                                        Text("Join Tower")
                                            .foregroundColor(.white)
                                    }
                                }
                                .opacity(User.shared.loggedIn ? String(towerID).count != 0 ? 1 : 0.35 : 0.35)
                                .disabled((User.shared.loggedIn ? String(towerID).count != 0 ? false : true : true))
                                .onAppear(perform: {
                                    self.buttonHeight = geo.size.height

                                })
                                .alert(isPresented: self.$showingAlert) {
                                    Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: alertCancelButton)
                                }
                            }
                            

                            //                    .frame(height: 45)
                            //                    .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        .padding(.vertical, 8)
                        
                        .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/) },
                    label: { Button(action: {
                        withAnimation {
                            showingTowerIDField.toggle()
                        }
                    }) {
                        HStack {
                        Text("Enter existing tower ID").font(.headline)
                        Spacer()
                        }
                    }}
                )
                
                Delimiter()
                
                DisclosureGroup(
                    isExpanded: $createTowerShowing,
                    content: {
                        ZStack {
                            TextField("Enter name of new tower", text: $towerName).textFieldStyle(RoundedBorderTextFieldStyle())

                            if towerName.count > 0 {
                            HStack {
                                Spacer()
                                Button(action: {
                                    towerName = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(5)
                            }
                        }
                        .padding(.top, 8)
                        ZStack {
                            Button(action: self.createTower) {
                                ZStack {
                                    Color.main
                                        .cornerRadius(5)
                                    Text("Create Tower")
                                        .foregroundColor(.white)
                                }
                                .frame(height: 35)
                            }
                            .opacity(User.shared.loggedIn ? String(towerName).count != 0 ? 1 : 0.35 : 0.35)
                            .disabled((User.shared.loggedIn ? String(towerName).count != 0 ? false : true : true))
                            
                        }
                    },
                    label: { Button(action: {
                        withAnimation {
                            createTowerShowing.toggle()
                        }
                    }) {
                        HStack {
                            Text("Create new tower").font(.headline)
                            Spacer()
                        }
                    }
                    }
                )
                
            }
            .onAppear(perform: {
                self.comController = CommunicationController(sender: self)
                let queue = DispatchQueue.monitor
                monitor.start(queue: queue)
            })
            .padding()
            .navigationBarTitle("Towers")
        }
        //        } else {
        //            ringingRoomView
        //        }
        
        //        .onReceive(BellCircle.current.objectWillChange, perform: { _ in
        //
        //        })
    }
    
    func getTowerIDHeader() -> String {
        return "Enter existing tower ID"
    }
    
    func getOffset() -> CGFloat {
        let offset = keyboardHeight - joinTowerYPosition
        print("offset: ",offset)
        if offset <= 0 {
            return 0
        } else {
            return -offset
        }
    }
    
    func isID(id:Int) -> Bool {
        return String(id).count == 9
    }
    
    func createTower() {
        DispatchQueue.global(qos: .userInteractive).async {
            if monitor.currentPath.status == .satisfied {
                print("joined tower")
                
                comController.createTower(name: towerName.trimmingCharacters(in: .whitespaces))
                
                //create new tower
            } else {
                noInternetAlert()
            }
        }
    }
    
    func joinTower(id: Int) {
        DispatchQueue.global(qos: .userInteractive).async {
            if monitor.currentPath.status == .satisfied {
                print("joined tower")
                
                self.getTowerConnectionDetails(id: id)
                
                //create new tower
            } else {
                noInternetAlert()
            }
        }
        
    }
    
    func getTowerConnectionDetails(id: Int) {
        comController.getTowerDetails(id: id)
    }
    
    @State var towerInQueue = 0
    
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        if statusCode == 404 {
            noTowerAlert()
        } else if statusCode == 200 {
            //            if user.myTowers.towerForID(response["tower_id"] as! Int) == nil {
            //                self.response = response
            //                comController.getMyTowers()
            //            } else {
            BellCircle.current.towerName = response["tower_name"] as! String
            BellCircle.current.towerID = response["tower_id"] as! Int
            BellCircle.current.serverAddress = response["server_address"] as! String
            
            if let tower = user.myTowers.towerForID(BellCircle.current.towerID) {
                BellCircle.current.isHost = tower.host
                if !tower.gotSettings {
                    print("in queue")
                    towerInQueue = BellCircle.current.towerID
                } else {
                    BellCircle.current.hostModeEnabled = tower.hostModePermitted
                    print(tower.additionalSizes, "additional")
                    BellCircle.current.additionalSizes = tower.additionalSizes
                    SocketIOManager.shared.setups += 1
                }
            } else {
                BellCircle.current.needsTowerInfo = true
            }
            
            
            
            //            comController.getHostModePermitted(BellCircle.current.towerID)
            SocketIOManager.shared.connectSocket(server_ip: BellCircle.current.serverAddress)
            //            }
        } else {
            unknownErrorAlert()
        }
    }
    
    func receivedTowerSettings(id: Int) {
        if id == towerInQueue {
            let tower = User.shared.myTowers.towerForID(id)!
            BellCircle.current.hostModeEnabled = tower.hostModePermitted
            BellCircle.current.additionalSizes = tower.additionalSizes
            BellCircle.current.needsTowerInfo = false
            SocketIOManager.shared.connectSocket(server_ip: BellCircle.current.serverAddress)
        }
    }
    
    func presentRingingRoomView() {
        print("going to ringingroom view")
        comController.getMyTowers()
        AppController.shared.state = .ringing
    }
    
    func noTowerAlert() {
        alertTitle = "No tower found"
        alertMessage = "There is no tower with that ID."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
    
    func unknownErrorAlert() {
        alertTitle = "Error"
        alertMessage = "An unknown error occured."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
    
    func noInternetAlert() {
        alertTitle = "Connection error"
        alertMessage = "Your device is not connected to the internet. Please check your internet connection and try again."
        
        alertCancelButton = .cancel(Text("OK"))
        
        showingAlert = true
    }
    
}

struct Delimiter:View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary)
            .opacity(0.4)
            .frame(height: 2)
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

extension Notification.Name {
    static let gotMyTowers = Notification.Name("gotMyTowers")
}

extension DispatchQueue {
    static let monitor = DispatchQueue(label: "Monitor", qos: .background)
}


public struct TextAlert {
  public var title: String // Title of the dialog
  public var message: String // Dialog message
  public var placeholder: String = "" // Placeholder text for the TextField
  public var accept: String = "OK" // The left-most button label
  public var cancel: String? = "Cancel" // The optional cancel (right-most) button label
  public var secondaryActionTitle: String? = nil // The optional center button label
  public var keyboardType: UIKeyboardType = .default // Keyboard tzpe of the TextField
  public var action: (String?) -> Void // Triggers when either of the two buttons closes the dialog
  public var secondaryAction: (() -> Void)? = nil // Triggers when the optional center button is tapped
}

extension UIAlertController {
  convenience init(alert: TextAlert) {
    self.init(title: alert.title, message: alert.message, preferredStyle: .alert)
    addTextField {
       $0.placeholder = alert.placeholder
       $0.keyboardType = alert.keyboardType
    }
    if let cancel = alert.cancel {
      addAction(UIAlertAction(title: cancel, style: .cancel) { _ in
        alert.action(nil)
      })
    }
    if let secondaryActionTitle = alert.secondaryActionTitle {
       addAction(UIAlertAction(title: secondaryActionTitle, style: .default, handler: { _ in
         alert.secondaryAction?()
       }))
    }
    let textField = self.textFields?.first
    addAction(UIAlertAction(title: alert.accept, style: .default) { _ in
      alert.action(textField?.text)
    })
  }
}

struct AlertWrapper<Content: View>: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  let alert: TextAlert
  let content: Content

  func makeUIViewController(context: UIViewControllerRepresentableContext<AlertWrapper>) -> UIHostingController<Content> {
    UIHostingController(rootView: content)
  }

  final class Coordinator {
    var alertController: UIAlertController?
    init(_ controller: UIAlertController? = nil) {
       self.alertController = controller
    }
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }

  func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: UIViewControllerRepresentableContext<AlertWrapper>) {
    uiViewController.rootView = content
    if isPresented && uiViewController.presentedViewController == nil {
      var alert = self.alert
      alert.action = {
        self.isPresented = false
        self.alert.action($0)
      }
      context.coordinator.alertController = UIAlertController(alert: alert)
      uiViewController.present(context.coordinator.alertController!, animated: true)
    }
    if !isPresented && uiViewController.presentedViewController == context.coordinator.alertController {
      uiViewController.dismiss(animated: true)
    }
  }
}


extension View {
  public func alert(isPresented: Binding<Bool>, _ alert: TextAlert) -> some View {
    AlertWrapper(isPresented: isPresented, alert: alert, content: self)
  }
}
