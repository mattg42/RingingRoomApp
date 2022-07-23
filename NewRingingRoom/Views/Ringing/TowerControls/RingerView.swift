//
//  RingerView.swift
//  NewRingingRoom
//
//  Created by Matthew on 14/07/2022.
//

import SwiftUI

struct RingerView: View {

    var user: Ringer
    var selectedUser: Bool

    @EnvironmentObject var viewModel: RingingRoomViewModel

    var body: some View {
        HStack {
            Text(
                !viewModel.assignments.compactMap { ringer in
                    if let ringer {
                        return ringer.ringerID
                    } else {
                        return nil
                    }
                }
                    .contains(user.ringerID) ? "-" : self.getString(indexes: viewModel.assignments.allIndicesOfRinger(user))
            )
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            Text(user.name)
                .fontWeight(self.selectedUser ? .bold : .regular)
                .lineLimit(1)
                .layoutPriority(2)
            Spacer()
        }
        .foregroundColor(self.selectedUser ? Color.main : Color.primary)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())
    }

    func getString(indexes:[Int]) -> String {
        var str = ""
        for (index, number) in indexes.enumerated() {
            if index == 0 {
                str += String(number + 1)
            } else {
                str += ", \(number + 1)"
            }
        }
        return str
    }
}
