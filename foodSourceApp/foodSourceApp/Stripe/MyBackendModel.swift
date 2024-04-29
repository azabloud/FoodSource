//
//  MyBackendModel.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 4/12/24.
//

import StripePaymentSheet
import SwiftUI
import FirebaseFirestore

class MyBackendModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var showPaymentSheet: Bool = false

    private let db = Firestore.firestore()

    func preparePaymentSheet(for amount: Int, sellerId: String, shippingAddress: String) {
        db.collection("sellers").document(sellerId).getDocument { [weak self] (document, error) in
            guard let self = self, error == nil, let document = document, document.exists,
                  let sellerData = document.data(),
                  let stripeAccountId = sellerData["stripeAccountId"] as? String else {
                print("Error fetching seller data or seller data is incomplete")
                return
            }
            
            let paymentIntentParams: [String: Any] = [
                "amount": amount,
                "currency": "usd",
                "onBehalfOf": stripeAccountId,
                "shippingAddress": shippingAddress
            ]

            self.createPaymentIntent(with: paymentIntentParams)
        }
    }
    
    private func initializePaymentSheet(with clientSecret: String) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Your App Name"
        
        DispatchQueue.main.async {
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
            self.showPaymentSheet = true
        }
    }

    private func createPaymentIntent(with params: [String: Any]) {
        guard let url = URL(string: "https://us-central1-foodsource-91e25.cloudfunctions.net/createPaymentIntent") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData: [String: Any] = ["data": params]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse,
                  error == nil else {
                print("Network request failed with error: \(error?.localizedDescription ?? "No error info")")
                return
            }

            if response.statusCode == 200 {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let outerResult = json["result"] as? [String: Any],
                       let innerResult = outerResult["result"] as? [String: Any],
                       let clientSecret = innerResult["client_secret"] as? String {
                        print("Received client secret: \(clientSecret)")
                        self.initializePaymentSheet(with: clientSecret)
                    } else {
                        print("Failed to parse JSON or missing keys.")
                    }
                } catch {
                    print("JSON parsing failed with error: \(error.localizedDescription)")
                }
            } else {
                print("Received non-200 status code.")
                if let str = String(data: data, encoding: .utf8) {
                    print("Server response: \(str)")
                }
            }
        }.resume()
    }

    func onPaymentCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result
            self.showPaymentSheet = false
        }
    }
}
