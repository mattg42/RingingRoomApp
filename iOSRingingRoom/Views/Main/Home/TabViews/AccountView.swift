//
//  AccountView.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI

struct AccountView: View {
    @EnvironmentObject var router: Router<AppRoute>

    @Binding var user: User
    let apiService: APIService

    @StateObject private var viewModel: AccountSettingsViewModel

    init(user: Binding<User>, apiService: APIService) {
        self._user = user
        self.apiService = apiService
        self._viewModel = StateObject(wrappedValue: AccountSettingsViewModel(apiService: apiService))
    }

    var body: some View {
        NavigationView {
            Form {
                    Section {
                        NavigationLink {
                            ChangeUsernameView(user: $user, viewModel: viewModel)
                        } label: {
                            accountRow(title: "Username", value: user.username)
                        }

                        NavigationLink {
                            ChangeEmailView(user: $user, viewModel: viewModel)
                        } label: {
                            accountRow(title: "Email", value: user.email)
                        }

                        NavigationLink("Change password") {
                            ChangePasswordView(user: $user, viewModel: viewModel)
                        }
                    } header: {
                        Text("Account")
                    }

                    Section {
                        Toggle("Auto-rotate bell circle", isOn: Binding(get: {
                            UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
                        }, set: {
                            UserDefaults.standard.set($0, forKey: "autoRotate")
                        }))
                        .toggleStyle(SwitchToggleStyle(tint: .main))
                    } header: {
                        Text("Preferences")
                    }

                    Section {
                        NavigationLink("About") {
                            AboutView()
                        }
                    }

                    Section {
                        Link("Visit the Ringing Room store", destination: URL(string: "https://www.redbubble.com/people/ringingroom/shop")!)
                    }

                    Section {
                        Button {
                            AlertHandler.presentAlert(title: "Are you sure you want to log out?", message: nil, dismiss: .logout(action: logout))
                        } label: {
                            HStack {
                                Spacer()
                                Text("Log out")
                                Spacer()
                            }
                        }
                    }

                    Section {
                        NavigationLink {
                            DeleteAccountView(viewModel: viewModel)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete account")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
            }
            .navigationBarTitle("Account")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private func accountRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    private func logout() {
        apiService.clearSession()
        router.moveTo(.login)
    }
}
