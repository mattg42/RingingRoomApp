//
//  RingingView.swift
//  NewRingingRoom
//
//  Created by Matthew on 14/07/2022.
//

import SwiftUI

struct RingingView:View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isSplit:Bool {
        get {
            !(horizontalSizeClass == .compact || (UIApplication.shared.orientation?.isPortrait ?? true))
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            RopeCircle()
            Spacer()
            
            if UIApplication.shared.orientation?.isPortrait ?? true {
                if horizontalSizeClass == .compact {
                    if viewModel.assignments.contains(viewModel.ringer) {
                        HStack(spacing: 5.0) {
                            ForEach(0..<viewModel.size, id: \.self) { i in
                                if viewModel.assignments[viewModel.size-1-i] == viewModel.ringer {
                                    Button(action: {
                                        viewModel.ringBell(number: viewModel.size-i)
                                    }) {
                                        RingButton(number: String(viewModel.size-i))
                                    }
                                    .buttonStyle(TouchDown(isAvailable: true, callButton:false))
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                        
                    }
                    HorizontalCallButtons()
                        .disabled(!canCall())
                        .opacity(canCall() ? 1 : 0.35)
                        .padding(.horizontal, 5)
                        .padding(.bottom, 5)
                
                } else {
                    HorizontalCallButtons()
                        .disabled(!canCall())
                        .opacity(canCall() ? 1 : 0.35)
                        .padding(.horizontal, 5)
                        .padding(.bottom, 5)
                    if viewModel.assignments.contains(viewModel.ringer) {
                        HStack(spacing: 5.0) {
                            ForEach(0..<viewModel.size, id: \.self) { i in
                                if viewModel.assignments[viewModel.size-1-i] == viewModel.ringer {
                                    Button(action: {
                                        viewModel.ringBell(number: viewModel.size-i)
                                    }) {
                                        RingButton(number: String(viewModel.size-i))
                                    }
                                    .buttonStyle(TouchDown(isAvailable: true, callButton:false))
                                }
                            }
                        }
                        .padding(.horizontal, 5)

                    }
                }
            } else {
                if viewModel.assignments.contains(viewModel.ringer) {
                    HStack(alignment: .bottom, spacing: 5.0) {
                        VerticalCallButtons(size: .infinity)
                            .frame(width: 310)
                            .disabled(!canCall())
                            .opacity(canCall() ? 1 : 0.35)

                        ForEach(0..<viewModel.size, id: \.self) { i in
                            if viewModel.assignments[viewModel.size-1-i] == viewModel.ringer {
                                Button(action: {
                                    viewModel.ringBell(number: viewModel.size-i)
                                }) {
                                    RingButton(number: String(viewModel.size-i))
                                }
                                .buttonStyle(TouchDown(isAvailable: true, callButton:false))
                            }
                        }
                        //                        .padding(.vertical, 5)
                        .padding(.top, 5)
                        //                        .padding(.bottom, -5)
                    }

                    .frame(height: 150)

                    .padding(.horizontal, 5)

                } else {
                    VerticalCallButtons(size: .infinity)
                        .disabled(!canCall())
                        .opacity(canCall() ? 1 : 0.35)
                        .padding(.horizontal, 5)
                        .padding(.bottom, -5)
                        .frame(height: 150)
                }
            }
        }
    }
    
    func makeCall(_ call:String) {
        viewModel.send(event: "c_call", with: ["call": call, "tower_id": viewModel.towerInfo.towerID])
    }
    
    func canCall() -> Bool {
        if viewModel.towerInfo.isHost {
            return true
        } else if viewModel.hostMode {
            if viewModel.assignments.contains(viewModel.ringer) {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
}

struct TouchDown: PrimitiveButtonStyle {
    
    @Environment(\.scenePhase) var scenePhase
    
    var isAvailable:Bool
    
    @State var opacity:Double = 1
    @State var disabled = false
    
    @State var timer:Timer? = nil
    
    var callButton:Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .gesture(
                DragGesture()
                    .onChanged({ gesture in
                        let distance = sqrt(pow(gesture.translation.width, 2) + pow(gesture.translation.height, 2))
                        print("gesture",    gesture.translation, distance)
                        if distance > 2 {
                            timer?.invalidate()
                        }
                    })
            )
            .onLongPressGesture(
                minimumDuration: 20,
                pressing: { isPressed in
                    if isPressed {
                        if callButton {
                            pressed(config: configuration)
                        } else {
                            configuration.trigger()
                            opacity = 0.35
                            withAnimation(.linear(duration: 0.25)) {
                                opacity = 1
                            }
                            disabled = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                disabled = false
                            }
                        }
                    }
                    
                },
                perform: {
                    //                    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in
                    //                        configuration.trigger()
                    //                        opacity = 0.35
                    //                        withAnimation(.linear(duration: 0.25)) {
                    //                            opacity = 1
                    //                        }
                    //                        disabled = true
                    //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    //                            disabled = false
                    //                        }
                    //                    })
                    
                }
            )
            .opacity(isAvailable ? opacity : 0.35)
            .disabled(isAvailable ? disabled : true)
            .onChange(of: scenePhase, perform: { phase in
                if phase != .active {
                    timer?.invalidate()
                }
            })
    }
    
    func pressed(config: Configuration) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: false, block: { _ in
            config.trigger()
            opacity = 0.35
            withAnimation(.linear(duration: 0.25)) {
                opacity = 1
            }
            disabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                disabled = false
            }
        })
    }
}
