//
//  foodSourceAppApp.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//

import SwiftUI
import FirebaseCore
import Stripe

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    STPAPIClient.shared.publishableKey = "pk_live_51P1DG0EQTOaxXJYkI936RmQ85s5V8P2PFywgbxAD4WPVJO6CBsgGFbFi68KfldfJA4KNIzYqK7R63BwYZ4s79WD400oFIfsBSE"
    return true
  }
}

@main
struct foodSourceAppApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var cartManager = CartManager()
    @StateObject private var userViewModel = UserViewModel()
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        LoginView()
      }
      .environmentObject(cartManager)
      .environmentObject(userViewModel)
    }
  }
}
