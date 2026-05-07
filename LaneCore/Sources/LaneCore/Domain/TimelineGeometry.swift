import Foundation

struct TimelineGeometry {
    let viewportStart: Date
    let dayWidth: CGFloat
    let calendar: Calendar = Calendar(identifier: .gregorian)

    func x(for date: Date) -> CGFloat {
        let days = calendar.dateComponents([.day],
            from: calendar.startOfDay(for: viewportStart),
            to: calendar.startOfDay(for: date)).day ?? 0
        return CGFloat(days) * dayWidth
    }

    func width(from: Date, to: Date) -> CGFloat {
        let days = calendar.dateComponents([.day],
            from: calendar.startOfDay(for: from),
            to: calendar.startOfDay(for: to)).day ?? 0
        return CGFloat(days + 1) * dayWidth
    }

    static func progress(start: Date, end: Date, today: Date) -> Double {
        let cal = Calendar(identifier: .gregorian)
        let sd = cal.startOfDay(for: start)
        let ed = cal.startOfDay(for: end)
        let td = cal.startOfDay(for: today)
        guard ed >= sd else { return 0 }
        if td <= sd { return 0 }
        if td >= ed { return 1 }
        let total = ed.timeIntervalSince(sd)
        let elapsed = td.timeIntervalSince(sd)
        return elapsed / total
    }

    static func quantize(_ p: Double) -> Double {
        let q = (p * 4 + 0.375).rounded(.down) / 4
        return min(max(q, 0), 1)
    }
}
