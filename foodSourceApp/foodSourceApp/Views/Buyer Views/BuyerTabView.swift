//
//  BuyerTabView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//
import SwiftUI

struct BuyerTabView: View {
    @ObservedObject var userViewModel: UserViewModel
    var body: some View {
        TabView(selection: $userViewModel.selectedTab) {
            SellerListView()
                .tabItem {
                    Image(systemName: "carrot.fill")
                }
                .tag(0)

            OrdersView()
                .tabItem {
                    Image(systemName: "list.bullet")
                }
                .tag(1)

            BuyerProfileView(userViewModel: userViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                }
                .tag(2)
        }
        .navigationBarBackButtonHidden()
        .tint(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
    }
}
