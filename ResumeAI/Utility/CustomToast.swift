import SwiftUI

struct Toast: ViewModifier {
    @Binding var isShowing: Bool
    var message: String
    var icon: String = "checkmark.circle.fill"
    var duration: TimeInterval = 2.0
    @State private var timer: Timer? = nil

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .foregroundColor(.white)
                        Text(message)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        // Cancel any existing timer if a new toast appears
                        timer?.invalidate()
                        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                            isShowing = false
                            timer = nil
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.1), value: isShowing)
            }
        }
    }
}

extension View {
    func toast(
        message: String,
        isShowing: Binding<Bool>,
        icon: String = empty,
        duration: TimeInterval = 2.0
    ) -> some View {
        self.modifier(Toast(isShowing: isShowing,
                            message: message,
                            icon: icon,
                            duration: duration))
    }
}
