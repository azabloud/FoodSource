//
//  ProductManagementView.swift
//  foodSourceApp
//
//  Created by Adam Zabloudil on 2/19/24.
//

import SwiftUI

struct ProductManagementView: View {
    let sellerId: String
    @StateObject private var viewModel: ProductManagementViewModel

    init(sellerId: String) {
        self.sellerId = sellerId
        self._viewModel = StateObject(wrappedValue: ProductManagementViewModel(sellerId: sellerId))
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Manage Products")
                        .font(.system(.title, design: .serif, weight: .regular))
                    Spacer()
                    Button(action: {
                        viewModel.showAddProductSheet = true
                    }) {
                        Image(systemName: "plus")
                            .padding(.trailing, 4)
                    }
                }.padding([.horizontal, .top])

                ScrollView {
                    VStack {
                        ForEach(viewModel.products) { product in
                            ProductListItemView(product: product)
                        }
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $viewModel.showAddProductSheet) {
                AddProductView(viewModel: viewModel)
            }
        }.tint(Color(.displayP3, red: 157/255, green: 188/255, blue: 138/255))
    }
}

struct ProductListItemView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 16) {
            if !product.imageURL.isEmpty {
                AsyncImage(url: URL(string: product.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                    @unknown default:
                        EmptyView()
                    }
                }
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

struct AddProductView: View {
    @ObservedObject var viewModel: ProductManagementViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("Add Product")
                            .font(.system(.title, design: .serif, weight: .regular))
                        Spacer()
                    }.padding([.horizontal, .top])

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.system(.subheadline, design: .monospaced, weight: .regular))

                        TextField("Product Name", text: $viewModel.newProduct.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))

                        TextField("Description", text: $viewModel.newProduct.description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))

                        TextField("Price", text: $viewModel.priceString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Image")
                            .font(.system(.subheadline, design: .monospaced, weight: .regular))

                        if let image = viewModel.newProductImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .cornerRadius(10)
                        } else {
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(height: 200)
                                .cornerRadius(10)
                                .overlay(
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.gray)
                                )
                        }

                    }
                    .padding(.horizontal)
                    
                    Button(action: viewModel.showImagePicker) {
                        Text("Upload Image")
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

                    Button(action: {
                        viewModel.addProduct()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Add Product")
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
                }.padding()
            }
            .sheet(isPresented: $viewModel.showingImagePicker, content: {
                ImagePicker(image: $viewModel.newProductImage)
            })
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Success"), message: Text("Product added successfully"), dismissButton: .default(Text("OK")))
        }
    }
}

class ProductManagementViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var newProduct = Product(id: "", name: "", description: "", price: 0.0, imageURL: "")
    @Published var newProductImage: UIImage? = nil
    @Published var showAddProductSheet = false
    @Published var showingImagePicker = false
    @Published var showingAlert = false
    
    private let dataService = FirestoreDataService()
    private let sellerId: String
    
    init(sellerId: String) {
        self.sellerId = sellerId
        fetchProducts()
    }
    
    var priceString: String {
        get {
            return String(format: "%.2f", newProduct.price)
        }
        set {
            if let price = Double(newValue) {
                newProduct.price = price
            }
        }
    }
    
    func fetchProducts() {
        dataService.fetchProductsForSeller(sellerId) { products in
            self.products = products
        }
    }
    
    func addProduct() {
        dataService.addProduct(newProduct, image: newProductImage, sellerId: sellerId) { imageURL in
            if let imageURL = imageURL {
                var newProduct = self.newProduct
                newProduct.imageURL = imageURL
                self.products.append(newProduct)
                self.newProduct = Product(id: "", name: "", description: "", price: 0.0, imageURL: "")
                self.newProductImage = nil
                self.showingAlert = true
            } else {
                print("ERROR, PRODUCT DIDN'T UPLOAD")
            }
        }
    }
    
    func showImagePicker() {
        showingImagePicker = true
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.editedImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
