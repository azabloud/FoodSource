//
//  OrderManagementView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//
import SwiftUI

struct SellerOrdersView: View {
    @StateObject private var viewModel: SellerOrdersViewModel
    let sellerId: String
    
    init(sellerId: String) {
        self.sellerId = sellerId
        _viewModel = StateObject(wrappedValue: SellerOrdersViewModel(sellerId: sellerId))
    }
    
    var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Orders")
                                .font(.system(.title, design: .serif, weight: .regular))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Total Earnings")
                                .font(.system(.headline, design: .monospaced, weight: .semibold))
                            
                            Text("$\(viewModel.totalEarnings, specifier: "%.2f")")
                                .font(.system(.headline, design: .monospaced, weight: .semibold))
                                .foregroundColor(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
                            
                            Text("VISIT CONNECT.STRIPE.COM TO TRACK YOUR PAYOUTS")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        ForEach(viewModel.orders) { order in
                            NavigationLink(destination: SellerOrderDetailView(order: order)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Order #\(order.id)")
                                            .font(.system(.subheadline, design: .monospaced, weight: .regular))
                                            .foregroundColor(.primary)
                                        
                                        Text("Shipping Address:")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text(order.shippingAddress)
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
                viewModel.fetchOrders()
                viewModel.fetchSellerEarnings()
            }
        }
}

class SellerOrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var totalEarnings = 0.0
    
    private let sellerId: String
    private let dataService = FirestoreDataService()
    
    init(sellerId: String) {
        self.sellerId = sellerId
    }
    
    func fetchOrders() {
        dataService.fetchOrdersForSeller(sellerId: sellerId) { orders in
            DispatchQueue.main.async {
                self.orders = orders
            }
        }
    }
    
    func fetchSellerEarnings() {
        dataService.fetchSellerProfile(sellerId: sellerId) { profile in
            DispatchQueue.main.async {
                self.totalEarnings = profile?.earnings ?? 0.0
            }
        }
    }
}

struct SellerOrderDetailView: View {
    let order: Order

    @State private var trackingNumber: String = ""
    @State private var carrierCode: String = "ups"
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
                        
                        Group {
                            Text("Total: $\(order.totalAmount, specifier: "%.2f")")
                                .font(.system(.subheadline, design: .monospaced))
                            
                            Text("Date: \(order.date, formatter: dateFormatter)")
                                .font(.system(.subheadline, design: .monospaced))
                            
                            Text("Shipping Address:")
                                .font(.system(.subheadline, design: .monospaced))
                            
                            Text(order.shippingAddress)
                                .font(.system(.subheadline).width(.condensed))
                                .foregroundColor(.secondary)
                                .padding(.leading)
                            
                            Text("Shipping Status:")
                                .font(.system(.subheadline, design: .monospaced))
                            
                            if !trackingNumber.isEmpty {
                                Text("Tracking Number: \(trackingNumber)")
                                    .font(.system(.subheadline).width(.condensed))
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                                Text("Carrier: \(carrierCode.uppercased())")
                                    .font(.system(.subheadline).width(.condensed))
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                            } else {
                                Text("Not shipped yet")
                                    .font(.system(.subheadline).width(.condensed))
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                            }
                        }
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
                                    
                                    Text("Quantity: \(product.quantity ?? 1)")
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
                    
                    VStack(spacing: 20) {
                        TextField("Enter Tracking Number", text: $trackingNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Picker("Carrier", selection: $carrierCode) {
                            Text("UPS").tag("ups")
                            Text("USPS").tag("usps")
                            Text("FedEx").tag("fedex")
                            Text("DHL").tag("dhl")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        Button(action: {
                            submitTrackingNumber()
                        }) {
                            Text("Submit Tracking Number")
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
                    }
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
        }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    func submitTrackingNumber() {
        let trackingData: [String: Any] = [
            "trackingNumber": trackingNumber,
            "carrierCode": carrierCode
        ]
        
        FirestoreDataService().updateOrderWithTrackingData(orderId: order.id, trackingData: trackingData) { success in
            if success {
                print("Tracking data saved to Firestore")
            } else {
                print("Failed to save tracking data to Firestore")
            }
        }
    }
}
