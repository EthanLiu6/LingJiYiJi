import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var inspirations: [Inspiration]
    
    var categoryCounts: [(String, Int)] {
        let counts = Dictionary(grouping: inspirations, by: { $0.category })
            .mapValues { $0.count }
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
                    StatCard(title: "总灵感", value: "\(inspirations.count)", color: .blue)
                    StatCard(title: "已完成", value: "\(inspirations.filter { $0.isCompleted }.count)", color: .green)
                    StatCard(title: "置顶中", value: "\(inspirations.filter { $0.isPinned }.count)", color: .orange)
                }
                
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("完成情况 (已记录 vs 已完成)")
                            .font(.headline)
                        
                        if inspirations.isEmpty {
                            Text("暂无数据")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 250)
                        } else {
                            Chart {
                                ForEach(completionStats, id: \.0) { item in
                                    SectorMark(
                                        angle: .value("数量", item.1),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .cornerRadius(5)
                                    .foregroundStyle(by: .value("状态", item.0))
                                    .annotation(position: .overlay) {
                                        if item.1 > 0 {
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
                                        angle: .value("数量", item.1),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .cornerRadius(5)
                                    .foregroundStyle(by: .value("分类", item.0))
                                    .annotation(position: .overlay) {
                                        if item.1 > 0 {
                                            Text("\(item.1)")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .frame(height: 250)
                            .chartLegend(position: .bottom, spacing: 12)
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
                }
            }
            .padding()
        }
        .navigationTitle("统计报表")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
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
    }
}
