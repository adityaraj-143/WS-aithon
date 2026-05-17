import SwiftUI

struct CartItemRow: View {

    let item: CartItem
    let onAdd: () -> Void
    let onRemove: () -> Void
    let onRemoveCompletely: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // ─── Image ───────────────────────────────────────
            ZStack {
                Color.brandAccentWash.opacity(0.4)
                
                CustomAsyncImage(url: item.imageURL)
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // ─── Info ────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                // Category/Badge label
                if item.registryId != nil {
                    Text("REGISTRY EXCLUSIVE")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(.brandPrimary)
                }
                
                Text(item.title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                // Stepper
                HStack(spacing: 12) {
                    Button(action: onRemove) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 24, height: 24)
                    }

                    Text("\(item.quantity)")
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundColor(.textPrimary)
                        .frame(minWidth: 16)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.brandAccentWash.opacity(0.6))
                .clipShape(Capsule())
            }

            Spacer(minLength: 12)

            // ─── Price & Remove ──────────────────────────────
            VStack(alignment: .trailing, spacing: 12) {
                // Remove button
                Button(action: onRemoveCompletely) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textTertiary)
                        .frame(width: 20, height: 20)
                        .background(Color.brandAccentWash.opacity(0.4))
                        .clipShape(Circle())
                }
                
                Spacer(minLength: 0)
                
                // Total price aligned right
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundColor(.textPrimary)
                    
                    if item.quantity > 1 {
                        Text("$\(item.price, specifier: "%.2f") each")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}
