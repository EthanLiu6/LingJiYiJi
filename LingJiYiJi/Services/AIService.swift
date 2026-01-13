import Foundation

/// AI 服务类：对接智谱 AI (BigModel) 接口，实现灵感的智能分类
class AIService {
    static let shared = AIService()
    
    // 智谱 AI 配置信息
    private var apiKey: String = ""
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    
    private init() {}
    
    /// 设置 API Key（通常从设置页面传入）
    func setApiKey(_ key: String) {
        self.apiKey = key
    }
    
    /// 调用 AI 接口对灵感进行智能分类
    /// - Parameters:
    ///   - title: 灵感标题
    ///   - notes: 灵感备注
    ///   - availableCategories: 当前用户已创建的所有分类名称列表
    /// - Returns: 返回匹配到的最合适的分类名称
    func classifyInspiration(title: String, notes: String, availableCategories: [String]) async -> String {
        // 如果用户未设置 API Key，使用内置的默认 Key（或提示用户设置）
        let currentKey = apiKey.isEmpty ? "" : apiKey
        
        // 构建提示词（Prompt），要求 AI 只返回分类名称
        let prompt = """
        你是一个灵感分类助手。请根据以下灵感的标题和内容，从给定的类别列表中选择最合适的一个。
        只返回类别名称，不要有任何其他解释。
        
        标题: \(title)
        内容: \(notes)
        
        候选类别: \(availableCategories.joined(separator: ", "))
        
        如果不确定或者不符合罗列的类别，请返回"未分类"。
        """
        
        guard let url = URL(string: baseURL) else { return "未分类" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(currentKey)", forHTTPHeaderField: "Authorization")
        
        // 构建符合 OpenAI/智谱 API 规范的请求体
        let body: [String: Any] = [
            "model": "glm-4.5-flash", // 使用高性能低延迟的模型
            "messages": [
                ["role": "system", "content": "你是一个负责灵感记录的灵感分类助手"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3, // 较低的温度值使输出更具确定性
            "thinking": [
                "enable": false
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // 清理 AI 返回的结果字符串
                let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 验证 AI 返回的分类是否在可选列表中
                return availableCategories.contains(cleanedContent) ? cleanedContent : "未分类"
            }
        } catch {
            print("AI 分类请求失败: \(error)")
        }
        
        return "未分类"
    }
    
    /// 本地模拟分类逻辑（备用或测试用）
    private func mockClassify(title: String, notes: String) async -> String {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let text = (title + notes).lowercased()
        if text.contains("工作") || text.contains("会议") || text.contains("项目") {
            return "工作"
        } else if text.contains("学习") || text.contains("阅读") || text.contains("课程") {
            return "学习"
        } else if text.contains("买") || text.contains("去") || text.contains("吃") {
            return "生活"
        }
        return "未分类"
    }
}
