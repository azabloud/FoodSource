//
//  FeedView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//

import Foundation
import SwiftUI
import StripePaymentSheet

struct SellerListView: View {
    @StateObject private var viewModel = SellerListViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("FoodSource")
                        .font(.system(.title, design: .serif, weight: .regular))
                    Spacer()
                    Button(action: {
                        
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .padding(.trailing, 4)
                    }
                }.padding([.horizontal, .top])
                
                HStack {
                    TextField("Search sellers, products, locations", text: $searchText)
                        .font(.system(.caption, design: .monospaced, weight: .regular))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 6)
                            }
                        )
                }.padding(.horizontal)
                
                ScrollView {
                    VStack {
                        
                        ForEach(viewModel.sellers.filter { seller in
                            searchText.isEmpty || seller.name.localizedCaseInsensitiveContains(searchText)
                        }) { seller in
                            NavigationLink(destination: SellerDetailView(seller: seller)) {
                                HStack(spacing: 16) {
                                    if let image = seller.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                    } else {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 80, height: 80)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(seller.name)
                                            .font(.system(.subheadline, design: .monospaced, weight: .regular))
                                            .foregroundColor(.primary)
                                        
                                        Text(seller.location)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            if let rating = seller.rating {
                                                Text(String(format: "%.1f", rating))
                                                    .font(.system(.caption, design: .monospaced))
                                            } else {
                                                Text("5.0")
                                                    .font(.system(.caption, design: .monospaced))
                                            }
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                        }.foregroundColor(.secondary)
                                        
                                        if let products = seller.products, products.count > 0 {
                                            Text(products.prefix(3).map { $0.name }.joined(separator: ", "))
                                                .font(.system(.caption).width(.condensed))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    viewModel.fetchSellers()
                }
            }
        }.tint(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
    }
}

class CartManager: ObservableObject {
    @Published var cartItems: [Product: Int] = [:]
    @Published var totalPrice: Double = 0.0

    func addToCart(_ product: Product, quantity: Int = 1) {
        if let existingQuantity = cartItems[product] {
            cartItems[product] = existingQuantity + quantity
        } else {
            cartItems[product] = quantity
        }
        totalPrice += product.price * Double(quantity)
    }

    func removeFromCart(_ product: Product) {
        if let quantity = cartItems[product] {
            totalPrice -= product.price * Double(quantity)
            cartItems[product] = nil
        }
    }

    func updateQuantity(for product: Product, quantity: Int) {
        if let existingQuantity = cartItems[product] {
            let quantityDifference = quantity - existingQuantity
            cartItems[product] = quantity
            totalPrice += product.price * Double(quantityDifference)
        }
    }

    func quantityFor(_ product: Product) -> Int {
        return cartItems[product] ?? 0
    }

    func increaseQuantity(for product: Product) {
        if let existingQuantity = cartItems[product] {
            cartItems[product] = existingQuantity + 1
            totalPrice += product.price
        } else {
            addToCart(product)
        }
    }

    func decreaseQuantity(for product: Product) {
        if let existingQuantity = cartItems[product], existingQuantity > 1 {
            cartItems[product] = existingQuantity - 1
            totalPrice -= product.price
        } else {
            removeFromCart(product)
        }
    }
    
    func clearCart() {
        cartItems = [:]
        totalPrice = 0.0
    }
}

class SellerListViewModel: ObservableObject {
    @Published var sellers: [Seller] = []
    
    private let dataService = FirestoreDataService()
    private let useSampleData = true
    
    init() {
        fetchSellers()
    }
    
    func fetchSellers() {
        dataService.fetchSellers { [weak self] firestoreSellers in
            guard let self = self else { return }
            
            var allSellers: [Seller] = []
            
            if self.useSampleData {
                allSellers.append(contentsOf: sampleSellers)
            }
            
            allSellers.append(contentsOf: firestoreSellers)
            
            DispatchQueue.main.async {
                self.sellers = allSellers
            }
        }
    }
}

struct SellerDetailView: View {
    let seller: Seller
    @State private var selectedProduct: Product?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cartManager: CartManager

    var body: some View {
        ScrollView {
            VStack {
                ZStack(alignment: .top) {
                    if let image = seller.image {
                        Image(uiImage: image)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 390, height: 450)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 320)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label : {
                            Image(systemName: "arrow.backward")
                                .foregroundColor(.primary)
                                .font(.title3)
                                .padding(11)
                                .background {
                                    Circle()
                                        .fill(Color(.systemBackground))
                                }
                        }
                        Spacer()
                        Button {
                            
                        } label : {
                            Image(systemName: "heart")
                        }
                        
                        Button {
                            
                        } label : {
                            Image(systemName: "square.and.arrow.up")
                                .symbolRenderingMode(.hierarchical)
                                .padding(.leading, 8)
                        }
                    }
                    .font(.system(.title2, weight: .semibold))
                    .foregroundColor(.white)
                    .padding()
                    .padding(.top, 100)
                }
                .frame(height: 320)
                .clipped()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(seller.name)
                            .font(.system(.title, design: .serif, weight: .regular))
                        
                        Text(seller.location)
                            .font(.system(.callout, design: .serif, weight: .medium))
                        
                        HStack {
                            if let rating = seller.rating {
                                Text(String(format: "%.1f", rating))
                                    .font(.system(.callout, design: .serif, weight: .medium))
                            } else {
                                Text("5.0")
                                    .font(.system(.callout, design: .serif, weight: .medium))
                            }
                            Image(systemName: "star.fill")
                                .font(.caption)
                        }
                        
                        Text(seller.description)
                            .font(.system(.callout).width(.condensed))
                            .padding(.vertical)
                        
                        NavigationLink(destination: CartView(seller: seller)) {
                            
                            HStack {
                                Text("View Cart")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("$\(cartManager.totalPrice, specifier: "%.2f")")
                                    .foregroundColor(.white)
                            }
                            .font(.system(.headline, design: .monospaced, weight: .semibold))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .background(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                            .mask { RoundedRectangle(cornerRadius: 40, style: .continuous) }
                            .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 15) {
                    
                    
                    Text("PRODUCTS")
                        .kerning(2.0)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                    
                    ForEach(seller.products ?? []) { product in
                        
                        Button {
                            selectedProduct = product
                        }label: {
                            HStack(spacing: 16) {
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .font(.system(.subheadline, design: .monospaced, weight: .regular)).foregroundColor(.primary)
                                        
                                    
                                    Text(product.description)
                                        .font(.system(.subheadline).width(.condensed))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text("$\(product.price, specifier: "%.2f")")
                                        .font(.system(.subheadline).width(.condensed))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                if let image = product.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(seller: seller, product: product)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager
    @State private var shippingAddress: String = ""
    @State private var buyerName: String = ""
    @StateObject private var paymentModel = MyBackendModel()
    let seller: Seller
    @Environment(\.presentationMode) var presentationMode
    @State private var showOrderConfirmation = false
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label : {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.primary)
                            .font(.title3)
                            .padding(11)
                            .background {
                                Circle()
                                    .fill(Color(.systemBackground))
                            }
                    }
                    Spacer()
                }
                
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Items")
                        .font(.system(.title2, design: .monospaced, weight: .semibold))
                    
                    ForEach(Array(cartManager.cartItems.keys), id: \.self) { product in
                        HStack(spacing: 16) {
                            if let image = product.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(.system(.subheadline, design: .monospaced, weight: .regular))
                                    .foregroundColor(.primary)
                                
                                Text(product.description)
                                    .font(.system(.subheadline).width(.condensed))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                Text("$\(product.price, specifier: "%.2f")")
                                    .font(.system(.subheadline).width(.condensed))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Button(action: {
                                        cartManager.decreaseQuantity(for: product)
                                    }) {
                                        Image(systemName: "minus")
                                            .tint(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                                    }
                                    
                                    Text("\(cartManager.quantityFor(product))")
                                        .font(.system(.subheadline, design: .monospaced, weight: .regular))
                                    
                                    Button(action: {
                                        cartManager.increaseQuantity(for: product)
                                    }) {
                                        Image(systemName: "plus")
                                            .tint(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shipping Details")
                        .font(.system(.title2, design: .monospaced, weight: .semibold))
                    
                    Text("Enter your name")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal)
                    
                    TextEditor(text: $buyerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 30)
                        .padding(.horizontal)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )

                    Text("Enter your shipping address")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal)
                    
                    TextEditor(text: $shippingAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 100)
                        .padding(.horizontal)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Total: $\(cartManager.totalPrice, specifier: "%.2f")")
                        .font(.system(.title3, design: .monospaced, weight: .semibold))
                    
                    Button(action: {
                        let amount = Int(cartManager.totalPrice * 100.0)
                        paymentModel.preparePaymentSheet(for: amount, sellerId: seller.id, shippingAddress: shippingAddress)
                    }) {
                        Text("Checkout")
                            .foregroundColor(.white)
                            .font(.system(.headline, design: .monospaced, weight: .semibold))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .background(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                            .mask { RoundedRectangle(cornerRadius: 40, style: .continuous) }
                            .padding(.horizontal)
                            .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .disabled(shippingAddress.isEmpty)
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $paymentModel.showPaymentSheet, onDismiss: {
            handlePaymentResult()
        }) {
            if let sheet = paymentModel.paymentSheet {
                PaymentSheet.PaymentButton(paymentSheet: sheet, onCompletion: paymentModel.onPaymentCompletion) {
                    VStack {
                        Image(systemName: "creditcard")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                        
                        Text("Confirm Payment")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                            .cornerRadius(10)
                    }
                }
                .presentationDetents([.height(200)])
            }
        }
        .navigationDestination(isPresented: $showOrderConfirmation) {
            OrdersView()
        }
    }


    private func handlePaymentResult() {
        if let result = paymentModel.paymentResult {
            switch result {
            case .completed:
                print("Payment successful")
                let totalAmount = cartManager.totalPrice
                let buyerId = userViewModel.currentUser?.uid ?? ""
                FirestoreDataService().registerOrder(buyerId: buyerId, sellerId: seller.id, sellerName: seller.name, products: Array(cartManager.cartItems.keys), totalAmount: totalAmount, shippingAddress: shippingAddress) { success in
                    if success {
                        cartManager.clearCart()
                        
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.async {
                            userViewModel.selectedTab = 1
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                    }
                }
                showOrderConfirmation = true
            case .failed(let error):
                print("Payment failed: \(error.localizedDescription)")
            case .canceled:
                print("Payment canceled")
            }
        }
    }
}

struct ProductDetailView: View {
    let seller: Seller
    var product: Product
    @State private var quantity = 1
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var paymentModel = MyBackendModel()
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack {
                    if let image = product.image {
                        Image(uiImage: image)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 390, height: 450)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 390, height: 450)
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        HStack {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label : {
                                Image(systemName: "xmark")
                                    .foregroundColor(.primary)
                                    .font(.title3)
                                    .padding(11)
                                    .background {
                                        Circle()
                                            .fill(Color(.systemBackground))
                                    }
                            }
                            
                            Spacer()
                            Button {
                                
                            } label : {
                                Image(systemName: "heart")
                            }
                            
                            Button {
                                
                            } label : {
                                Image(systemName: "square.and.arrow.up")
                                    .symbolRenderingMode(.hierarchical)
                                    .padding(.leading, 8)
                            }
                        }
                        .font(.system(.title2, weight: .semibold))
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .padding(.top, 10)
                    
                    VStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text(product.name)
                                .font(.system(.title, design: .serif, weight: .regular))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .frame(maxWidth: 290, alignment: .center)
                                .clipped()
                            
                            Text(product.description)
                                .foregroundColor(.white.opacity(0.75))
                                .font(.system(.caption, design: .monospaced))
                            
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .padding()
                }
                .frame(height: 450)
                .clipped()
                
                VStack(spacing: 16) {
                    HStack {
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.system(.title3, design: .monospaced, weight: .regular))
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                if quantity > 1 {
                                    quantity -= 1
                                }
                            }) {
                                Image(systemName: "minus")
                                    .tint(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                            }
                            
                            Text("\(quantity)")
                                .font(.system(.title3, design: .monospaced, weight: .regular))
                            
                            Button(action: {
                                if quantity < 10 {
                                    quantity += 1
                                }
                            }) {
                                Image(systemName: "plus").tint(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                            }
                        }
                        
                    }
                    .padding()
                    
                    Button(action: {
                        cartManager.addToCart(product, quantity: quantity)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text("Add to Cart")
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("$\(product.price * Double(quantity), specifier: "%.2f")")
                                .foregroundColor(.white)
                        }
                        .font(.system(.headline, design: .monospaced, weight: .semibold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .background(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                        .mask { RoundedRectangle(cornerRadius: 40, style: .continuous) }
                        .padding(.horizontal)
                        .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    
                }
                .padding(.vertical)
            }
            .padding(.bottom, 40)
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $paymentModel.showPaymentSheet, onDismiss: {
            handlePaymentResult()
        }) {
            if let sheet = paymentModel.paymentSheet {
                PaymentSheet.PaymentButton(paymentSheet: sheet, onCompletion: paymentModel.onPaymentCompletion) {
                    Text("Confirm Payment")
                }
            }
        }
    }
    
    private func handlePaymentResult() {
        if let result = paymentModel.paymentResult {
            switch result {
            case .completed:
                print("Payment successful")
            case .failed(let error):
                print("Payment failed: \(error.localizedDescription)")
            case .canceled:
                print("Payment canceled")
            }
        }
    }
}

struct SellerList_Previews: PreviewProvider {
    static var previews: some View {
        SellerListView()
    }
}

