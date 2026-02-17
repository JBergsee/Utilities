//
//  ProgressHUDView.swift
//  Utilities
//
//  Created by Johan Nyman on 2025-02-09.
//

import SwiftUI

// MARK: - State Model

@Observable
public class ProgressHUDState {
    public var mode: ProgressHUDMode = .indeterminate
    public var label: String?
    public var progress: Float = 0
    public var progressObject: Progress?
    public var showsBackground: Bool = false
    public var isSquare: Bool = false
    public var buttonTitle: String?
    public var buttonAction: (() -> Void)?

    public init() {}
}

public enum ProgressHUDMode: Equatable, Sendable {
    case indeterminate
    case annularDeterminate
    case horizontalBar
    case customView(systemImage: String)

    public static func == (lhs: ProgressHUDMode, rhs: ProgressHUDMode) -> Bool {
        switch (lhs, rhs) {
        case (.indeterminate, .indeterminate),
             (.annularDeterminate, .annularDeterminate),
             (.horizontalBar, .horizontalBar):
            return true
        case (.customView(let a), .customView(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - SwiftUI View

public struct ProgressHUDView: View {
    @Bindable var state: ProgressHUDState

    public init(state: ProgressHUDState) {
        self.state = state
    }

    public var body: some View {
        ZStack {
            if state.showsBackground {
                Color(white: 0.5, opacity: 0.5)
                    .ignoresSafeArea()
            }
            VStack(spacing: 12) {
                switch state.mode {
                case .indeterminate:
                    ProgressView()
                        .controlSize(.large)
                case .annularDeterminate:
                    AnnularProgressView(progress: Double(state.progress))
                        .frame(width: 37, height: 37)
                case .horizontalBar:
                    if let obj = state.progressObject {
                        ProgressView(obj)
                            .progressViewStyle(.linear)
                    } else {
                        ProgressView(value: Double(state.progress))
                            .progressViewStyle(.linear)
                    }
                case .customView(let systemImage):
                    Image(systemName: systemImage)
                        .font(.title)
                }
                if let label = state.label {
                    Text(label)
                        .font(.subheadline)
                }
                if let title = state.buttonTitle {
                    Button(title) {
                        state.buttonAction?()
                    }
                }
            }
            .padding(24)
            .frame(minWidth: state.isSquare ? 120 : nil,
                   minHeight: state.isSquare ? 120 : nil)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Annular Progress Ring

struct AnnularProgressView: View {
    var progress: Double
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(Color.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
        }
    }
}
