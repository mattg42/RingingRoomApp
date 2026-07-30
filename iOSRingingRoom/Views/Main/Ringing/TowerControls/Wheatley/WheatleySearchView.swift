//
//  WheatleySearchView.swift
//  Ringing Room
//
//  Created by Matthew on 17/11/2023.
//

import SwiftUI

private struct MethodSearchRequest: Hashable {
    let query: String
    let stage: Int
}

enum WheatleyError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case invalidMethodPayload
    case invalidCompositionPayload
    case invalidCallInterval
    case invalidCompositionURL
    case invalidCompositionHost
    case invalidCompositionPath
    case emptyCompositionID

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Wheatley request URL was invalid."
        case .invalidResponse:
            return "Wheatley returned an invalid response."
        case .httpStatus(let status):
            return "The Wheatley server returned HTTP status \(status)."
        case .invalidMethodPayload:
            return "The method response was missing required data."
        case .invalidCompositionPayload:
            return "The composition response was missing required data."
        case .invalidCallInterval:
            return "The method response contained an invalid call interval."
        case .invalidCompositionURL:
            return "Enter a Complib composition ID or a complib.org composition URL."
        case .invalidCompositionHost:
            return "The URL must point exactly to complib.org."
        case .invalidCompositionPath:
            return "The URL must point to a Complib composition."
        case .emptyCompositionID:
            return "The composition ID is empty."
        }
    }
}

struct WheatleySearchView: View {
    @EnvironmentObject var state: RingingRoomState
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State var text: String = ""
    
    @FocusState private var isEditing: Bool
    
    @State private var methods = [BluelineMethod]()
    
    var body: some View {
        VStack {
            HStack {
                TextField("Method", text: $text)
                    .focused($isEditing)
                    .padding(7)
                    .padding(.horizontal, 25)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                            
                            if isEditing {
                                Button(action: {
                                    self.text = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                                .transition(.opacity)
                                .animation(.default, value: isEditing)
                            }
                        }
                    )
                    .padding(.horizontal)
            }
            
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                
                if methods.count > 0 {
                    List(methods) { method in
                        Button {
                            do {
                                viewModel.send(.setWheatleyRowGen(rowGen: try method.makeRowGen()))
                                presentationMode.wrappedValue.dismiss()
                            } catch {
                                AlertHandler.presentAlert(title: "Wheatley", message: error.localizedDescription, dismiss: .cancel(title: "Dismiss", action: nil))
                            }
                        } label: {
                            HStack {
                                Text(method.title)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .task(id: MethodSearchRequest(query: text, stage: state.size)) {
            await searchMethods(query: text, stage: state.size)
        }
    }

    @MainActor
    private func searchMethods(query: String, stage: Int) async {
        guard stage > 0 else {
            methods = []
            return
        }

        do {
            try await Task.sleep(nanoseconds: 250_000_000)
            try Task.checkCancellation()

            var components = URLComponents()
            components.scheme = "https"
            components.host = "rsw.me.uk"
            components.path = "/blueline/methods/search.json"
            components.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "stage", value: "\(stage - 1),\(stage)")
            ]

            guard let url = components.url else { throw WheatleyError.invalidURL }
            let (data, response) = try await URLSession.shared.data(from: url)
            try Task.checkCancellation()

            guard let response = response as? HTTPURLResponse else {
                throw WheatleyError.invalidResponse
            }
            guard 200..<300 ~= response.statusCode else {
                throw WheatleyError.httpStatus(response.statusCode)
            }

            let decodedMethods: Methods
            do {
                decodedMethods = try JSONDecoder().decode(Methods.self, from: data)
            } catch {
                throw WheatleyError.invalidMethodPayload
            }
            try Task.checkCancellation()
            methods = decodedMethods.results
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            AlertHandler.presentAlert(title: "Wheatley", message: error.localizedDescription, dismiss: .cancel(title: "Dismiss", action: nil))
        }
    }
}

struct Methods: Codable {
    let results: [BluelineMethod]
}

struct BluelineMethod: Codable, Identifiable, Hashable {
    var id: String {
        "\(url)-\(stage)"
    }
    
    let title: String
    let stage: Int
    let notation: String
    let lengthOfLead: Int
    let calls: Calls?
    let url: String
    
    func makeRowGen() throws -> [String: Any] {
        var wheatleyMethod = [String: Any]()
        wheatleyMethod["title"] = title
        wheatleyMethod["stage"] = stage
        wheatleyMethod["notation"] = notation
        wheatleyMethod["url"] = url
        
        func convertCall(call: Bob?) throws -> [String: String] {
            if let call  {
                guard call.every > 0 else { throw WheatleyError.invalidCallInterval }
                var convertedCall = [String: String]()
                for i in 0..<Int((Double(lengthOfLead)/Double(call.every)).rounded(.up)) {
                    convertedCall[String(call.from + i * call.every)] = call.notation
                }
                return convertedCall
            } else {
                return .init()
            }
        }
        
        

        let bob = try convertCall(call: calls?.bob)
        let single: [String: String]
        
        if title == "Stedman Doubles" {
            single = [
                "0": "145",
                "6": "345"
            ]
        } else {
            single = try convertCall(call: calls?.single)
        }
        
        wheatleyMethod["bob"] = bob
        wheatleyMethod["single"] = single
        wheatleyMethod["type"] = "method"
        return wheatleyMethod
    }
}

struct Calls: Codable, Hashable {
    let bob, single: Bob?
    
    enum CodingKeys: String, CodingKey {
        case bob = "Bob"
        case single = "Single"
    }
}

struct Bob: Codable, Hashable {
    let notation: String
    let from, every: Int
}

enum RowGen: Decodable, Sendable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "method":
            self = .method(try WheatleyMethod(from: decoder))
        case "composition":
            self = .comp(try WheatleyComp(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown row generation type.")
        }
    }
    
    case method(WheatleyMethod)
    case comp(WheatleyComp)
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
    }
    
    init(dictionary: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        self = try JSONDecoder().decode(RowGen.self, from: data)
    }
}

struct WheatleyComp: Codable, Sendable {
    let title: String
    let url: String
}

struct WheatleyMethod: Codable, Sendable {
    init(title: String, stage: Int, notation: String, url: String, bob: [Int : String], single: [Int : String]) {
        self.title = title
        self.stage = stage
        self.notation = notation
        self.url = url
        self.bob = bob
        self.single = single
    }
    
    let title: String
    let stage: Int
    let notation: String
    let url: String
    let bob: [Int: String]
    let single: [Int: String]
}
