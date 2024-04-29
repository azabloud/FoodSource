//
//  SellerTabView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//
import SwiftUI

struct SellerTabView: View {
    @ObservedObject var userViewModel: UserViewModel
    var body: some View {
        TabView {
            ProductManagementView(sellerId: userViewModel.currentUser?.uid ?? "")
                .tabItem {
                    Image(systemName: "carrot.fill")
                }

            SellerOrdersView(sellerId: userViewModel.currentUser?.uid ?? "")
                .tabItem {
                    Image(systemName: "list.bullet")
                }
            
            SellerProfileView(userViewModel: userViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                }
        }
        .navigationBarBackButtonHidden()
        .tint(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
    }
}
