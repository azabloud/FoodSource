//
//  ContentView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject var userViewModel = UserViewModel()

    var body: some View {
        switch userViewModel.currentUserRole {
        case .buyer:
            BuyerTabView(userViewModel: userViewModel)
        case .seller:
            SellerTabView(userViewModel: userViewModel)
        }
    }
}
