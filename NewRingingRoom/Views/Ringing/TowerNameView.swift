//
//  TowerNameView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/08/2022.
//

import SwiftUI

struct TowerNameView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel

    var body: some View {
        ZStack {
            Color.main
                .cornerRadius(5)
            
            Text(viewModel.towerInfo.towerName)
                .foregroundColor(.white)
                .font(Font.custom("Simonetta-Black", size: 30))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.vertical, 4)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct TowerNameView_Previews: PreviewProvider {
    static var previews: some View {
        TowerNameView()
    }
}
