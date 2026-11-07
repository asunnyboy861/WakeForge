import SwiftUI
import SwiftData
import UIKit

struct PhotoTaskView: View {
    @ObservedObject var viewModel: TaskRunnerViewModel
    let context: ModelContext

    @State private var image: UIImage?
    @State private var isVerifying = false
    @State private var verdict: PhotoVerdict?
    @State private var showPicker = false
    @State private var pickerFailed = false

    private let prompt = "a clear view of the sky through a window or from outside"

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Take a photo of the sky")
                    .font(WFTheme.font(24, weight: .bold))
                    .foregroundStyle(.white)
                Text("Any angle works. Daylight is easier to verify.")
                    .font(WFTheme.font(13))
                    .foregroundStyle(WFTheme.muted)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(WFTheme.surface)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 34))
                            .foregroundStyle(WFTheme.muted)
                        Text("No photo yet")
                            .font(WFTheme.font(14))
                            .foregroundStyle(WFTheme.muted)
                    }
                }
                if isVerifying {
                    Color.black.opacity(0.6)
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(WFTheme.gold)
                        Text("Verifying…")
                            .font(WFTheme.font(14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 280)
            .padding(.horizontal, 20)

            if let verdict {
                verdictCard(verdict)
            } else {
                HStack(spacing: 12) {
                    Button {
                        showPicker = true
                    } label: {
                        Label(image == nil ? "Take photo" : "Retake", systemImage: "camera.fill")
                    }
                    .buttonStyle(WFPrimaryButtonStyle())
                    .disabled(isVerifying)

                    Button {
                        viewModel.manualConfirm(in: context)
                    } label: {
                        Text("Confirm manually")
                    }
                    .buttonStyle(WFSecondaryButtonStyle())
                }
                .padding(.horizontal, 20)
            }

            if pickerFailed {
                Text("Camera isn't available here. Use the photo library or switch tasks.")
                    .font(WFTheme.font(12))
                    .foregroundStyle(WFTheme.muted)
            }
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(onImage: handleImage)
        }
    }

    private func verdictCard(_ verdict: PhotoVerdict) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: verdict.manualFallback ? "questionmark.circle.fill" : (verdict.passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"))
                    .foregroundStyle(verdict.manualFallback ? WFTheme.gold : (verdict.passed ? WFTheme.success : WFTheme.danger))
                Text(verdict.manualFallback ? "Manual check needed" : (verdict.passed ? "Photo verified" : "Could not verify"))
                    .font(WFTheme.font(15, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(verdict.reason)
                .font(WFTheme.font(13))
                .foregroundStyle(WFTheme.muted)
                .multilineTextAlignment(.center)
            if verdict.manualFallback {
                Button("I took the photo") {
                    viewModel.manualConfirm(in: context)
                }
                .buttonStyle(WFPrimaryButtonStyle())
            } else if !verdict.passed {
                Button("Retake photo") {
                    self.verdict = nil
                    showPicker = true
                }
                .buttonStyle(WFPrimaryButtonStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func handleImage(_ uiImage: UIImage) {
        guard let data = uiImage.compressedJPEG() else { return }
        image = uiImage
        verdict = nil
        isVerifying = true
        Task {
            let result = await AIProviderRouter.shared.verifyPhoto(jpeg: data, prompt: prompt)
            isVerifying = false
            verdict = result
            if result.passed {
                viewModel.succeeded(reps: 1, in: context)
            } else if !result.manualFallback {
                viewModel.registerFailure(reason: result.reason)
            }
            try? await Task.sleep(for: .seconds(10))
            image = nil
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            controller.sourceType = .camera
            controller.cameraDevice = .front
        } else {
            controller.sourceType = .photoLibrary
        }
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void

        init(onImage: @escaping (UIImage) -> Void) {
            self.onImage = onImage
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

extension UIImage {
    func compressedJPEG(maxBytes: Int = 1_000_000) -> Data? {
        var quality: CGFloat = 0.7
        var data = jpegData(compressionQuality: quality)
        while let current = data, current.count > maxBytes, quality > 0.2 {
            quality -= 0.1
            data = jpegData(compressionQuality: quality)
        }
        return data
    }
}
