//
//  UserViewModel.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 4/4/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserViewModel: ObservableObject {
    @Published var currentUserRole: UserRole = .buyer
    @Published var currentUser: User?
    @Published var selectedTab = 0

    init() {
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        if let user = AuthService.shared.getCurrentUser() {
            currentUser = user
            
            let userRef = Firestore.firestore().collection("users").document(user.uid)
            userRef.getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user data: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(), let roleString = data["role"] as? String else {
                    return
                }
                
                self.currentUserRole = UserRole(rawValue: roleString) ?? .buyer
            }
        }
    }
}
