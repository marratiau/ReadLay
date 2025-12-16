import SwiftUI

struct ActiveEngagementBetRowView: View {
    let bet: EngagementBet
    let readSlipViewModel: ReadSlipViewModel  // kept to match call sites

    // Derived values so the body stays light and compile-friendly
    private var completedGoals: Int {
        bet.goals.filter { $0.isCompleted }.count
    }

    private var totalGoals: Int {
        bet.goals.count
    }

    private var progressPercentage: Double {
        guard totalGoals > 0 else { return 0 }
        return Double(completedGoals) / Double(totalGoals)
    }

    private var allGoalsCompleted: Bool {
        completedGoals == totalGoals && totalGoals > 0
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            goalsList
            footer
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            allGoalsCompleted ? Color.green.opacity(0.3)
                                              : Color.goodreadsAccent.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(.goodreadsBrown)
                    Text("Engagement Goals")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }

                Text(bet.book.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("$\(bet.wager, specifier: "%.0f") bet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsBrown.opacity(0.8))

                    Text("•")
                        .foregroundColor(.goodreadsAccent.opacity(0.5))

                    Text("Win $\(bet.potentialWin, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(bet.odds)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )

                Text("\(Int(progressPercentage * 100))% complete")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.goodreadsAccent.opacity(0.8))
            }
        }
    }

    private var goalsList: some View {
        VStack(spacing: 8) {
            ForEach(bet.goals) { goal in
                GoalRow(goal: goal)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Overall Progress")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.goodreadsAccent)

            Spacer()

            Text("\(completedGoals)/\(totalGoals) goals complete")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.goodreadsBrown)
        }
    }
}

// MARK: - Goal Row

private struct GoalRow: View {
    let goal: EngagementGoal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: goal.type.icon)
                .font(.system(size: 16))
                .foregroundColor(.goodreadsAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.type.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsBrown)

                Text("\(goal.currentCount)/\(goal.targetCount) completed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
            }

            Spacer()

            ProgressBadge(isCompleted: goal.isCompleted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(goal.isCompleted ? Color.green.opacity(0.1)
                                       : Color.goodreadsBeige.opacity(0.5))
        )
    }
}

// MARK: - Tiny badge view

private struct ProgressBadge: View {
    let isCompleted: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(isCompleted ? Color.green : Color.goodreadsAccent.opacity(0.3), lineWidth: 2)
                .frame(width: 20, height: 20)

            if isCompleted {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 20, height: 20)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .frame(width: 20 as CGFloat, height: 20 as CGFloat)
    }
}
