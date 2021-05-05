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
    
//    @State private var comController:CommunicationController!
    
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
    
    var monitor = NetworkStatus.shared.monitor

    @State private var buttonHeight:CGFloat = 0
    
    @State private var createTowerShowing = false
    @State private var showingTowerIDField = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                //            Picker("Tower list selection", selection: $towerListSelection) {
                //                ForEach(0 ..< towerLists.count) {
                //                    Text(self.towerLists[$0])
                //                }
                //            }
                //            .pickerStyle(SegmentedPickerStyle())
                HStack {
                    Text("(No tower management in this version)")
                    Spacer()
                }.padding(.top, -20)
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
                                .opacity(User.shared.loggedIn ? String(towerID).count == 9 ? 1 : 0.35 : 0.35)
                                .disabled((User.shared.loggedIn ? String(towerID).count == 9 ? false : true : true))
                                .onAppear(perform: {
                                    self.buttonHeight = geo.size.height
                                    
                                })
                                
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
                            Text("Join tower by ID").font(.headline)
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
                        .padding(.bottom,6)
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
                )                    .padding(.bottom, 9)

                
            }
            .alert(isPresented: self.$showingAlert) {
                Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: alertCancelButton)
            }
            
            .padding([.horizontal, .top])
            .navigationBarTitle("Towers")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onOpenURL(perform: { url in
            var pathComponents = url.pathComponents.dropFirst()
            if let firstPath = pathComponents.first {
                if let towerID = Int(firstPath) {
                    if NetworkManager.token != nil {
                        joinTower(id: towerID)
                    }
                }
            }
            print("opened from \(url.pathComponents.dropFirst())")
        })
    }
        
    func getTowerIDHeader() -> String {
        return "Join tower by ID"
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
            if monitor?.currentPath.status == .satisfied {
                print("joined tower")
                
//                comController.createTower(name: towerName.trimmingCharacters(in: .whitespaces))
                NetworkManager.sendRequest(request: .createTower(name: towerName.trimmingCharacters(in: .whitespaces))) { (json, response, error) in
                    if let json = json {
                        receivedResponse(statusCode: response?.statusCode, response: json)
                    }
                }
            } else {
                noInternetAlert()
            }
        }
    }
    
    func joinTower(id: Int) {
        SocketIOManager.shared.socket?.disconnect()
        DispatchQueue.global(qos: .userInteractive).async {
            if monitor?.currentPath.status == .satisfied {
                print("joined tower")
                self.getTowerConnectionDetails(id: id)
                
                //create new tower
            } else {
                noInternetAlert()
            }
        }
        
    }
    
    func getTowerConnectionDetails(id: Int) {
//        comController.getTowerDetails(id: id)
        NetworkManager.sendRequest(request: .getTowerDetails(id: id)) { (json, response, error) in
            if let json = json {
                receivedResponse(statusCode: response?.statusCode, response: json)
            }
        }
    }
        
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        print("received")
        if statusCode ?? 0 == 404 {
            noTowerAlert()
        } else if statusCode ?? 0 == 401 {
            unauthorisedAlert()
        } else if statusCode ?? 0 == 200 {
            BellCircle.current.towerName = response["tower_name"] as! String
            BellCircle.current.towerID = response["tower_id"] as! Int
            BellCircle.current.serverAddress = response["server_address"] as! String
            BellCircle.current.additionalSizes = response["additional_sizes_enabled"] as? Bool ?? false
            BellCircle.current.hostModePermitted = response["host_mode_permitted"] as? Bool ?? false
            BellCircle.current.halfMuffled = response["half_muffled"] as? Bool ?? false
            
            DispatchQueue.main.async {
                BellCircle.current.hostModeEnabled = false
            }
            
            if let tower = user.myTowers.towerForID(BellCircle.current.towerID) {
                DispatchQueue.main.async {
                    BellCircle.current.isHost = tower.host
                }
            } else {
                BellCircle.current.needsTowerInfo = true
            }
            
            BellCircle.current.joinedTowers.append(BellCircle.current.towerID)
            
            SocketIOManager.shared.setups = 0
            SocketIOManager.shared.connectSocket(server_ip: BellCircle.current.serverAddress)
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                if !BellCircle.current.joinedTowers.contains(response["tower_id"] as! Int) {
                    if !showingAlert {
                        socketFailedAlert()
                    }
                } else {
                    BellCircle.current.joinedTowers.removeFirstInstance(of: response["tower_id"] as! Int)
                }
            }
            //            }
        } else {
            unknownErrorAlert()
        }
    }
    
    func presentRingingRoomView() {
        print("going to ringingroom view")
//        comController.getMyTowers()
        AppController.shared.state = .ringing
    }
    
    func socketFailedAlert() {
        alertTitle = "Failed to connect socket"
        alertMessage = "Please try and join the tower again. If the problem persists, restart the app."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
    
    func unauthorisedAlert() {
        alertTitle = "Invalid token"
        alertMessage = "Please restart the app."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
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




struct TextFieldAlert: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    
    var title: String
    var message: String?
    
    var dismissAction: (String?) -> ()
    var isSecure: Bool
    var setting: UserSetting? = nil
    
    typealias UIViewControllerType = TextFieldAlertViewController
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        TextFieldAlertViewController(title: title, message: message, isPresented: $isPresented, dismissAction: dismissAction, setting: setting, isSecure: isSecure)
    }
    
    func updateUIViewController(_ textAlertViewController: UIViewControllerType,
                                context: Context) {
        if isPresented == true {
            textAlertViewController.presentAlertController()
        }
    }
}

extension View {
  func textFieldAlert(content: TextFieldAlert) -> some View {
    ZStack(alignment: .leading) {
        self
        content
    }
  }
}

class TextFieldAlertViewController: UIViewController {

    /// Presents a UIAlertController (alert style) with a UITextField and a `Done` button
    /// - Parameters:
    ///   - title: to be used as title of the UIAlertController
    ///   - message: to be used as optional message of the UIAlertController
    ///   - text: binding for the text typed into the UITextField
    ///   - isPresented: binding to be set to false when the alert is dismissed (`Done` button tapped)
    init(title: String, message: String?, isPresented: Binding<Bool>, dismissAction: @escaping ((String?) -> ()), setting:UserSetting?, isSecure:Bool) {
        self.alertTitle = title
        self.message = message
        self._isPresented = isPresented
        self.dismissAction = dismissAction
        self.setting = setting
        self.isSecure = isSecure
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Dependencies
    private let alertTitle: String
    private let message: String?
    @Binding private var isPresented: Bool
    private let dismissAction: (String?) -> ()
    private let setting:UserSetting?
    private let isSecure:Bool

    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func presentAlertController() {
        let vc = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)

        // add a textField and create a subscription to update the `text` binding
        vc.addTextField { [weak self] textField in
            guard let self = self else { return }

            textField.clearButtonMode = .always
            switch self.setting {
            case .email:
//                textField.textContentType = .emailAddress
                textField.placeholder = "New email"
                textField.keyboardType = .emailAddress
            case .password:
                textField.placeholder = "New password"
                textField.textContentType = .newPassword
                textField.isSecureTextEntry = true
            case .username:
                textField.placeholder = "New username"
            default:
                break
            }
            textField.isSecureTextEntry = self.isSecure
        }
        
        if setting == .email {
            vc.addTextField { [weak self] textField in
                textField.placeholder = "Enter your password to confirm"
                textField.isSecureTextEntry = true
                textField.textContentType = .password
            }
        }
        
        
        // create a `Done` action that updates the `isPresented` binding when tapped
        // this is just for Demo only but we should really inject
        // an array of buttons (with their title, style and tap handler)
        let action = UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.dismissAction(vc.textFields?.first!.text)
            self?.isPresented = false
        }
        vc.addAction(action)
        present(vc, animated: true, completion: nil)
    }
}

extension Array where Element == Int {
    
    mutating func removeFirstInstance(of element:Int) {
        for (index, ele) in self.enumerated() {
            if ele == element {
                self.remove(at: index)
                return
            }
        }
    }
    
}
