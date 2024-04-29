//
//  Product.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 4/4/24.
//

import Foundation
import UIKit

struct Order: Identifiable {
    let id: String
    let buyerId: String
    let sellerId: String
    var products: [Product]
    let totalAmount: Double
    let shippingAddress: String
    let date: Date
    let sellerName: String
}

struct Product: Identifiable, Hashable {
    var id: String
   var name: String
   var description: String
   var price: Double
   var imageURL: String
    var image: UIImage?
    var quantity: Int?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
}

struct Seller: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    var rating: Double?
    let products: [Product]?
    let location: String
    let imageURL: String
    var image: UIImage?
    var earnings: Double?
}

struct SellerProfile {
    var name: String
    var description: String
    var location: String
    var imageURL: String
    var email: String
    var earnings: Double
}

let seller1 = Seller(
    id: "s1",
    name: "Green Valley Farm",
    description: "We are a family-owned farm dedicated to providing fresh, organic produce.",
    rating: 4.8,
    products: [
        Product(id: "p1", name: "Organic Carrots", description: "1/2 lbs of fresh, crunchy carrots grown without pesticides.", price: 2.99, imageURL: "https://example.com/carrots.jpg", image: UIImage(named: "carrots2")),
        Product(id: "p2", name: "Heirloom Tomatoes", description: "Juicy, flavorful tomatoes in a variety of colors.", price: 4.99, imageURL: "https://example.com/tomatoes.jpg", image: UIImage(named: "tomatos")),
        Product(id: "p3", name: "Fresh Eggs", description: "Free-range eggs from our happy hens.", price: 5.99, imageURL: "https://example.com/eggs.jpg", image: UIImage(named: "eggs"))
    ],
    location: "Los Angeles",
    imageURL: "hufhr",
    image: UIImage(named: "farm")
)

let seller2 = Seller(
    id: "s2",
    name: "Riverside Fishing Co.",
    description: "We specialize in fresh, sustainably caught fish from local rivers.",
    rating: 4.5,
    products: [
        Product(id: "p4", name: "Wild Caught Salmon", description: "Delicious, omega-3 rich salmon caught in pristine waters.", price: 12.99, imageURL: "https://example.com/salmon.jpg", image: UIImage(named: "carrot")),
        Product(id: "p5", name: "Freshwater Trout", description: "Tender, flaky trout perfect for grilling or baking.", price: 9.99, imageURL: "https://example.com/trout.jpg", image: UIImage(named: "carrot"))
    ],
    location: "New York",
    imageURL: "hufhr",
    image: UIImage(named: "fisherman")
)

let seller3 = Seller(
    id: "s3",
    name: "Meadow View Apiary",
    description: "We offer a variety of pure, raw honey from our own bee hives.",
    rating: 4.9,
    products: [
        Product(id: "p6", name: "Wildflower Honey", description: "Fragrant, golden honey from wildflower nectar.", price: 7.99, imageURL: "https://example.com/wildflower_honey.jpg", image: UIImage(named: "carrot")),
        Product(id: "p7", name: "Clover Honey", description: "Light, sweet honey from clover blossoms.", price: 6.99, imageURL: "https://example.com/clover_honey.jpg", image: UIImage(named: "carrot"))
    ],
    location: "Nebraska",
    imageURL: "hufhr",
    image: UIImage(named: "honey")
)

let seller4 = Seller(
    id: "s4",
    name: "Hilltop Orchards",
    description: "We grow a wide variety of fresh, juicy fruits in our scenic orchards.",
    rating: 4.3,
    products: [
        Product(id: "p8", name: "Crisp Apples", description: "Freshly picked, crisp apples in several varieties.", price: 1.99, imageURL: "https://example.com/apples.jpg", image: UIImage(named: "carrot")),
        Product(id: "p9", name: "Ripe Peaches", description: "Sweet, succulent peaches perfect for pies or eating fresh.", price: 3.99, imageURL: "https://example.com/peaches.jpg", image: UIImage(named: "carrot")),
        Product(id: "p10", name: "Juicy Pears", description: "Delicate, juicy pears with a smooth texture.", price: 2.99, imageURL: "https://example.com/pears.jpg", image: UIImage(named: "carrot"))
    ],
    location: "Austin",
    imageURL: "hufhr",
    image: UIImage(named: "orchard")
)

let seller5 = Seller(
    id: "s5",
    name: "Deer Valley Venison",
    description: "We provide high-quality, locally hunted venison meat.",
    rating: 4.5,
    products: [
        Product(id: "p11", name: "Venison Steaks", description: "Lean, flavorful venison steaks perfect for grilling.", price: 14.99, imageURL: "https://example.com/venison_steaks.jpg", image: UIImage(named: "carrot")),
        Product(id: "p12", name: "Ground Venison", description: "Versatile ground venison for burgers, chili, and more.", price: 9.99, imageURL: "https://example.com/ground_venison.jpg", image: UIImage(named: "carrot"))
    ],
    location: "Iowa",
    imageURL: "hufhr",
    image: UIImage(named: "venison")
)

let seller6 = Seller(
    id: "s6",
    name: "Sunny Meadow Dairy",
    description: "We offer fresh, creamy milk and artisanal cheeses from our grass-fed cows.",
    rating: 4.2,
    products: [
        Product(id: "p13", name: "Whole Milk", description: "Rich, wholesome milk from our contented cows.", price: 3.99, imageURL: "https://example.com/whole_milk.jpg", image: UIImage(named: "milk")),
        Product(id: "p14", name: "Aged Cheddar", description: "Sharp, tangy cheddar cheese aged to perfection.", price: 8.99, imageURL: "https://example.com/aged_cheddar.jpg", image: UIImage(named: "cheese"))
    ],
    location: "Wisconsin",
    imageURL: "https://example.com/dairy_farm.jpg",
    image: UIImage(named: "cows")
)

let seller7 = Seller(
    id: "s7",
    name: "Golden Grain Bakery",
    description: "We bake delicious, wholesome breads using traditional methods and organic grains.",
    rating: 4.9,
    products: [
        Product(id: "p15", name: "Sourdough Bread", description: "Tangy, crusty sourdough bread with a soft interior.", price: 5.99, imageURL: "https://example.com/sourdough_bread.jpg", image: UIImage(named: "bread")),
        Product(id: "p16", name: "Whole Wheat Loaf", description: "Nutritious whole wheat bread perfect for sandwiches.", price: 4.99, imageURL: "https://example.com/whole_wheat_loaf.jpg", image: UIImage(named: "bread"))
    ],
    location: "Seattle",
    imageURL: "https://example.com/bakery.jpg",
    image: UIImage(named: "bakery")
)

let seller8 = Seller(
    id: "s8",
    name: "Maple Hill Sugarbush",
    description: "We produce pure, delicious maple syrup from our own maple trees.",
    rating: 4.4,
    products: [
        Product(id: "p17", name: "Amber Maple Syrup", description: "Rich, amber-colored maple syrup with a smooth flavor.", price: 12.99, imageURL: "https://example.com/amber_maple_syrup.jpg", image: UIImage(named: "syrup")),
        Product(id: "p18", name: "Dark Maple Syrup", description: "Robust, dark maple syrup with a strong, complex taste.", price: 14.99, imageURL: "https://example.com/dark_maple_syrup.jpg", image: UIImage(named: "syrup"))
    ],
    location: "Vermont",
    imageURL: "https://example.com/sugarbush.jpg",
    image: UIImage(named: "trees")
)

let sampleSellers = [seller1, seller2, seller3, seller4, seller5, seller6, seller7, seller8]
