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
    
    @State private var ringingRoomView = RingingRoomView()
    
    @State var presentingRingingRoomView = false
    
    @State private var joinTowerYPosition:CGFloat = 0
    @State private var keyboardHeight:CGFloat = 0
    
    @State private var viewOffset:CGFloat = 0
    
    @State private var isRelevant = false
    
    @State var sink:AnyCancellable!
    
    @State var response = [String:Any]()
    
    @State var monitor = NWPathMonitor()
    
    var body: some View {
//        if !BellCircle.current.ringingroomIsPresented {
            VStack(spacing: 20) {
    //            Picker("Tower list selection", selection: $towerListSelection) {
    //                ForEach(0 ..< towerLists.count) {
    //                    Text(self.towerLists[$0])
    //                }
    //            }
    //            .pickerStyle(SegmentedPickerStyle())
                ScrollView {
                    ScrollViewReader { reader in
                        VStack {
        //                    if User.shared.myTowers[0].tower_id != 0 {
                                ForEach(User.shared.myTowers) { tower in

                                    if tower.tower_id != 0 {
                                        Button(action: {
                                            User.shared.towerID = String(tower.tower_id)
                                            UserDefaults.standard.set(String(tower.tower_id), forKey: "\(User.shared.email)savedTower")
                                        }) {
                                            HStack() {
                                                Text(String(tower.tower_name))
                                                .fontWeight((String(tower.tower_id) == User.shared.towerID) ? Font.Weight.bold : nil)
                                                Spacer()
                                            }
                                            .foregroundColor((String(tower.tower_id) == User.shared.towerID) ? .main : Color.primary)
                                        }
                                        .frame(height: 40)
                                        .padding(.horizontal)
                                        .buttonStyle(CustomButtonStyle())
                                        .cornerRadius(10)
                                        .id(tower.tower_id)
                                    } else {
                                        /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
                                    }
                                }
        //                    }
                        }
                        .onChange(of: User.shared.myTowers, perform: { value in
                            reader.scrollTo(user.myTowers.last!.tower_id)
                        })
    //                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name.gotMyTowers)) { _ in
    //                        reader.scrollTo(user.myTowers.last!.tower_id)
    //                    }
                        .onAppear {
                            reader.scrollTo(user.myTowers.last!.tower_id)
                        }
                    }
                }
                TextField("Tower name or id", text: .init(
                            get: {
                                User.shared.towerID
                            },
                            set: {
                                UserDefaults.standard.set($0, forKey: "\(User.shared.email)savedTower")
                                User.shared.towerID = $0
                            }))
                        .disabled(!User.shared.loggedIn)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                    .padding(.vertical, -10)
                GeometryReader { geo in
                    Button(action: self.joinTower) {
                        ZStack {
                            Color.main
                                .cornerRadius(5)
                            Text(!User.shared.loggedIn ? "Please log in to join or create a tower" : self.isID(str: User.shared.towerID) ? "Join Tower" : "Create Tower")
                                .foregroundColor(.white)
                        }
                    }
                    .opacity(User.shared.loggedIn ? User.shared.towerID.count != 0 ? 1 : 0.35 : 0.35)
                    .disabled((User.shared.loggedIn ? User.shared.towerID.count != 0 ? false : true : true))
                    .onAppear(perform: {
                        var pos = geo.frame(in: .global).midY
                        pos += geo.frame(in: .global).height/2 + 10
                        print("pos", pos)
                        pos = UIScreen.main.bounds.height - pos
                        self.joinTowerYPosition = pos
                    })
                        .alert(isPresented: self.$showingAlert) {
                            Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: alertCancelButton)
                    }
                }
                .padding(.bottom, -5)
                .frame(height: 45)
                .fixedSize(horizontal: false, vertical: true)
                
            }
            .onAppear(perform: {
                self.comController = CommunicationController(sender: self)
                let queue = DispatchQueue.monitor
                monitor.start(queue: queue)
                sink = BellCircle.current.setupPublisher.sink { _ in
                    print("received combine")
                    if !BellCircle.current.ringingroomIsPresented {
                        print("checked values")
                        for (key, value) in BellCircle.current.setupComplete {
                            print(key, value)
                            if !value {
                                return
                            }
                        }
                        self.presentRingingRoomView()
                    }
                }
            })
            .padding()
//        } else {
//            ringingRoomView
//        }

//        .onReceive(BellCircle.current.objectWillChange, perform: { _ in
//            
//        })
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
    
    func isID(str:String) -> Bool {
        if str.count == 9 {
            if Int(str) != nil {
                return true
            }
        }
        return false
    }
    
    func joinTower() {
        DispatchQueue.global(qos: .userInteractive).async {
        if monitor.currentPath.status == .satisfied {
            print("joined tower")

            if isID(str: User.shared.towerID) {
                self.getTowerConnectionDetails()
                return
            }

            //create new tower
            comController.createTower(name: User.shared.towerID)
        } else {
            noInternetAlert()
        }
        }
        
    }
    
    func getTowerConnectionDetails() {
        comController.getTowerDetails(id: Int(User.shared.towerID)!)
    }
    
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
                BellCircle.current.isHost = user.myTowers.towerForID(response["tower_id"] as! Int)?.host ?? false
                
    //            comController.getHostModePermitted(BellCircle.current.towerID)
                SocketIOManager.shared.connectSocket(server_ip: response["server_address"] as! String)
//            }
        } else {
            unknownErrorAlert()
        }
    }
    
    func updatedMyTowers() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("gotMyTowers"), object: nil)
        }
    }
    
    func presentRingingRoomView() {
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
        
        alertCancelButton = .cancel(Text("Try again."), action: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: joinTower)
        })

        showingAlert = true
    }
    
}

struct CustomButtonStyle:ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .opacity(1)
        .contentShape(Rectangle())
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
