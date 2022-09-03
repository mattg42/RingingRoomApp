////
////  CallButton.swift
////  NewRingingRoom
////
////  Created by Matthew on 14/07/2022.
////
//
//import SwiftUI
//
//struct VerticalCallButtons:View {
//    
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    
//    var size:CGFloat
//    var body: some View {
//        HStack {
//            VStack(spacing: 5) {
//                Button(action: {
//                    makeCall("Bob")
//                }) {
//                    CallButton(call: "Bob")
//                        .frame(maxWidth: size)
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//                Button(action: {
//                    makeCall("Single")
//                }) {
//                    CallButton(call: "Single")
//                        .frame(maxWidth: size)
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//                Button(action: {
//                    makeCall("That's all")
//                }) {
//                    CallButton(call: "That's all")
//                        .frame(maxWidth: size)
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//            }
//            VStack(spacing: 5.0) {
//                Button(action: {
//                    makeCall("Look to")
//                }) {
//                    CallButton(call: "Look to")
//                        .frame(maxWidth: size)
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//                Button(action: {
//                    makeCall("Go")
//                }) {
//                    CallButton(call: "Go")
//                        .frame(maxWidth: size)
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//                Button(action: {
//                    makeCall("Stand next")
//                }) {
//                    CallButton(call: "Stand")
//                        .frame(maxWidth: size)
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//            }
//        }
//    }
//    
//    func makeCall(_ call:String) {
//        viewModel.send(event: "c_call", with: ["call":call, "tower_id":viewModel.towerInfo.towerID])
//    }
//}
//
//struct HorizontalCallButtons:View {
//    
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    
//    var body: some View {
//        VStack(spacing: 5) {
//            HStack(spacing: 5) {
//                Button(action: {
//                    makeCall("Bob")
//                }) {
//                    CallButton(call: "Bob")
//                    
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//                Button(action: {
//                    makeCall("Single")
//                }) {
//                    CallButton(call: "Single")
//                    
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//                Button(action: {
//                    makeCall("That's all")
//                }) {
//                    CallButton(call: "That's all")
//                    
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//            }
//            HStack(spacing: 5.0) {
//                Button(action: {
//                    makeCall("Look to")
//                }) {
//                    CallButton(call: "Look to")
//                    
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//                Button(action: {
//                    makeCall("Go")
//                }) {
//                    CallButton(call: "Go")
//                    
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//                Button(action: {
//                    makeCall("Stand next")
//                }) {
//                    CallButton(call: "Stand")
//                    
//                }
//                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
//            }
//        }
//    }
//    
//    func makeCall(_ call:String) {
//        viewModel.send(event: "c_call", with: ["call":call, "tower_id":viewModel.towerInfo.towerID])
//    }
//}
//
//struct CallButton:View {
//    
//    var call:String
//    
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    @Environment(\.verticalSizeClass) var verticalSizeClass
//    
//    @Environment(\.colorScheme) var colorScheme
//    
//    var body: some View {
//        ZStack {
//            Color(white: colorScheme == .light ? 1 : 0.085).cornerRadius(5)
//            Text(call)
//                .foregroundColor(.primary)
//            
//        }
//        .frame(maxHeight: horizontalSizeClass == .regular ? 45 : 30)
//    }
//}
//
//struct RingButton:View {
//    
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    @Environment(\.verticalSizeClass) var verticalSizeClass
//    
//    @Environment(\.colorScheme) var colorScheme
//    
//    var number:String
//    
//    var body: some View {
//        ZStack {
//            Color(white: colorScheme == .light ? 1 : 0.085).cornerRadius(5)
//            Text(number)
//                .foregroundColor(.primary)
//                .font(horizontalSizeClass == .regular ? .largeTitle : .title3)
//                .bold()
//        }
//        .frame(maxHeight: horizontalSizeClass == .regular ? 150 : 70)
//    }
//}
