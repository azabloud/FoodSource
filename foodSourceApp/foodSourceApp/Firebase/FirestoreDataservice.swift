//
//  FirestoreDataservice.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 4/3/24.
//

import FirebaseFirestore
import FirebaseStorage

class FirestoreDataService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    func updateOrderWithTrackingData(orderId: String, trackingData: [String: Any], completion: @escaping (Bool) -> Void) {
        let orderRef = db.collection("orders").document(orderId)
        
        orderRef.updateData(trackingData) { error in
            if let error = error {
                print("Error updating order with tracking data: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func fetchTrackingInfoForOrder(orderId: String, completion: @escaping ([String: Any]) -> Void) {
        let orderRef = db.collection("orders").document(orderId)
        
        print("ORDER ID")
        print(orderId)
        
        orderRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching tracking info: \(error)")
                completion([:])
                return
            }
            
            guard let data = snapshot?.data(),
                  let trackingNumber = data["trackingNumber"] as? String,
                  let carrierCode = data["carrierCode"] as? String else {
                completion([:])
                return
            }
            
            let trackingInfo: [String: Any] = [
                "trackingNumber": trackingNumber,
                "carrierCode": carrierCode
            ]
            
            print("TRACKING INFO")
            print(trackingInfo)
            
            completion(trackingInfo)
        }
    }
    
    func fetchSellerProfile(sellerId: String, completion: @escaping (SellerProfile?) -> Void) {
        let sellerRef = db.collection("sellers").document(sellerId)
        sellerRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching seller profile: \(error)")
                completion(nil)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            
            let name = data["name"] as? String ?? ""
            let description = data["description"] as? String ?? ""
            let location = data["location"] as? String ?? ""
            let imageURL = data["imageURL"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let earnings = data["earnings"] as? Double ?? 0.0
            
            let profile = SellerProfile(name: name, description: description, location: location, imageURL: imageURL, email: email, earnings: earnings)
            completion(profile)
        }
    }

    func saveSellerProfile(sellerId: String, profile: SellerProfile, image: UIImage?, completion: @escaping (Bool) -> Void) {
        let sellerRef = db.collection("sellers").document(sellerId)
        
        let profileData: [String: Any] = [
            "name": profile.name,
            "description": profile.description,
            "location": profile.location,
            "email": profile.email,
            "earnings": profile.earnings
        ]
        
        if let image = image {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Invalid image")
                completion(false)
                return
            }
            
            let imageReference = storage.child("sellerProfiles/\(sellerId).jpg")
            imageReference.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading profile image: \(error)")
                    completion(false)
                    return
                }
                
                imageReference.downloadURL { url, error in
                    if let error = error {
                        print("Error getting profile image URL: \(error)")
                        completion(false)
                        return
                    }
                    
                    guard let imageURL = url?.absoluteString else {
                        print("Invalid profile image URL")
                        completion(false)
                        return
                    }
                    
                    let updatedProfileData = profileData.merging(["imageURL": imageURL]) { $1 }
                    sellerRef.setData(updatedProfileData) { error in
                        if let error = error {
                            print("Error saving seller profile: \(error)")
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                }
            }
        } else {
            sellerRef.setData(profileData) { error in
                if let error = error {
                    print("Error saving seller profile: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func fetchBuyerProfile(userId: String, completion: @escaping (BuyerProfile?) -> Void) {
        let buyerRef = db.collection("buyers").document(userId)
        buyerRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching buyer profile: \(error)")
                completion(nil)
                return
            }

            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }

            let name = data["name"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let profile = BuyerProfile(name: name, email: email)
            completion(profile)
        }
    }

    func saveBuyerProfile(userId: String, profile: BuyerProfile, completion: @escaping (Bool) -> Void) {
        let buyerRef = db.collection("buyers").document(userId)
        let profileData: [String: Any] = [
            "name": profile.name,
            "email": profile.email
        ]
        buyerRef.setData(profileData) { error in
            if let error = error {
                print("Error saving buyer profile: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func registerOrder(buyerId: String, sellerId: String, sellerName: String, products: [Product], totalAmount: Double, shippingAddress: String, completion: @escaping (Bool) -> Void) {
        let orderData: [String: Any] = [
            "buyerId": buyerId,
            "sellerId": sellerId,
            "sellerName": sellerName,
            "products": products.map { ["id": $0.id, "name": $0.name, "price": $0.price, "quantity": 1, "imageURL": $0.imageURL] },
            "totalAmount": totalAmount,
            "shippingAddress": shippingAddress,
            "date": Date()
        ]

        db.collection("orders").addDocument(data: orderData) { error in
            if let error = error {
                print("Error registering order: \(error)")
                completion(false)
            } else {
                self.updateSellerEarnings(sellerId: sellerId, amount: totalAmount) { success in
                    completion(success)
                }
            }
        }
    }

    func updateSellerEarnings(sellerId: String, amount: Double, completion: @escaping (Bool) -> Void) {
        let sellerRef = db.collection("sellers").document(sellerId)
        
        db.runTransaction { transaction, errorPointer in
            let sellerDocument: DocumentSnapshot
            do {
                try sellerDocument = transaction.getDocument(sellerRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            var newEarnings = amount
            if let oldEarnings = sellerDocument.data()?["earnings"] as? Double {
                newEarnings += oldEarnings
            }
            
            transaction.updateData(["earnings": newEarnings], forDocument: sellerRef)
            return newEarnings
        } completion: { object, error in
            if let error = error {
                print("Error updating seller earnings: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func fetchOrdersForBuyer(buyerId: String, completion: @escaping ([Order]) -> Void) {
        db.collection("orders")
            .whereField("buyerId", isEqualTo: buyerId)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching orders: \(error)")
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let group = DispatchGroup()
                var orders: [Order] = []

                for document in documents {
                    let data = document.data()
                    guard let buyerId = data["buyerId"] as? String,
                          let sellerId = data["sellerId"] as? String,
                          let sellerName = data["sellerName"] as? String,
                          let totalAmount = data["totalAmount"] as? Double,
                          let shippingAddress = data["shippingAddress"] as? String,
                          let date = data["date"] as? Timestamp,
                          let productDictionaries = data["products"] as? [[String: Any]] else {
                        continue
                    }

                    var products = productDictionaries.compactMap { dict -> Product? in
                        guard let id = dict["id"] as? String,
                              let name = dict["name"] as? String,
                              let price = dict["price"] as? Double,
                              let imageURL = dict["imageURL"] as? String else {
                            return nil
                        }
                        return Product(id: id, name: name, description: "", price: price, imageURL: imageURL)
                    }

                    let productGroup = DispatchGroup()
                    var updatedProducts: [Product] = []

                    for product in products {
                        productGroup.enter()

                        if !product.imageURL.isEmpty, let url = URL(string: product.imageURL) {
                            URLSession.shared.dataTask(with: url) { data, _, error in
                                if let error = error {
                                    print("Error downloading product image: \(error)")
                                } else if let data = data, let image = UIImage(data: data) {
                                    var updatedProduct = product
                                    updatedProduct.image = image
                                    updatedProducts.append(updatedProduct)
                                } else {
                                    updatedProducts.append(product)
                                }
                                productGroup.leave()
                            }.resume()
                        } else {
                            updatedProducts.append(product)
                            productGroup.leave()
                        }
                    }

                    group.enter()
                    productGroup.notify(queue: .main) {
                        let order = Order(id: document.documentID, buyerId: buyerId, sellerId: sellerId, products: updatedProducts, totalAmount: totalAmount, shippingAddress: shippingAddress, date: date.dateValue(), sellerName: sellerName)
                        orders.append(order)
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    completion(orders)
                }
            }
    }

    func fetchOrdersForSeller(sellerId: String, completion: @escaping ([Order]) -> Void) {
        db.collection("orders")
            .whereField("sellerId", isEqualTo: sellerId)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching orders: \(error)")
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let group = DispatchGroup()
                var orders: [Order] = []

                for document in documents {
                    let data = document.data()
                    guard let buyerId = data["buyerId"] as? String,
                          let sellerId = data["sellerId"] as? String,
                          let totalAmount = data["totalAmount"] as? Double,
                          let shippingAddress = data["shippingAddress"] as? String,
                          let date = data["date"] as? Timestamp,
                          let productDictionaries = data["products"] as? [[String: Any]] else {
                        continue
                    }

                    var products = productDictionaries.compactMap { dict -> Product? in
                        guard let id = dict["id"] as? String,
                              let name = dict["name"] as? String,
                              let price = dict["price"] as? Double,
                              let imageURL = dict["imageURL"] as? String else {
                            return nil
                        }
                        return Product(id: id, name: name, description: "", price: price, imageURL: imageURL)
                    }

                    let productGroup = DispatchGroup()
                    var updatedProducts: [Product] = []

                    for product in products {
                        productGroup.enter()

                        if !product.imageURL.isEmpty, let url = URL(string: product.imageURL) {
                            URLSession.shared.dataTask(with: url) { data, _, error in
                                if let error = error {
                                    print("Error downloading product image: \(error)")
                                } else if let data = data, let image = UIImage(data: data) {
                                    var updatedProduct = product
                                    updatedProduct.image = image
                                    updatedProducts.append(updatedProduct)
                                } else {
                                    updatedProducts.append(product)
                                }
                                productGroup.leave()
                            }.resume()
                        } else {
                            updatedProducts.append(product)
                            productGroup.leave()
                        }
                    }

                    group.enter()
                    productGroup.notify(queue: .main) {
                        let order = Order(id: document.documentID, buyerId: buyerId, sellerId: sellerId, products: updatedProducts, totalAmount: totalAmount, shippingAddress: shippingAddress, date: date.dateValue(), sellerName: "")
                        orders.append(order)
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    completion(orders)
                }
            }
    }
    
    func updateOrderWithTrackingNumber(orderId: String, trackingNumber: String, completion: @escaping (Bool) -> Void) {
        let orderRef = db.collection("orders").document(orderId)
        
        orderRef.updateData(["trackingNumber": trackingNumber]) { error in
            if let error = error {
                print("Error updating order with tracking number: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func saveSeller(_ seller: Seller, completion: @escaping (Bool) -> Void) {
        var sellerData: [String: Any] = [
            "name": seller.name,
            "description": seller.description,
            "location": seller.location,
            "imageURL": seller.imageURL
        ]

        if seller.id.isEmpty {
            db.collection("sellers").addDocument(data: sellerData) { error in
                if let error = error {
                    print("Error creating seller: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } else {
            db.collection("sellers").document(seller.id).setData(sellerData) { error in
                if let error = error {
                    print("Error updating seller: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func fetchSellers(completion: @escaping ([Seller]) -> Void) {
        db.collection("sellers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching sellers: \(error)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let group = DispatchGroup()
            let sellerGroup = DispatchGroup()
            var sellers: [Seller] = []

            for document in documents {
                let data = document.data()
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let location = data["location"] as? String else {
                    continue
                }

                let imageURL = data["imageURL"] as? String ?? ""

                sellerGroup.enter()

                if !imageURL.isEmpty, let url = URL(string: imageURL) {
                    URLSession.shared.dataTask(with: url) { data, _, error in
                        var sellerImage: UIImage?

                        if let error = error {
                            print("Error downloading seller image: \(error)")
                        } else if let data = data, let image = UIImage(data: data) {
                            sellerImage = image
                        }

                        let productsCollection = document.reference.collection("products")
                        group.enter()

                        productsCollection.order(by: "price", descending: true).limit(to: 3).getDocuments { snapshot, error in
                            if let error = error {
                                print("Error fetching products for seller \(name): \(error)")
                                group.leave()
                                sellerGroup.leave()
                                return
                            }

                            guard let productDocuments = snapshot?.documents else {
                                group.leave()
                                sellerGroup.leave()
                                return
                            }

                            let productGroup = DispatchGroup()
                            var products: [Product] = []

                            for productDocument in productDocuments {
                                let productData = productDocument.data()
                                guard let productName = productData["name"] as? String,
                                      let productDescription = productData["description"] as? String,
                                      let price = productData["price"] as? Double,
                                      let imageURL = productData["imageURL"] as? String else {
                                    continue
                                }

                                let product = Product(id: productDocument.documentID, name: productName, description: productDescription, price: price, imageURL: imageURL)
                                products.append(product)

                                productGroup.enter()

                                if let url = URL(string: imageURL) {
                                    URLSession.shared.dataTask(with: url) { data, _, error in
                                        if let error = error {
                                            print("Error downloading image: \(error)")
                                        } else if let data = data, let image = UIImage(data: data) {
                                            if let index = products.firstIndex(where: { $0.id == product.id }) {
                                                products[index].image = image
                                            }
                                        }
                                        productGroup.leave()
                                    }.resume()
                                } else {
                                    productGroup.leave()
                                }
                            }

                            productGroup.notify(queue: .main) {
                                let seller = Seller(id: document.documentID, name: name, description: description, products: products, location: location, imageURL: imageURL, image: sellerImage)
                                sellers.append(seller)
                                group.leave()
                                sellerGroup.leave()
                            }
                        }
                    }.resume()
                } else {
                    let productsCollection = document.reference.collection("products")
                    group.enter()

                    productsCollection.order(by: "price", descending: true).limit(to: 3).getDocuments { snapshot, error in
                        if let error = error {
                            print("Error fetching products for seller \(name): \(error)")
                            group.leave()
                            sellerGroup.leave()
                            return
                        }

                        guard let productDocuments = snapshot?.documents else {
                            group.leave()
                            sellerGroup.leave()
                            return
                        }

                        let productGroup = DispatchGroup()
                        var products: [Product] = []

                        for productDocument in productDocuments {
                            let productData = productDocument.data()
                            guard let productName = productData["name"] as? String,
                                  let productDescription = productData["description"] as? String,
                                  let price = productData["price"] as? Double,
                                  let imageURL = productData["imageURL"] as? String else {
                                continue
                            }

                            let product = Product(id: productDocument.documentID, name: productName, description: productDescription, price: price, imageURL: imageURL)
                            products.append(product)

                            productGroup.enter()

                            if let url = URL(string: imageURL) {
                                URLSession.shared.dataTask(with: url) { data, _, error in
                                    if let error = error {
                                        print("Error downloading image: \(error)")
                                    } else if let data = data, let image = UIImage(data: data) {
                                        if let index = products.firstIndex(where: { $0.id == product.id }) {
                                            products[index].image = image
                                        }
                                    }
                                    productGroup.leave()
                                }.resume()
                            } else {
                                productGroup.leave()
                            }
                        }

                        productGroup.notify(queue: .main) {
                            let seller = Seller(id: document.documentID, name: name, description: description, products: products, location: location, imageURL: imageURL, image: nil)
                            sellers.append(seller)
                            group.leave()
                            sellerGroup.leave()
                        }
                    }
                }
            }

            sellerGroup.notify(queue: .main) {
                group.notify(queue: .main) {
                    completion(sellers)
                }
            }
        }
    }

    func fetchProducts(completion: @escaping ([Product]) -> Void) {
        db.collection("products").getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching products: \(error)")
                completion([])
            } else {
                let products = querySnapshot?.documents.compactMap { document -> Product? in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let price = data["price"] as? Double,
                          let imageURL = data["imageURL"] as? String else {
                        return nil
                    }
                    return Product(id: document.documentID, name: name, description: description, price: price, imageURL: imageURL)
                } ?? []
                completion(products)
            }
        }
    }

    func fetchProductsForSeller(_ sellerId: String, completion: @escaping ([Product]) -> Void) {
        db.collection("sellers").document(sellerId).collection("products").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching products for seller: \(error)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let products = documents.compactMap { document -> Product? in
                let data = document.data()
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let price = data["price"] as? Double,
                      let imageURL = data["imageURL"] as? String else {
                    return nil
                }

                return Product(id: document.documentID, name: name, description: description, price: price, imageURL: imageURL)
            }

            completion(products)
        }
    }

    func addProduct(_ product: Product, image: UIImage?, sellerId: String, completion: @escaping (String?) -> Void) {
        guard let image = image, let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Invalid image")
            completion(nil)
            return
        }

        let imageReference = storage.child("products/\(UUID().uuidString).jpg")
        imageReference.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
                completion(nil)
                return
            }

            imageReference.downloadURL { url, error in
                if let error = error {
                    print("Error getting image URL: \(error)")
                    completion(nil)
                    return
                }

                guard let imageURL = url?.absoluteString else {
                    print("Invalid image URL")
                    completion(nil)
                    return
                }

                let productData: [String: Any] = [
                    "name": product.name,
                    "description": product.description,
                    "price": product.price,
                    "imageURL": imageURL
                ]

                self.db.collection("sellers").document(sellerId).collection("products").addDocument(data: productData) { error in
                    if let error = error {
                        print("Error adding product: \(error)")
                        completion(nil)
                    } else {
                        completion(imageURL)
                    }
                }
            }
        }
    }
}
