//
//  StripeDataService.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 4/11/24.
//

import Stripe
import FirebaseFirestore

class StripeDataService {
    private let db = Firestore.firestore()

    func createStripeAccountForSeller(_ sellerId: String, completion: @escaping (String?) -> Void) {
        let accountParams = STPConnectAccountParams()
        accountParams.tosShownAndAccepted = true

        STPAPIClient.shared.createToken(withConnectAccount: accountParams) { token, error in
            if let error = error {
                print("Error creating Stripe account token: \(error)")
                completion(nil)
                return
            }

            guard let token = token else {
                print("No Stripe account token received")
                completion(nil)
                return
            }

            let accountId = token.tokenId
            let accountData: [String: Any] = [
                "stripeAccountId": accountId
            ]

            self.db.collection("sellers").document(sellerId).setData(accountData, merge: true) { error in
                if let error = error {
                    print("Error saving Stripe account ID: \(error)")
                    completion(nil)
                } else {
                    completion(accountId)
                }
            }
        }
    }

    func processPayment(amount: Double, sellerId: String, completion: @escaping (Bool) -> Void) {
        db.collection("sellers").document(sellerId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching seller data: \(error)")
                completion(false)
                return
            }

            guard let sellerData = snapshot?.data(),
                  let stripeAccountId = sellerData["stripeAccountId"] as? String else {
                print("Invalid seller data")
                completion(false)
                return
            }

            let paymentIntentParams: [String: Any] = [
                "amount": Int64(amount * 100),
                "currency": "usd",
                "on_behalf_of": stripeAccountId
            ]

            let url = URL(string: "https://us-central1-foodsource-91e25.cloudfunctions.net/createPaymentIntent")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: paymentIntentParams)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error creating PaymentIntent: \(error)")
                    completion(false)
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let clientSecret = json["client_secret"] as? String else {
                    print("Invalid response from server")
                    completion(false)
                    return
                }

                let paymentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                STPAPIClient.shared.confirmPaymentIntent(with: paymentParams) { paymentIntent, error in
                    if let error = error {
                        print("Error processing payment: \(error)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }.resume()
        }
    }
}
