//
//  SellerProfileView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//
import SwiftUI
import FirebaseFunctions
import FirebaseFirestore
import SafariServices

struct SellerProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @StateObject private var viewModel: SellerProfileViewModel
    
    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        let sellerId = userViewModel.currentUser?.uid ?? ""
        _viewModel = StateObject(wrappedValue: SellerProfileViewModel(sellerId: sellerId))
    }

    var body: some View {
        VStack {
            HStack {
                Text("Seller Profile")
                    .font(.system(.title, design: .serif, weight: .regular))
                Spacer()
            }.padding([.horizontal, .top])
            Form {
                Section(header: Text("Earnings")) {
                    Text("Total Earnings: $\(viewModel.totalEarnings, specifier: "%.2f")")
                }
                
                Section(header: Text("Profile Image")) {
                    if let image = viewModel.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        viewModel.showImagePicker = true
                    }) {
                        Text("Upload Image")
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("Seller Name", text: $viewModel.sellerName)
                    TextField("Location", text: $viewModel.location)
                }
                
                Section(header: Text("Contact")) {
                    TextField("Email", text: $viewModel.email)
                }
                
                Section(header: Text("About")) {
                    TextEditor(text: $viewModel.description)
                        .frame(height: 200)
                }
                
                Button("Save Profile") {
                    viewModel.saveProfile()
                }
                
                Button("Add Payout Information") {
                    viewModel.createStripeAccount()
                }
                
                Button("Switch to Buyer View") {
                    userViewModel.currentUserRole = .buyer
                }
                
                Button("Log Out") {
                    viewModel.showLogoutConfirmation = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showImagePicker, content: {
            ImagePicker(image: $viewModel.profileImage)
        })
        .navigationTitle("Seller Profile")
        .sheet(isPresented: $viewModel.shouldPresentOnboarding) {
            if let url = viewModel.onboardingURL {
                SafariView(url: url)
            } else {
                Text("Invalid URL")
            }
        }
        .onAppear {
            viewModel.fetchProfile()
        }
        .alert(isPresented: $viewModel.showLogoutConfirmation) {
            Alert(
                title: Text("Logout"),
                message: Text("Are you sure you want to logout?"),
                primaryButton: .destructive(Text("Logout")) {
                    AuthService.shared.logout()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

class SellerProfileViewModel: ObservableObject {
    @Published var sellerName = ""
    @Published var description = ""
    @Published var sellerId = ""
    @Published var location = ""
    @Published var imageURL = ""
    @Published var totalEarnings = 0.0
    @Published var email = ""
    @Published var shouldPresentOnboarding: Bool = false
    @Published var onboardingURL: URL?
    @Published var showLogoutConfirmation = false
    @Published var profileImage: UIImage?
    @Published var showImagePicker = false

    private let dataService = FirestoreDataService()
    private let stripeDataService = StripeDataService()
    private let db = Firestore.firestore()
    
    init(sellerId: String) {
        self.sellerId = sellerId
    }
    
    func fetchProfile() {
        dataService.fetchSellerProfile(sellerId: sellerId) { profile in
            DispatchQueue.main.async {
                self.sellerName = profile?.name ?? ""
                self.description = profile?.description ?? ""
                self.location = profile?.location ?? ""
                self.imageURL = profile?.imageURL ?? ""
                self.email = profile?.email ?? ""
                self.totalEarnings = profile?.earnings ?? 0.0
            }
        }
    }

    func saveProfile() {
        let profile = SellerProfile(name: sellerName, description: description, location: location, imageURL: imageURL, email: email, earnings: totalEarnings)
        dataService.saveSellerProfile(sellerId: sellerId, profile: profile, image: profileImage) { success in
            if success {
                print("Seller profile saved")
            } else {
                print("Failed to save seller profile")
            }
        }
    }
    
    func createStripeAccount() {
        let function = Functions.functions().httpsCallable("createStripeAccount")
        function.call(["email": email]) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error as NSError? {
                print("Error: \(error.localizedDescription)")
                return
            }
            if let accountId = (result?.data as? [String: Any])?["accountId"] as? String {
                print("Stripe account created: \(accountId)")
                
                let accountData: [String: Any] = ["stripeAccountId": accountId]
                self.db.collection("sellers").document(self.sellerId).setData(accountData, merge: true) { error in
                    if let error = error {
                        print("Error saving Stripe account ID: \(error)")
                    }
                    self.fetchOnboardingLink(accountId: accountId)
                }
            }
        }
    }

    func fetchOnboardingLink(accountId: String) {
        print("Attempting to fetch onboarding link for account:", accountId)
        let function = Functions.functions().httpsCallable("createAccountLink")
        function.call(["accountId": accountId]) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching account link: \(error.localizedDescription)")
                return
            }
            if let link = (result?.data as? [String: Any])?["url"] as? String, let url = URL(string: link) {
                print("Received onboarding link:", url)
                DispatchQueue.main.async {
                    self.onboardingURL = url
                    self.shouldPresentOnboarding = true
                }
            } else {
                print("Failed to receive a valid URL.")
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}
