import Foundation

class AIService {
    static let shared = AIService()
    
    // 智谱 AI 配置
    private var apiKey: String = ""
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    
    private init() {}
    
    func setApiKey(_ key: String) {
        self.apiKey = key
    }
    
    /// 使用智谱 AI 接口规范进行分类
    func classifyInspiration(title: String, notes: String, availableCategories: [String]) async -> String {
        // 如果没有 API Key，使用提供的默认 Key 或模拟分类
        let currentKey = apiKey.isEmpty ? "7ddcdd2dda7a418c914c1c1be096bfe6.jNMHlHKtlEK2IdwF" : apiKey
        
        let prompt = """
        你是一个灵感分类助手。请根据以下灵感的标题和内容，从给定的类别列表中选择最合适的一个。
        只返回类别名称，不要有任何其他解释。
        
        标题: \(title)
        内容: \(notes)
        
        候选类别: \(availableCategories.joined(separator: ", "))
        
        如果不确定，请返回"未分类"。
        """
        
        guard let url = URL(string: baseURL) else { return "未分类" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(currentKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "glm-4.5-flash",
            "messages": [
                ["role": "system", "content": "你是一个负责灵感记录的灵感分类助手"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
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
                let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                return availableCategories.contains(cleanedContent) ? cleanedContent : "未分类"
            }
        } catch {
            print("AI 分类请求失败: \(error)")
        }
        
        return "未分类"
    }
    
    private func mockClassify(title: String, notes: String) async -> String {
        // 模拟网络延迟
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
