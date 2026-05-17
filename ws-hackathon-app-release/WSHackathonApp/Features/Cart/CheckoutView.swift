//
//  CheckoutView.swift
//  WSHackathonApp
//

import SwiftUI

struct CheckoutView: View {
    let items: [CartItem]
    let totalPrice: Double
    var onPaySuccess: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPayment: PaymentMethod = .creditCard
    @State private var isSplitBill = false
    @EnvironmentObject var registryRepo: RegistryRepository
    
    private let bgColor = Color.appBackground
    private let brandColor = Color.brandPrimary
    private let accentSuccess = Color.wsSuccess
    
    var body: some View {
        ZStack(alignment: .top) {
            bgColor.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Checkout")
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // ─── Order Summary ───────────────────────────
                        orderSummarySection
                        
                        if showSplitBillOption {
                            sectionDivider
                            
                            splitBillSection
                        }
                        
                        sectionDivider
                        
                        // ─── Payment Methods ─────────────────────────
                        paymentMethodsSection
                        
                        sectionDivider
                        
                        // ─── Card Offers ─────────────────────────────
                        cardOffersSection
                        
                        sectionDivider
                        
                        // ─── Price Breakdown ─────────────────────────
                        priceBreakdownSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
            
            // Bottom Pay Button
            VStack {
                Spacer()
                
                let divisor = isSplitBill ? Double(collaboratorCount) : 1.0
                let payableAmount = (totalPrice + totalPrice * 0.08) / divisor
                
                Button(action: {
                    onPaySuccess?()
                    dismiss()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                        Text("Pay \(payableAmount.formatted(.currency(code: "USD")))")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(brandColor)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [bgColor.opacity(0), bgColor, bgColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .offset(y: 10)
                )
            }
        }
    }
    
    // MARK: - Order Summary
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("ORDER SUMMARY")
            
            ForEach(items) { item in
                HStack(spacing: 12) {
                    CustomAsyncImage(url: item.imageURL)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                        
                        Text("Qty: \(item.quantity)")
                            .font(.system(size: 12))
                            .foregroundColor(.textTertiary)
                    }
                    
                    Spacer()
                    
                    Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Payment Methods
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("PAYMENT METHOD")
            
            ForEach(PaymentMethod.allCases) { method in
                paymentRow(method)
            }
        }
    }
    
    private func paymentRow(_ method: PaymentMethod) -> some View {
        let isSelected = selectedPayment == method
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPayment = method
            }
        }) {
            HStack(spacing: 14) {
                Image(systemName: method.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? brandColor : Color.textTertiary)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? brandColor.opacity(0.1) : Color.brandAccentWash)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(method.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    Text(method.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                }
                
                Spacer()
                
                // Radio
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.textMuted, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(brandColor)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? brandColor.opacity(0.06) : Color.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? brandColor.opacity(0.3) : Color.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Split Bill
    
    private var splitBillSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("COLLABORATIVE GIFTING")
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Split Bill Equally")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Divide total among \(collaboratorCount) collaborators")
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isSplitBill.animation(.spring(response: 0.35, dampingFraction: 0.8)))
                    .labelsHidden()
                    .tint(brandColor)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Card Offers
    
    private var cardOffersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("CARD OFFERS & BENEFITS")
            
            ForEach(cardOffers, id: \.title) { offer in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: offer.icon)
                        .font(.system(size: 16))
                        .foregroundColor(brandColor)
                        .frame(width: 36, height: 36)
                        .background(brandColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(offer.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text(offer.description)
                            .font(.system(size: 12))
                            .foregroundColor(.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
    
    // MARK: - Price Breakdown
    
    private var priceBreakdownSection: some View {
        let divisor = isSplitBill ? Double(collaboratorCount) : 1.0
        let rawSubtotal = totalPrice
        let rawTax = totalPrice * 0.08
        
        let displaySubtotal = rawSubtotal
        let displayTax = rawTax / divisor
        let displayTotal = (rawSubtotal + rawTax) / divisor
        
        return VStack(spacing: 12) {
            priceRow("Subtotal", value: displaySubtotal)
            
            if isSplitBill {
                HStack {
                    Text("Split Between")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(collaboratorCount) People")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.brandPrimary)
                }
                
                priceRow("Per Person", value: rawSubtotal / divisor)
            }
            
            priceRow("Shipping", value: 0, label: "FREE")
            priceRow(isSplitBill ? "Estimated Tax (Per Person)" : "Estimated Tax", value: displayTax)
            
            Divider()
                .background(Color.borderSubtle)
            
            HStack {
                Text(isSplitBill ? "Total Payable" : "Total")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(displayTotal.formatted(.currency(code: "USD")))
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(.textPrimary)
            }
        }
    }
    
    private func priceRow(_ title: String, value: Double, label: String? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Spacer()
            if let label {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentSuccess)
            } else {
                Text(value.formatted(.currency(code: "USD")))
                    .font(.system(size: 14))
                    .foregroundColor(.textPrimary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var uniqueRegistryIds: Set<String> {
        Set(items.compactMap { $0.registryId })
    }
    
    private var singleRegistryId: UUID? {
        guard uniqueRegistryIds.count == 1,
              let firstIdStr = uniqueRegistryIds.first,
              let uuid = UUID(uuidString: firstIdStr) else {
            return nil
        }
        return uuid
    }
    
    private var checkoutRegistry: Registry? {
        guard let uuid = singleRegistryId else { return nil }
        return registryRepo.registries.first { $0.id == uuid }
    }
    
    private var collaboratorCount: Int {
        checkoutRegistry?.collaboratorNames.count ?? 0
    }
    
    private var showSplitBillOption: Bool {
        uniqueRegistryIds.count == 1 && collaboratorCount > 1
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.5)
            .foregroundColor(.textTertiary)
    }
    
    private var sectionDivider: some View {
        Divider()
            .background(Color.borderSubtle)
            .padding(.vertical, 4)
    }
    
    // MARK: - Data
    
    private var cardOffers: [(icon: String, title: String, description: String)] {
        [
            (
                icon: "creditcard.fill",
                title: "5% Cashback on HDFC Cards",
                description: "Get 5% cashback up to $25 on HDFC credit & debit cards."
            ),
            (
                icon: "gift.fill",
                title: "No-Cost EMI Available",
                description: "Pay in 3, 6, or 12 month installments at 0% interest on select cards."
            ),
            (
                icon: "percent",
                title: "10% Off with Amex Platinum",
                description: "American Express Platinum members save an extra 10% on orders above $100."
            )
        ]
    }
}

// MARK: - Payment Method Enum

enum PaymentMethod: String, CaseIterable, Identifiable {
    case creditCard
    case debitCard
    case applePay
    case paypal
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        case .applePay: return "Apple Pay"
        case .paypal: return "PayPal"
        }
    }
    
    var subtitle: String {
        switch self {
        case .creditCard: return "Visa, Mastercard, Amex"
        case .debitCard: return "All major banks supported"
        case .applePay: return "Pay with Face ID or Touch ID"
        case .paypal: return "Fast & secure checkout"
        }
    }
    
    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "banknote.fill"
        case .applePay: return "apple.logo"
        case .paypal: return "p.circle.fill"
        }
    }
}
