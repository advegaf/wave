import SwiftUI

struct WaveSegmentedControl<T>: View where T: Hashable & CaseIterable & RawRepresentable, T.RawValue == String, T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    @Namespace private var selectionNS

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(T.allCases), id: \.self) { option in
                let isSelected = option == selection
                Text(option.rawValue)
                    .waveFont(Wave.font.micro)
                    .foregroundStyle(isSelected ? Wave.colors.textPrimary : Wave.colors.textSecondary)
                    .padding(.horizontal, Wave.spacing.s8)
                    .padding(.vertical, Wave.spacing.s6)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(Wave.colors.surfacePrimary)
                                    .matchedGeometryEffect(id: "selection", in: selectionNS)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            selection = option
                        }
                    }
            }
        }
        .padding(Wave.spacing.s2)
        .background(Wave.colors.surfaceSecondary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Wave.colors.border, lineWidth: 1))
    }
}
