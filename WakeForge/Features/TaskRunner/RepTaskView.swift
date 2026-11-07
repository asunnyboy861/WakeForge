import SwiftUI
import SwiftData
import AVFoundation

struct RepTaskView: View {
    @ObservedObject var viewModel: TaskRunnerViewModel
    let kind: TaskKind
    let context: ModelContext

    @StateObject private var camera = CameraSession()
    @State private var attempts = 0
    @State private var showGuide = true

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if camera.isAvailable {
                    CameraPreview(session: camera.session)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            statusPill
                                .padding(10)
                        }
                    if showGuide {
                        guideOverlay
                    }
                } else {
                    unavailablePlaceholder
                }
            }
            .frame(height: 300)
            .padding(.horizontal, 20)

            VStack(spacing: 4) {
                Text("\(viewModel.progress)/\(viewModel.target)")
                    .font(WFTheme.font(76, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(viewModel.progress) of \(viewModel.target) \(kind.title)")
                Text(kind == .pushup ? "Elbows below 95° count. Shoulders must drop too." : "Knees below 95° count. Hips must drop too.")
                    .font(WFTheme.font(13))
                    .foregroundStyle(WFTheme.muted)
            }

            ProgressView(value: Double(viewModel.progress), total: Double(viewModel.target))
                .tint(WFTheme.forge)
                .padding(.horizontal, 28)

            if !camera.isAvailable {
                Button {
                    attempts += 1
                    viewModel.registerFailure(reason: "This device has no front camera available.")
                } label: {
                    Text("Use another task")
                }
                .buttonStyle(WFSecondaryButtonStyle())
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            if camera.isAvailable {
                camera.start()
            }
            withAnimation(.easeInOut.delay(0.4)) {
                showGuide = false
            }
        }
        .onDisappear {
            camera.stop()
        }
        .onChange(of: camera.count) { _, value in
            viewModel.updateProgress(value)
            if value >= viewModel.target {
                camera.stop()
                viewModel.succeeded(reps: value, in: context)
            }
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(camera.detectedBody ? WFTheme.success : WFTheme.danger)
                .frame(width: 8, height: 8)
            Text(camera.detectedBody ? "Body detected" : "No body detected")
                .font(WFTheme.font(11, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var guideOverlay: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(WFTheme.gold)
            Text("Angle the phone 45° and keep your full body in frame")
                .font(WFTheme.font(14, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(24)
        .background(.black.opacity(0.55))
        .transition(.opacity)
    }

    private var unavailablePlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 38))
                .foregroundStyle(WFTheme.muted)
            Text("Camera counting isn't available here")
                .font(WFTheme.font(16, weight: .semibold))
                .foregroundStyle(.white)
            Text("On a real device the front camera counts your reps live.")
                .font(WFTheme.font(13))
                .foregroundStyle(WFTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        if let connection = view.videoPreviewLayer.connection, connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
