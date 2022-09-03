////
////  ChatView.swift
////  NewRingingRoom
////
////  Created by Matthew on 14/07/2022.
////
//
//import SwiftUI
//
//struct ChatView:View {
//    
//    @Environment(\.colorScheme) var colorScheme
//    
//    @State private var updateView = false
//    
//    //    @State private var showingChat = false {
//    //        didSet {
//    //            self.chatManager.canSeeMessages = self.showingChat
//    //            if self.showingChat == true {
//    //                self.chatManager.newMessages = 0
//    //            }
//    //            hideKeyboard()
//    //        }
//    //    }
//    
//    //    @State private var arrowDown = false
//    
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    @Environment(\.verticalSizeClass) var verticalSizeClass
//    
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    
//    @State private var currentMessage = ""
//    
//    var isSplit:Bool {
//        get {
//            !(horizontalSizeClass == .compact || (UIApplication.shared.orientation?.isPortrait ?? true))
//        }
//    }
//    
//    var body: some View {
//        VStack(spacing: 0.0) {
//            HStack(alignment: .center) {
//                Text("Chat")
//                    .font(.title3)
//                    .fontWeight(.heavy)
//                //                        .bold()
//                    .padding(.leading, 7)
//                Spacer()
//                Text("Fill In")
//                    .padding(.horizontal, 6)
//                    .padding(.vertical, 4)
//                    .lineLimit(1)
//                    .opacity(0)
//                Spacer()
//                Button(action: {
//                    viewModel.towerControlsViewSelection = .users
//                }) {
//                    Image(systemName: "chevron.left")
//                    Text("Users")
//                }
//                .foregroundColor(.main)
//            }
//            .padding(.bottom, 5)
//            //            if self.showingChat {
//            ScrollView {
//                ScrollViewReader { value in
//                    VStack(spacing: 5) {
//                        if viewModel.messages.count > 0 {
//                            ForEach(0..<viewModel.messages.count, id: \.self) { i in
//                                HStack {
//                                    (Text(viewModel.messages[i].user).bold() + Text(": \(viewModel.messages[i].message)"))
//                                        .id(i)
//                                    Spacer()
//                                }
//                                
//                                //                                      .background(Color.blue)
//                            }
//                            
//                            .onAppear {
//                                value.scrollTo(viewModel.messages.count - 1)
//                            }
//                        }
//                    }
//                }
//            }
//            .padding(.horizontal, 5)
//            .padding(.bottom, 8)
//            //                .background(Color.red)
//            HStack(alignment: .center) {
//                //                    GeometryReader { geo in
//                TextField("Message", text: self.$currentMessage, onEditingChanged: { selected in
//                    //  self.textFieldSelected = selected
//                })
//                //                        .padding(.top, -13)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .shadow(color: Color.white.opacity(0), radius: 1, x: 0, y: 0)
//                //                        .onAppear {
//                //                            let yPos = geo.frame(in: .global).maxY  + geo.frame(in: .global).height + 18
//                //                            messageFieldYPosition = UIScreen.main.bounds.height - (yPos)
//                //                        }
//                //                    }
//                //                    .fixedSize(horizontal: false, vertical: true )
//                Button("Send") {
//                    self.sendMessage()
//                }
//                .foregroundColor(Color.main)
//            }
//            .padding(.horizontal, 3)
//            .padding(.bottom, 7)
//        }
//        //        }
//        //        .ignoresSafeArea()
//        //        .edgesIgnoringSafeArea(.all)
//        .clipped()
//        .padding(.horizontal, 7)
//        .padding(.vertical, 7)
//        .background(isSplit ? Color(white: colorScheme == .light ? 1 : 0.08).cornerRadius(5) : Color(white: colorScheme == .light ? 0.94 : 0.08).cornerRadius(5))
//        .onAppear {
//            print("chat view appeared")
//        }
//    }
//    
//    func sendMessage() {
//        //send message
//        viewModel.send(event: "c_msg_sent", with: ["user":viewModel.user.username, "email":viewModel.user.email, "msg":currentMessage, "tower_id":viewModel.towerInfo.towerID])
//        currentMessage = ""
//    }
//}
