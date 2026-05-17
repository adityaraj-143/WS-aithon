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
                Color.brandAccentWash
                
                CustomAsyncImage(url: item.imageURL)
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )

            // ─── Info ────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                // Category/Badge label
                Text(item.registryId != nil ? "REGISTRY EXCLUSIVE" : "CURATED COLLECTION")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.brandPrimary)
                
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(.textSecondary)
                    
                    if item.quantity > 1 {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                        Text("$\(item.price * Double(item.quantity), specifier: "%.2f") total")
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(.brandPrimary)
                    }
                }

                Spacer(minLength: 8)

                // Stepper
                HStack(spacing: 12) {
                    Button(action: onRemove) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Color.white)
                            .clipShape(Circle())
                    }

                    Text("\(item.quantity)")
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundColor(.textPrimary)
                        .frame(minWidth: 16)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.brandAccentWash)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )
            }

            Spacer(minLength: 0)

            // ─── Remove Action ──────────────────────────────
            Button(action: onRemoveCompletely) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textTertiary)
                    .frame(width: 24, height: 24)
                    .background(Color.brandAccentWash.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
}
