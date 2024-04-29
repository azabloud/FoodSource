//
//  LoginView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var role: UserRole = .buyer
    @State private var isShowingNextView = false

    var body: some View {
            VStack {
                Text("FoodSource")
                    .font(.system(.largeTitle, design: .serif, weight: .regular))
                    .fontWeight(.bold)
                    .foregroundColor(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                    .padding(.bottom, 40)
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Picker("Role", selection: $role) {
                        Text("Buyer").tag(UserRole.buyer)
                        Text("Seller").tag(UserRole.seller)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Button("Sign Up") {
                        AuthService.shared.signUpWithEmail(email: email, password: password, role: role) { success in
                            if success {
                                isShowingNextView = true
                            }
                        }
                    }
                    .padding()
                    .background(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()

                NavigationLink(destination: ContentView(), isActive: $isShowingNextView) {
                    EmptyView()
                }
            }
            .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            .padding()
            .onAppear {
                if userViewModel.currentUser != nil {
                    isShowingNextView = true
                }
            }
        
    }
}

enum UserRole: String {
    case buyer
    case seller
}




