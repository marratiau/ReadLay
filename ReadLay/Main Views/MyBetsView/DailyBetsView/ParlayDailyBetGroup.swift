import SwiftUI

struct ParlayDailyBetGroup: View {
    let parlayId: UUID
    let dailyBets: [DailyBet]
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    let onStartReading: (DailyBet) -> Void
    let onStartNextDay: (DailyBet) -> Void

    private var parlayInfo: ParlayBet? {
        readSlipViewModel.activeParlays.first { $0.id == parlayId }
    }
    private var parlayOdds: String { parlayInfo?.combinedOdds ?? "+100" }
    private var legCount: Int { parlayInfo?.totalLegs ?? dailyBets.count }
    private var allLegsComplete: Bool {
        dailyBets.allSatisfy { readSlipViewModel.getDailyProgress(for: $0.betId) >= $0.dailyGoal }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack(alignment: .leading) {
                ConnectorColumn(allComplete: allLegsComplete)
                    .frame(width: 48)

                VStack(spacing: 8) {
                    ForEach(dailyBets, id: \.id) { bet in
                        let currentProgress = readSlipViewModel.getDailyProgress(for: bet.betId)
                        let canNextDay: Bool = {
                            guard let rb = readSlipViewModel.placedBets.first(where: { $0.id == bet.betId }) else { return false }
                            let currentPage = readSlipViewModel.getCurrentPagePosition(for: bet.betId)
                            let target = rb.pagesPerDay * rb.currentDay
                            return currentPage >= target && rb.currentDay < rb.totalDays
                        }()

                        DailyParlayLegRow(
                            bet: bet,
                            currentProgress: currentProgress,
                            isFirstLeg: bet.id == dailyBets.first?.id,
                            isLastLeg: bet.id == dailyBets.last?.id,
                            canStartNextDay: canNextDay,
                            onStartReading: { onStartReading(bet) },
                            onStartNextDay: { onStartNextDay(bet) }
                        )
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .modifier(CardBackground(isComplete: allLegsComplete))
    }

    private var header: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "link").font(.system(size: 12, weight: .bold))
                Text("\(legCount) LEG PARLAY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.goodreadsBrown))

            Spacer()

            Text(parlayOdds)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.goodreadsBrown)

            if allLegsComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(Color.goodreadsBeige.opacity(0.5))
    }
}

private struct ConnectorColumn: View {
    let allComplete: Bool
    var body: some View {
        GeometryReader { proxy in
            let lineColor: Color = allComplete ? .green : Color.goodreadsAccent.opacity(0.3)
            Path { path in
                path.move(to: CGPoint(x: 24, y: 0))
                path.addLine(to: CGPoint(x: 24, y: proxy.size.height))
            }
            .stroke(lineColor, style: StrokeStyle(lineWidth: 2))
        }
    }
}

private struct DailyParlayLegRow: View {
    let bet: DailyBet
    let currentProgress: Int
    let isFirstLeg: Bool
    let isLastLeg: Bool
    let canStartNextDay: Bool
    let onStartReading: () -> Void
    let onStartNextDay: () -> Void

    private var isCompleted: Bool { currentProgress >= bet.dailyGoal }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Day \(bet.dayNumber)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsAccent)
                    if bet.isNextDay {
                        Text("(Tomorrow)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }

                Text(bet.book.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(1)

                Text("Pages \(bet.pageRange) • \(currentProgress)/\(bet.dailyGoal)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onStartReading) {
                    HStack(spacing: 6) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "book.fill")
                            .font(.system(size: 13))
                        Text(isCompleted ? "Done" : "Start")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(isCompleted ? .green : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCompleted ? Color.green.opacity(0.15) : Color.goodreadsBrown)
                    )
                }
                .disabled(isCompleted)

                Button(action: onStartNextDay) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 12))
                        Text("Next Day")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(canStartNextDay ? Color.orange : Color.gray.opacity(0.4))
                    )
                }
                .disabled(!canStartNextDay)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.goodreadsBeige.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.goodreadsAccent.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

private struct CardBackground: ViewModifier {
    let isComplete: Bool
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.goodreadsWarm))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isComplete ? Color.green.opacity(0.3) : Color.goodreadsAccent.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
