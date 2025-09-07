//
//  PerformanceMonitor.swift
//  ReadLay
//
//  Created by Mateo Arratia on 8/23/25.
//

import Foundation
import SwiftUI

/// Performance monitoring utility to track performance metrics and identify bottlenecks
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var metrics: [String: PerformanceMetric] = [:]
    @Published var isEnabled = false
    
    private var startTimes: [String: Date] = [:]
    
    private init() {}
    
    // MARK: - Performance Tracking
    
    /// Start timing an operation
    func startTiming(_ operation: String) {
        guard isEnabled else { return }
        startTimes[operation] = Date()
    }
    
    /// End timing an operation and record the metric
    func endTiming(_ operation: String, additionalInfo: [String: Any] = [:]) {
        guard isEnabled, let startTime = startTimes[operation] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let metric = PerformanceMetric(
            operation: operation,
            duration: duration,
            timestamp: Date(),
            additionalInfo: additionalInfo
        )
        
        DispatchQueue.main.async {
            self.metrics[operation] = metric
        }
        
        startTimes.removeValue(forKey: operation)
        
        // Log slow operations
        if duration > 0.1 { // 100ms threshold
            print("⚠️ Performance Warning: \(operation) took \(String(format: "%.3f", duration))s")
        }
    }
    
    /// Measure the performance of a closure
    func measure<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
        startTiming(operation)
        defer { endTiming(operation) }
        return try block()
    }
    
    /// Measure the performance of an async closure
    func measureAsync<T>(_ operation: String, _ block: () async throws -> T) async rethrows -> T {
        startTiming(operation)
        defer { endTiming(operation) }
        return try await block()
    }
    
    // MARK: - Memory Monitoring
    
    /// Get current memory usage
    func getMemoryUsage() -> (used: Int64, total: Int64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let used = Int64(info.resident_size)
            let total = Int64(ProcessInfo.processInfo.physicalMemory)
            return (used, total)
        }
        
        return (0, 0)
    }
    
    // MARK: - Performance Analysis
    
    /// Get the slowest operations
    func getSlowestOperations(limit: Int = 5) -> [PerformanceMetric] {
        return Array(metrics.values.sorted { $0.duration > $1.duration }.prefix(limit))
    }
    
    /// Get average duration for an operation
    func getAverageDuration(for operation: String) -> TimeInterval {
        // This would need to be enhanced to store historical data
        return metrics[operation]?.duration ?? 0
    }
    
    /// Clear all metrics
    func clearMetrics() {
        metrics.removeAll()
        startTimes.removeAll()
    }
    
    /// Export performance report
    func exportReport() -> String {
        var report = "📊 Performance Report\n"
        report += "Generated: \(Date())\n\n"
        
        let sortedMetrics = metrics.values.sorted { $0.duration > $1.duration }
        
        for metric in sortedMetrics {
            report += "\(metric.operation): \(String(format: "%.3f", metric.duration))s\n"
            if !metric.additionalInfo.isEmpty {
                report += "  Additional Info: \(metric.additionalInfo)\n"
            }
        }
        
        let (used, total) = getMemoryUsage()
        let usedMB = Double(used) / 1024 / 1024
        let totalMB = Double(total) / 1024 / 1024
        
        report += "\n💾 Memory Usage: \(String(format: "%.1f", usedMB))MB / \(String(format: "%.1f", totalMB))MB"
        
        return report
    }
}

// MARK: - Performance Metric

struct PerformanceMetric: Identifiable {
    let id = UUID()
    let operation: String
    let duration: TimeInterval
    let timestamp: Date
    let additionalInfo: [String: Any]
    
    var formattedDuration: String {
        if duration < 0.001 {
            return String(format: "%.0fμs", duration * 1_000_000)
        } else if duration < 1 {
            return String(format: "%.1fms", duration * 1000)
        } else {
            return String(format: "%.3fs", duration)
        }
    }
}

// MARK: - Performance View Modifier

struct PerformanceModifier: ViewModifier {
    let operation: String
    let monitor: PerformanceMonitor
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                monitor.startTiming(operation)
            }
            .onDisappear {
                monitor.endTiming(operation)
            }
    }
}

extension View {
    /// Monitor the performance of a view's lifecycle
    func monitorPerformance(_ operation: String, monitor: PerformanceMonitor = .shared) -> some View {
        modifier(PerformanceModifier(operation: operation, monitor: monitor))
    }
}

// MARK: - Performance Debug View

struct PerformanceDebugView: View {
    @ObservedObject var monitor = PerformanceMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Performance Monitor")
                    .font(.headline)
                
                Spacer()
                
                Button(monitor.isEnabled ? "Disable" : "Enable") {
                    monitor.isEnabled.toggle()
                }
                .buttonStyle(.bordered)
            }
            
            if monitor.isEnabled {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(monitor.getSlowestOperations()) { metric in
                            HStack {
                                Text(metric.operation)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(metric.formattedDuration)
                                    .font(.caption)
                                    .foregroundColor(metric.duration > 0.1 ? .red : .green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
                .frame(maxHeight: 200)
                
                Button("Export Report") {
                    let report = monitor.exportReport()
                    print(report)
                }
                .buttonStyle(.bordered)
            } else {
                Text("Performance monitoring is disabled")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
