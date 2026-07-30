//
//  SessionCredentialStore.swift
//  NewRingingRoom
//

import Foundation

@MainActor
final class SessionCredentialStore {
    struct StoredCredentials {
        let credentials: SessionCredentials
        let keychainAccount: String
    }

    struct CleanupResult {
        let failures: [Error]

        var succeeded: Bool {
            failures.isEmpty
        }
    }

    static let standard = SessionCredentialStore()

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var keepMeLoggedIn: Bool {
        userDefaults.bool(forKey: UserDefaults.Keys.keepMeLoggedIn)
    }

    func load(for server: String) throws -> StoredCredentials? {
        guard let storedEmail = userDefaults.string(forKey: UserDefaults.Keys.userEmail) else {
            return nil
        }

        let accounts = accountAliases(for: [storedEmail] + storedAliases.map { Optional($0) })
        for account in accounts {
            do {
                let password = try KeychainService.getPasswordFor(account: account, server: server)
                return StoredCredentials(
                    credentials: SessionCredentials(email: storedEmail, password: password),
                    keychainAccount: account
                )
            } catch let error as KeychainError {
                guard case .itemNotFound = error else { throw error }
            }
        }

        throw KeychainError.itemNotFound
    }

    func persistLogin(credentials: SessionCredentials, keepMeLoggedIn: Bool, server: String) throws {
        let previousAccounts = accountAliases(
            for: [userDefaults.string(forKey: UserDefaults.Keys.userEmail)] + storedAliases.map { Optional($0) }
        )

        if keepMeLoggedIn {
            // Store the replacement before removing any aliases for the old email.
            try KeychainService.storePasswordFor(
                account: credentials.email,
                password: credentials.password,
                server: server
            )

            userDefaults.set(true, forKey: UserDefaults.Keys.keepMeLoggedIn)
            userDefaults.set(credentials.email, forKey: UserDefaults.Keys.userEmail)
            userDefaults.set(accountAliases(for: [credentials.email]), forKey: UserDefaults.Keys.userEmailAliases)

            let oldAccounts = previousAccounts.filter { $0 != credentials.email }
            let failures = delete(accounts: oldAccounts, servers: allServers)
            if !failures.isEmpty {
                throw SessionCredentialStoreError.cleanupFailed
            }
        } else {
            let accounts = accountAliases(for: previousAccounts + [credentials.email])
            let failures = delete(accounts: accounts, servers: allServers)

            userDefaults.removeObject(forKey: UserDefaults.Keys.userEmail)
            userDefaults.removeObject(forKey: UserDefaults.Keys.userEmailAliases)
            userDefaults.set(false, forKey: UserDefaults.Keys.keepMeLoggedIn)

            if !failures.isEmpty {
                throw SessionCredentialStoreError.cleanupFailed
            }
        }
    }

    func updateCredentials(from old: SessionCredentials, to new: SessionCredentials, server: String) throws {
        guard keepMeLoggedIn else { return }

        let oldAccounts = accountAliases(
            for: [old.email, userDefaults.string(forKey: UserDefaults.Keys.userEmail)] + storedAliases.map { Optional($0) }
        )

        // This ordering matters when the email changes: the new alias must exist
        // before the old alias is removed.
        try KeychainService.storePasswordFor(
            account: new.email,
            password: new.password,
            server: server
        )

        userDefaults.set(true, forKey: UserDefaults.Keys.keepMeLoggedIn)
        userDefaults.set(new.email, forKey: UserDefaults.Keys.userEmail)
        userDefaults.set(
            accountAliases(for: [old.email, new.email] + storedAliases.map { Optional($0) }),
            forKey: UserDefaults.Keys.userEmailAliases
        )

        let accountsToDelete = oldAccounts.filter { !$0.isEmpty && $0 != new.email }
        let failures = delete(accounts: accountsToDelete, servers: allServers)
        if !failures.isEmpty {
            throw SessionCredentialStoreError.cleanupFailed
        }
    }

    func disableAutomaticLogin() {
        userDefaults.removeObject(forKey: UserDefaults.Keys.userEmail)
        // Keep the alias list until the next explicit logout/deletion so a
        // later cleanup can still remove credentials written before a failure.
        userDefaults.set(false, forKey: UserDefaults.Keys.keepMeLoggedIn)
    }

    @discardableResult
    func clear(currentEmail: String? = nil) -> CleanupResult {
        let accounts = accountAliases(
            for: [currentEmail, userDefaults.string(forKey: UserDefaults.Keys.userEmail)] + storedAliases.map { Optional($0) }
        )
        let result = CleanupResult(failures: delete(accounts: accounts, servers: allServers))

        userDefaults.removeObject(forKey: UserDefaults.Keys.userEmail)
        userDefaults.removeObject(forKey: UserDefaults.Keys.userEmailAliases)
        userDefaults.set(false, forKey: UserDefaults.Keys.keepMeLoggedIn)

        if !result.succeeded {
            AppLogger.storage.error("Failed to remove one or more saved session credentials")
        }

        return result
    }

    private var storedAliases: [String] {
        userDefaults.array(forKey: UserDefaults.Keys.userEmailAliases) as? [String] ?? []
    }

    private var allServers: [String] {
        Region.allCases.map { "\($0.server)ringingroom.com" }
    }

    private func accountAliases(for emails: [String?]) -> [String] {
        var aliases: [String] = []

        for email in emails.compactMap({ $0 }) {
            let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            for alias in [email, trimmed, trimmed.lowercased()] where !alias.isEmpty && !aliases.contains(alias) {
                aliases.append(alias)
            }
        }

        return aliases
    }

    private func delete(accounts: [String], servers: [String]) -> [Error] {
        var failures: [Error] = []

        for account in Set(accounts) where !account.isEmpty {
            for server in Set(servers) {
                do {
                    try KeychainService.deletePasswordFor(account: account, server: server)
                } catch {
                    failures.append(error)
                }
            }
        }

        return failures
    }
}

enum SessionCredentialStoreError: Error {
    case cleanupFailed
}
