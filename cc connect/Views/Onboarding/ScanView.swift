//
//  ScanView.swift
//  cc connect
//
//  Created by alchain on 2026/1/21.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ScanView: View {
    let onPaired: (Session) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var scannedCode: String?
    @State private var manualCode = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showManualInput = false
    @State private var showStartupOptions = false
    @State private var pairedSession: Session?

    var body: some View {
        NavigationStack {
            VStack(spacing: CCSpacing.xxl) {
                // Header
                Text("将摄像头对准终端上的二维码")
                    .font(.ccBody)
                    .foregroundColor(.ccTextSecondary)
                    .padding(.top, CCSpacing.xl)

                // Camera View
                ZStack {
                    CameraPreviewView(onCodeScanned: handleScannedCode)
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(CCRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: CCRadius.lg)
                                .stroke(Color.ccBorder, lineWidth: 2)
                        )

                    if isConnecting {
                        Color.black.opacity(0.6)
                            .cornerRadius(CCRadius.lg)

                        VStack(spacing: CCSpacing.md) {
                            ProgressView()
                                .tint(.white)
                            Text("正在连接...")
                                .font(.ccBody)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, CCSpacing.xxxl)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.ccFootnote)
                        .foregroundColor(.ccError)
                        .padding(.horizontal)
                }

                Divider()
                    .padding(.horizontal, CCSpacing.xxxl)

                // Manual input toggle
                Button {
                    showManualInput.toggle()
                } label: {
                    Text(showManualInput ? "使用摄像头扫描" : "手动输入配对码")
                        .font(.ccSubheadline)
                        .foregroundColor(.ccPrimary)
                }

                if showManualInput {
                    VStack(spacing: CCSpacing.md) {
                        TextField("cc://xxxxxx:xxxxxx", text: $manualCode)
                            .font(.ccTerminal)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(CCSpacing.md)
                            .background(Color.ccSurfaceSecondary)
                            .cornerRadius(CCRadius.sm)
                            .padding(.horizontal, CCSpacing.xxxl)

                        CCPrimaryButton(
                            title: "确认",
                            action: { handleScannedCode(manualCode) },
                            isLoading: isConnecting,
                            isDisabled: manualCode.isEmpty
                        )
                        .padding(.horizontal, CCSpacing.xxxl)
                    }
                }

                Spacer()
            }
            .background(Color.ccBackground)
            .navigationTitle("扫描二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.ccPrimary)
                }
            }
            .fullScreenCover(isPresented: $showStartupOptions) {
                startupOptionsSheet
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        guard !isConnecting else { return }
        guard let pairingInfo = PairingInfo.parse(from: code) else {
            errorMessage = "无效的配对码"
            return
        }

        isConnecting = true
        errorMessage = nil

        // 查找是否已存在相同 ID 的会话
        let sessionId = pairingInfo.sessionId
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == sessionId }
        )

        let existingSession: Session?
        do {
            existingSession = try modelContext.fetch(descriptor).first
        } catch {
            print("⚠️ 查询会话失败: \(error)")
            existingSession = nil
        }

        let session: Session
        if let existing = existingSession {
            // 更新现有会话
            print("📝 更新现有会话: \(existing.id)")
            existing.name = pairingInfo.sessionName ?? existing.name
            existing.secret = pairingInfo.secret
            existing.status = .idle
            existing.lastActivity = Date()
            existing.isConnected = true
            session = existing
        } else {
            // 创建新会话
            let sessionName = pairingInfo.sessionName ?? "新会话"
            let newSession = Session(
                id: pairingInfo.sessionId,
                name: sessionName,
                status: .idle,
                lastActivity: Date(),
                isConnected: true,
                deviceName: "MacBook Pro"
            )
            newSession.secret = pairingInfo.secret
            modelContext.insert(newSession)
            print("📝 创建新会话: \(newSession.id)")
            session = newSession
        }

        // 保存更改
        try? modelContext.save()

        isConnecting = false

        // 显示启动选项
        pairedSession = session
        showStartupOptions = true
    }
}

// MARK: - Startup Options Sheet Extension

extension ScanView {
    @ViewBuilder
    var startupOptionsSheet: some View {
        if let session = pairedSession {
            StartupOptionsView(
                session: session,
                onStartClaude: {
                    // 发送 claude 命令启动
                    session.pendingStartupCommand = "claude"
                    showStartupOptions = false
                    onPaired(session)
                },
                onStartWithFlags: {
                    // 发送 claude --dangerously-skip-permissions
                    session.pendingStartupCommand = "claude --dangerously-skip-permissions"
                    showStartupOptions = false
                    onPaired(session)
                },
                onWait: {
                    // 不发送命令，直接进入会话
                    session.pendingStartupCommand = nil
                    showStartupOptions = false
                    onPaired(session)
                }
            )
        }
    }
}

// MARK: - Server Configuration
enum ServerConfig {
    static let relayServer = "wss://cc-connect.alchaincyf.workers.dev"
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = CameraPreview()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        private var hasScanned = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue,
                  stringValue.hasPrefix("cc://") else {
                return
            }

            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            DispatchQueue.main.async {
                self.onCodeScanned(stringValue)
            }
        }
    }
}

class CameraPreview: UIView {
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    private var captureSession: AVCaptureSession?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              session.canAddInput(videoInput) else {
            return
        }

        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first?.frame = bounds

        if let delegate = delegate {
            captureSession?.outputs
                .compactMap { $0 as? AVCaptureMetadataOutput }
                .forEach { $0.setMetadataObjectsDelegate(delegate, queue: .main) }
        }
    }
}

#Preview {
    ScanView(onPaired: { _ in })
}
