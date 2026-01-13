import SwiftUI

/// 设置视图：配置 AI 模型（如 API Key）和其他应用偏好
struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey: String = "" // 使用 AppStorage 持久化 API Key
    @State private var showingSaveAlert = false                  // 保存成功提示
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("偏好设置")
                    .font(.system(size: 28, weight: .bold))
                
                // 1. AI 配置区域
                VStack(alignment: .leading, spacing: 16) {
                    Label("AI 智能配置", systemImage: "sparkles")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API Key (智谱 AI / OpenAI 兼容接口)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        SecureField("请输入您的 API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 400)
                        
                        Text("用于灵感的智能自动分类。如果不填写，将使用系统内置演示 Key。")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.8))
                        
                        Button("保存配置") {
                            showingSaveAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(12)
                }
                
                // 2. 关于应用
                VStack(alignment: .leading, spacing: 16) {
                    Label("关于灵机一记", systemImage: "info.circle.fill")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("版本: 1.0.0 (Build 20240113)")
                        Text("灵机一记是一款专为 macOS 设计的轻量级灵感记录工具，支持 AI 智能分类与时间提醒。")
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .font(.system(size: 13))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(40)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .alert("设置已保存", isPresented: $showingSaveAlert) {
            Button("好", role: .cancel) { }
        }
    }
}
