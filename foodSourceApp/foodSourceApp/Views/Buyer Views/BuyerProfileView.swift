//
//  BuyerProfileView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//
import SwiftUI

struct BuyerProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @StateObject private var viewModel: BuyerProfileViewModel

    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        _viewModel = StateObject(wrappedValue: BuyerProfileViewModel(userId: userViewModel.currentUser?.uid ?? ""))
    }

    var body: some View {
        VStack {
            HStack {
                Text("Buyer Profile")
                    .font(.system(.title, design: .serif, weight: .regular))
                Spacer()
            }.padding([.horizontal, .top])
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $viewModel.name)
                    TextField("Email", text: $viewModel.email)
                }
                
                Button("Save Profile") {
                    viewModel.saveProfile()
                }
                
                Button("Switch to Seller View") {
                    userViewModel.currentUserRole = .seller
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                viewModel.fetchProfile()
            }
        }
    }
}

class BuyerProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    private let userId: String
    private let dataService = FirestoreDataService()

    init(userId: String) {
        self.userId = userId
    }

    func fetchProfile() {
        dataService.fetchBuyerProfile(userId: userId) { profile in
            DispatchQueue.main.async {
                self.name = profile?.name ?? ""
                self.email = profile?.email ?? ""
            }
        }
    }

    func saveProfile() {
        let profile = BuyerProfile(name: name, email: email)
        dataService.saveBuyerProfile(userId: userId, profile: profile) { success in
            if success {
                print("Buyer profile saved")
            } else {
                print("Failed to save buyer profile")
            }
        }
    }
}

struct BuyerProfile {
    var name: String
    var email: String
}
