import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var inspirations: [Inspiration]
    @Query private var categories: [Category]
    @State private var animateChart = false
    
    var categoryCounts: [(String, Int)] {
        let validCategoryNames = Set(categories.map { $0.name })
        
        // 统计所有灵感，如果分类已删除，则归类为"未分类"
        var counts: [String: Int] = [:]
        
        for inspiration in inspirations {
            let catName = validCategoryNames.contains(inspiration.category) ? inspiration.category : "未分类"
            counts[catName, default: 0] += 1
        }
        
        return counts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    var completionStats: [(String, Int)] {
        let completed = inspirations.filter { $0.isCompleted }.count
        let total = inspirations.count
        return [
            ("已完成", completed),
            ("进行中", total - completed)
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("数据统计")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 20) {
                    StatCard(title: "总灵感", value: "\(inspirations.count)", color: .blue, delay: 0)
                    StatCard(title: "已完成", value: "\(inspirations.filter { $0.isCompleted }.count)", color: .green, delay: 0.1)
                    StatCard(title: "置顶中", value: "\(inspirations.filter { $0.isPinned }.count)", color: .orange, delay: 0.2)
                }
                
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("完成情况 (进行中 vs 已完成)")
                            .font(.headline)
                        
                        if inspirations.isEmpty {
                            Text("暂无数据")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 250)
                        } else {
                            Chart {
                                ForEach(completionStats, id: \.0) { item in
                                    SectorMark(
                                        angle: .value("数量", animateChart ? item.1 : 0),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .cornerRadius(5)
                                    .foregroundStyle(by: .value("状态", item.0))
                                    .annotation(position: .overlay) {
                                        if item.1 > 0 && animateChart {
                                            Text("\(item.1)")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .frame(height: 250)
                            .chartForegroundStyleScale([
                                "已完成": Color.green,
                                "进行中": Color.blue
                            ])
                            .chartLegend(position: .bottom, spacing: 12)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateChart)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                    .scaleEffect(animateChart ? 1 : 0.95)
                    .opacity(animateChart ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animateChart)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("分类统计 (不同类别占比)")
                            .font(.headline)
                        
                        if categoryCounts.isEmpty {
                            Text("暂无数据")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 250)
                        } else {
                            Chart {
                                ForEach(categoryCounts, id: \.0) { item in
                                    SectorMark(
                                        angle: .value("数量", animateChart ? item.1 : 0),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .cornerRadius(5)
                                    .foregroundStyle(by: .value("分类", item.0))
                                    .annotation(position: .overlay) {
                                        if item.1 > 0 && animateChart {
                                            Text("\(item.1)")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .frame(height: 250)
                            .chartLegend(position: .bottom, spacing: 12)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateChart)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                    .scaleEffect(animateChart ? 1 : 0.95)
                    .opacity(animateChart ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animateChart)
                }
            }
            .padding()
        }
        .navigationTitle("统计报表")
        .onAppear {
            animateChart = false
            withAnimation {
                animateChart = true
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let delay: Double
    @State private var show = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .offset(y: show ? 0 : 20)
        .opacity(show ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                show = true
            }
        }
    }
}
