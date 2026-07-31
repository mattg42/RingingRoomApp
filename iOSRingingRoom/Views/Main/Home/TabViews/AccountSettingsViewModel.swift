//
//  AccountSettingsViewModel.swift
//  NewRingingRoom
//

import Foundation
import SwiftUI

struct AccountSettingsUpdateResult {
    let user: APIModel.User
    let automaticLoginDisabled: Bool
}

struct AccountDeletionResult {
    let credentialsRemoved: Bool
}

@MainActor
final class AccountSettingsViewModel: ObservableObject {
    @Published private(set) var isRunning = false

    let apiService: any AccountAPIClient
    private let alertPresenter: any AlertPresenting

    init(
        apiService: any AccountAPIClient,
        alertPresenter: any AlertPresenting = SystemAlertPresenter()
    ) {
        self.apiService = apiService
        self.alertPresenter = alertPresenter
    }

    func updateUser(
        username: String? = nil,
        email: String? = nil,
        password: String? = nil,
        currentPassword: String
    ) async -> AccountSettingsUpdateResult? {
        guard !currentPassword.isEmpty else {
            alertPresenter.presentAlert(
                title: "Current password required",
                message: "Enter your current password to confirm this change.",
                dismiss: .cancel(title: "OK", action: nil)
            )
            return nil
        }

        isRunning = true
        defer { isRunning = false }

        do {
            try await apiService.reauthenticate(with: currentPassword)
            let updatedUser = try await apiService.updateUser(
                username: username,
                email: email,
                password: password
            )
            return AccountSettingsUpdateResult(user: updatedUser, automaticLoginDisabled: false)
        } catch let error as APIError {
            if case .credentialsNotSaved(let updatedUser) = error {
                return AccountSettingsUpdateResult(user: updatedUser, automaticLoginDisabled: true)
            }

            alertPresenter.handle(error: error)
            return nil
        } catch {
            alertPresenter.presentAlert(
                title: "Unable to update account",
                message: error.localizedDescription,
                dismiss: .cancel(title: "OK", action: nil)
            )
            return nil
        }
    }

    func deleteAccount(currentPassword: String) async -> AccountDeletionResult? {
        guard !currentPassword.isEmpty else {
            alertPresenter.presentAlert(
                title: "Current password required",
                message: "Enter your current password to confirm account deletion.",
                dismiss: .cancel(title: "OK", action: nil)
            )
            return nil
        }

        isRunning = true
        defer { isRunning = false }

        do {
            try await apiService.reauthenticate(with: currentPassword)
            _ = try await apiService.deleteUser()

            // The server has returned a successful deletion response. Only now
            // remove local credentials and clear the in-memory session.
            let cleanup = apiService.clearSession()
            return AccountDeletionResult(credentialsRemoved: cleanup.succeeded)
        } catch let error as APIError {
            alertPresenter.handle(error: error)
            return nil
        } catch {
            alertPresenter.presentAlert(
                title: "Unable to delete account",
                message: error.localizedDescription,
                dismiss: .cancel(title: "OK", action: nil)
            )
            return nil
        }
    }
}
