//
//  AccountSettingsViews.swift
//  NewRingingRoom
//

import SwiftUI

private struct AccountSettingsFeedback: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissAfterAcknowledgement: Bool
}

private extension View {
    func accountSettingsTextFieldStyle() -> some View {
        self
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}

struct ChangeUsernameView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var user: User
    @ObservedObject var viewModel: AccountSettingsViewModel

    @State private var username: String
    @State private var currentPassword = ""
    @State private var feedback: AccountSettingsFeedback?

    init(user: Binding<User>, viewModel: AccountSettingsViewModel) {
        self._user = user
        self.viewModel = viewModel
        self._username = State(initialValue: user.wrappedValue.username)
    }

    var body: some View {
        Form {
            Section {
                TextField("New username", text: $username)
                    .accountSettingsTextFieldStyle()
            } header: {
                Text("Username")
            } footer: {
                Text("Your username is shown to other ringers.")
            }

            Section {
                SecureField("Current password", text: $currentPassword)
                    .accountSettingsTextFieldStyle()
                    .textContentType(.password)
            } header: {
                Text("Confirm change")
            }

            Section {
                Button {
                    save()
                } label: {
                    settingsButtonLabel("Save username")
                }
                .disabled(viewModel.isRunning)
            }
        }
        .navigationTitle("Change username")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $feedback) { feedback in
            Alert(
                title: Text(feedback.title),
                message: Text(feedback.message),
                dismissButton: .default(Text("OK"), action: feedback.dismissAfterAcknowledgement ? { dismiss() } : nil)
            )
        }
    }

    @ViewBuilder
    private func settingsButtonLabel(_ title: String) -> some View {
        HStack {
            Spacer()
            if viewModel.isRunning {
                ProgressView()
            } else {
                Text(title)
            }
            Spacer()
        }
    }

    private func save() {
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedUsername.isEmpty else {
            presentValidationError(message: "Enter a username before saving.")
            return
        }
        guard normalizedUsername != user.username else {
            presentValidationError(message: "Enter a different username before saving.")
            return
        }
        guard !currentPassword.isEmpty else {
            presentValidationError(message: "Enter your current password to confirm this change.")
            return
        }

        Task { @MainActor in
            guard let result = await viewModel.updateUser(
                username: normalizedUsername,
                currentPassword: currentPassword
            ) else { return }

            apply(result.user)
            if result.automaticLoginDisabled {
                feedback = AccountSettingsFeedback(
                    title: "Username updated",
                    message: "Your username was updated, but automatic login was disabled because the new credentials could not be saved.",
                    dismissAfterAcknowledgement: false
                )
            } else {
                feedback = AccountSettingsFeedback(
                    title: "Username updated",
                    message: "Your username has been updated.",
                    dismissAfterAcknowledgement: true
                )
            }
        }
    }

    private func apply(_ serverUser: APIModel.User) {
        user.username = serverUser.username
        user.email = serverUser.email
    }

    private func presentValidationError(message: String) {
        AlertHandler.presentAlert(title: "Unable to save username", message: message, dismiss: .cancel(title: "OK", action: nil))
    }
}

struct ChangeEmailView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var user: User
    @ObservedObject var viewModel: AccountSettingsViewModel

    @State private var email: String
    @State private var currentPassword = ""
    @State private var feedback: AccountSettingsFeedback?

    init(user: Binding<User>, viewModel: AccountSettingsViewModel) {
        self._user = user
        self.viewModel = viewModel
        self._email = State(initialValue: user.wrappedValue.email)
    }

    var body: some View {
        Form {
            Section {
                TextField("New email", text: $email)
                    .accountSettingsTextFieldStyle()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
            } header: {
                Text("Email")
            } footer: {
                Text("Use an email address you can access. It is used for future logins and password resets.")
            }

            Section {
                SecureField("Current password", text: $currentPassword)
                    .accountSettingsTextFieldStyle()
                    .textContentType(.password)
            } header: {
                Text("Confirm change")
            }

            Section {
                Button {
                    save()
                } label: {
                    settingsButtonLabel("Save email")
                }
                .disabled(viewModel.isRunning)
            }
        }
        .navigationTitle("Change email")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $feedback) { feedback in
            Alert(
                title: Text(feedback.title),
                message: Text(feedback.message),
                dismissButton: .default(Text("OK"), action: feedback.dismissAfterAcknowledgement ? { dismiss() } : nil)
            )
        }
    }

    @ViewBuilder
    private func settingsButtonLabel(_ title: String) -> some View {
        HStack {
            Spacer()
            if viewModel.isRunning {
                ProgressView()
            } else {
                Text(title)
            }
            Spacer()
        }
    }

    private func save() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail.isValidEmail() else {
            presentValidationError(message: "Enter a valid email address.")
            return
        }
        guard normalizedEmail != user.email else {
            presentValidationError(message: "Enter a different email address before saving.")
            return
        }
        guard !currentPassword.isEmpty else {
            presentValidationError(message: "Enter your current password to confirm this change.")
            return
        }

        Task { @MainActor in
            guard let result = await viewModel.updateUser(
                email: normalizedEmail,
                currentPassword: currentPassword
            ) else { return }

            apply(result.user)
            if result.automaticLoginDisabled {
                feedback = AccountSettingsFeedback(
                    title: "Email updated",
                    message: "Your email was updated, but automatic login was disabled because the new credentials could not be saved.",
                    dismissAfterAcknowledgement: false
                )
            } else {
                feedback = AccountSettingsFeedback(
                    title: "Email updated",
                    message: "Your email has been updated.",
                    dismissAfterAcknowledgement: true
                )
            }
        }
    }

    private func apply(_ serverUser: APIModel.User) {
        user.username = serverUser.username
        user.email = serverUser.email
    }

    private func presentValidationError(message: String) {
        AlertHandler.presentAlert(title: "Unable to save email", message: message, dismiss: .cancel(title: "OK", action: nil))
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var user: User
    @ObservedObject var viewModel: AccountSettingsViewModel

    @State private var newPassword = ""
    @State private var repeatedPassword = ""
    @State private var currentPassword = ""
    @State private var feedback: AccountSettingsFeedback?

    var body: some View {
        Form {
            Section {
                SecureField("New password", text: $newPassword)
                    .accountSettingsTextFieldStyle()
                    .textContentType(.newPassword)
                SecureField("Repeat new password", text: $repeatedPassword)
                    .accountSettingsTextFieldStyle()
                    .textContentType(.newPassword)
            } header: {
                Text("New password")
            } footer: {
                Text("Enter the new password twice so it can be checked before it is sent.")
            }

            Section {
                SecureField("Current password", text: $currentPassword)
                    .accountSettingsTextFieldStyle()
                    .textContentType(.password)
            } header: {
                Text("Confirm change")
            }

            Section {
                Button {
                    save()
                } label: {
                    settingsButtonLabel("Save password")
                }
                .disabled(viewModel.isRunning)
            }
        }
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $feedback) { feedback in
            Alert(
                title: Text(feedback.title),
                message: Text(feedback.message),
                dismissButton: .default(Text("OK"), action: feedback.dismissAfterAcknowledgement ? { dismiss() } : nil)
            )
        }
    }

    @ViewBuilder
    private func settingsButtonLabel(_ title: String) -> some View {
        HStack {
            Spacer()
            if viewModel.isRunning {
                ProgressView()
            } else {
                Text(title)
            }
            Spacer()
        }
    }

    private func save() {
        guard !newPassword.isEmpty else {
            presentValidationError(message: "Enter a new password.")
            return
        }
        guard newPassword == repeatedPassword else {
            presentValidationError(message: "The new passwords do not match.")
            return
        }
        guard !currentPassword.isEmpty else {
            presentValidationError(message: "Enter your current password to confirm this change.")
            return
        }

        Task { @MainActor in
            guard let result = await viewModel.updateUser(
                password: newPassword,
                currentPassword: currentPassword
            ) else { return }

            apply(result.user)
            if result.automaticLoginDisabled {
                feedback = AccountSettingsFeedback(
                    title: "Password updated",
                    message: "Your password was updated, but automatic login was disabled because the new credentials could not be saved.",
                    dismissAfterAcknowledgement: false
                )
            } else {
                feedback = AccountSettingsFeedback(
                    title: "Password updated",
                    message: "Your password has been updated.",
                    dismissAfterAcknowledgement: true
                )
            }
        }
    }

    private func apply(_ serverUser: APIModel.User) {
        user.username = serverUser.username
        user.email = serverUser.email
    }

    private func presentValidationError(message: String) {
        AlertHandler.presentAlert(title: "Unable to save password", message: message, dismiss: .cancel(title: "OK", action: nil))
    }
}

struct DeleteAccountView: View {
    @EnvironmentObject private var router: Router<AppRoute>
    @ObservedObject var viewModel: AccountSettingsViewModel

    @State private var currentPassword = ""
    @State private var showingConfirmation = false

    var body: some View {
        Form {
            Section {
                Text("Deleting your account is permanent. You will lose access to this account and its relationships with towers. The server deletes your user and those relationships, but it does not explicitly delete every tower you created.")
                    .foregroundColor(.primary)
            } header: {
                Text("Permanent deletion")
            }

            Section {
                SecureField("Current password", text: $currentPassword)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.password)
            } header: {
                Text("Confirm ownership")
            } footer: {
                Text("Your current password is required before the account can be deleted.")
            }

            Section {
                Button {
                    requestDeletion()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isRunning {
                            ProgressView()
                        } else {
                            Text("Delete account")
                        }
                        Spacer()
                    }
                }
                .foregroundColor(.red)
                .disabled(viewModel.isRunning || currentPassword.isEmpty)
            }
        }
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingConfirmation) {
            Alert(
                title: Text("Delete account permanently?"),
                message: Text("This cannot be undone. Delete your account and its tower relationships?"),
                primaryButton: .destructive(Text("Delete")) {
                    Task { @MainActor in
                        await deleteAccount()
                    }
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }

    private func requestDeletion() {
        guard !currentPassword.isEmpty else {
            AlertHandler.presentAlert(
                title: "Current password required",
                message: "Enter your current password before continuing.",
                dismiss: .cancel(title: "OK", action: nil)
            )
            return
        }
        showingConfirmation = true
    }

    private func deleteAccount() async {
        guard let result = await viewModel.deleteAccount(currentPassword: currentPassword) else { return }

        router.moveTo(.login)

        let message: String
        if result.credentialsRemoved {
            message = "Your account and local login information have been deleted."
        } else {
            message = "Your account was deleted, but some local login information could not be removed. Automatic login has been disabled; please remove any remaining Ringing Room credentials from Keychain if prompted."
        }

        DispatchQueue.main.async {
            AlertHandler.presentAlert(
                title: "Account deleted",
                message: message,
                dismiss: .cancel(title: "OK", action: nil)
            )
        }
    }
}
