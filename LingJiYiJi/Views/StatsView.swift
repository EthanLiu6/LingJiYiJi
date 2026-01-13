import SwiftUI
import SwiftData

/// 统计视图：展示灵感记录的汇总数据、分类占比以及最近完成情况
struct StatsView: View {
    @Query private var inspirations: [Inspiration]
    @Query private var categories: [Category]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("数据统计")
                    .font(.system(size: 28, weight: .bold))
                
                // 1. 顶部总览卡片
                HStack(spacing: 20) {
                    statCard(title: "总灵感", count: inspirations.count, color: .blue, icon: "lightbulb.fill")
                    statCard(title: "已完成", count: inspirations.filter { $0.isCompleted }.count, color: .green, icon: "checkmark.circle.fill")
                    statCard(title: "待处理", count: inspirations.filter { !$0.isCompleted }.count, color: .orange, icon: "clock.fill")
                }
                
                // 2. 分类占比分析
                VStack(alignment: .leading, spacing: 16) {
                    Text("分类占比")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        ForEach(categories) { category in
                            let count = inspirations.filter { $0.category == category.name }.count
                            let percentage = inspirations.isEmpty ? 0 : Double(count) / Double(inspirations.count)
                            
                            categoryRow(name: category.name, count: count, percentage: percentage)
                        }
                        
                        // 处理未在分类列表中的灵感（如果有）
                        let otherCount = inspirations.filter { insp in !categories.contains(where: { $0.name == insp.category }) }.count
                        if otherCount > 0 {
                            let percentage = Double(otherCount) / Double(inspirations.count)
                            categoryRow(name: "其他", count: otherCount, percentage: percentage)
                        }
                    }
                    .padding()
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(12)
                }
                
                // 3. 最近 7 天完成情况（占位展示，可后续扩展）
                VStack(alignment: .leading, spacing: 16) {
                    Text("完成趋势")
                        .font(.headline)
                    
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(0..<7) { day in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor.opacity(0.6))
                                    .frame(width: 30, height: CGFloat.random(in: 20...100))
                                Text("\(7-day)d")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 120)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(12)
                }
            }
            .padding(40)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
    
    // MARK: - 辅助组件
    
    /// 构建统计概览卡片
    private func statCard(title: String, count: Int, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    /// 构建分类进度条行
    private func categoryRow(name: String, count: Int, percentage: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 13))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.05))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(percentage))
                }
            }
            .frame(height: 4)
        }
    }
}
