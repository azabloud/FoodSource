//
//  OrdersView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//
import SwiftUI

struct OrdersView: View {
    @State private var orders: [Order] = []
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Orders")
                                .font(.system(.title, design: .serif, weight: .regular))
                            Spacer()
                        }
                        
                        ForEach(orders) { order in
                            NavigationLink(destination: OrderDetailView(order: order)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Order #\(order.id)")
                                            .font(.system(.subheadline, design: .monospaced, weight: .regular))
                                            .foregroundColor(.primary)
                                        
                                        Text("Total: $\(order.totalAmount, specifier: "%.2f")")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        
                                        Text("Date: \(order.date, formatter: dateFormatter)")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        
                                        Text("Seller: \(order.sellerName)")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
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
                .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                let buyerId = userViewModel.currentUser?.uid ?? ""
                FirestoreDataService().fetchOrdersForBuyer(buyerId: buyerId) { orders in
                    self.orders = orders
                    self.fetchProductImages()
                }
            }
        }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func fetchProductImages() {
        let group = DispatchGroup()
        
        for index in orders.indices {
            for productIndex in orders[index].products.indices {
                group.enter()
                
                let product = orders[index].products[productIndex]
                
                if !product.imageURL.isEmpty, let url = URL(string: product.imageURL) {
                    URLSession.shared.dataTask(with: url) { data, _, error in
                        if let error = error {
                            print("Error downloading product image: \(error)")
                        } else if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.orders[index].products[productIndex].image = image
                            }
                        }
                        group.leave()
                    }.resume()
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            print("Product images loaded")
        }
    }
}

struct OrderDetailView: View {
    let order: Order
    @State private var trackingInfo: [String: Any] = [:]
    @State private var trackingDetails: [String: Any] = [:]
    @State private var isTrackingInfoLoaded = false
    @Environment(\.presentationMode) var presentationMode

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
                        Text("Order #\(order.id)")
                            .font(.system(.title3, design: .monospaced, weight: .semibold))
                        
                        Text("Total: $\(order.totalAmount, specifier: "%.2f")")
                            .font(.system(.subheadline, design: .monospaced))
                        
                        Text("Date: \(order.date, formatter: dateFormatter)")
                            .font(.system(.subheadline, design: .monospaced))
                        
                        Text("Seller: \(order.sellerName)")
                            .font(.system(.subheadline, design: .monospaced))
                        
                        Text("Shipping Address:")
                            .font(.system(.subheadline, design: .monospaced))
                        Text(order.shippingAddress)
                            .font(.system(.subheadline).width(.condensed))
                            .foregroundColor(.secondary)
                            .padding(.leading)
                        
                        Text("Shipping Status:")
                            .font(.system(.subheadline, design: .monospaced))
                        
                        
                        if isTrackingInfoLoaded {
                            if let trackingNumber = trackingInfo["trackingNumber"] as? String,
                               let carrierCode = trackingInfo["carrierCode"] as? String {
                                Text("Tracking Number: \(trackingNumber)")
                                    .font(.system(.subheadline).width(.condensed))
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                                Text("Carrier: \(carrierCode.uppercased())")
                                    .font(.system(.subheadline).width(.condensed))
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                                
                                if let status = trackingDetails["status"] as? String {
                                    Text("Status: \(status)")
                                        .font(.system(.subheadline).width(.condensed))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("Waiting to be shipped...")
                                .font(.system(.subheadline).width(.condensed))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Waiting to be shipped...")
                            .font(.system(.subheadline).width(.condensed))
                            .foregroundColor(.secondary)
                            .padding(.leading)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Products")
                            .font(.system(.subheadline, design: .monospaced, weight: .regular))
                        
                        ForEach(order.products) { product in
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
                                    
                                    Text("$\(product.price, specifier: "%.2f")")
                                        .font(.system(.subheadline).width(.condensed))
                                        .foregroundColor(.secondary)
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
            .navigationBarBackButtonHidden(true)
            .onAppear {
                FirestoreDataService().fetchTrackingInfoForOrder(orderId: order.id) { trackingInfo in
                    self.trackingInfo = trackingInfo
                    self.isTrackingInfoLoaded = true
                    self.fetchTrackingDetails()
                }
            }
        }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func fetchTrackingDetails() {
        guard let trackingNumber = trackingInfo["trackingNumber"] as? String,
              let carrierCode = trackingInfo["carrierCode"] as? String else {
            return
        }
            
            let headers = [
                "content-type": "application/json",
                "X-RapidAPI-Key": "37cac45071mshf3c686ff8898579p156c14jsn009a79275032",
                "X-RapidAPI-Host": "order-tracking.p.rapidapi.com"
            ]
            
            let parameters = [
                "tracking_number": trackingNumber,
                "carrier_code": carrierCode
            ] as [String: Any]
            
            let postData = try? JSONSerialization.data(withJSONObject: parameters)
            
            let url = URL(string: "https://order-tracking.p.rapidapi.com/trackings/realtime")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making API call: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received from API")
                    return
                }
                
                if let jsonResult = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let trackingData = jsonResult["data"] as? [String: Any],
                   let trackingItems = trackingData["items"] as? [[String: Any]],
                   let trackingDetails = trackingItems.first {
                    DispatchQueue.main.async {
                        self.trackingDetails = trackingDetails
                    }
                }
            }.resume()
        }
}
