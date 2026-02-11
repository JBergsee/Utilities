//
//  TimePickerPopover.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import SwiftUI

/// A popover view presenting a wheels-style time picker with Set and Remove buttons.
/// Replaces the UIKit `TimePickerView.xib` + `TimePickerViewController` combination.
@available(iOS 18.0, *)
struct TimePickerPopover: View {

    @Binding var date: Date
    var onSet: (Date) -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.timeZone, .gmt)
                .frame(width: 250) // or whatever feels right
            HStack (spacing: 12) {
                Button(action: {
                    onSet(date)
                }) {
                    Text("Set")
                        .frame(maxWidth: .infinity) // Make it expand horizontally
                }
                Button(action: {
                    onRemove()
                }) {
                    Text("Remove")
                        .frame(maxWidth: .infinity) // Make it expand horizontally
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .buttonStyle(.bordered)
        }
        .fixedSize() // Restrain the size to minimum intrinsic size

    }
}

@available(iOS 18.0, *)
#Preview {
    TimePickerPopover(
        date: .constant(Date(timeIntervalSince1970: 750 * 60)),
        onSet: { _ in },
        onRemove: { }
    )
}
