import SwiftUI

struct CalendarView: View {
    let daysWithMemos: Set<Int>
    let onSelectDay: (Int) -> Void

    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }()

    var body: some View {
        VStack(spacing: 8) {
            monthHeader
            weekdayLabels
            daysGrid
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.app_bg)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(monthYearString)
                .font(.system(size: 15, weight: .bold, design: .serif))
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(reorderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Days Grid

    private var daysGrid: some View {
        let data = calendarDays()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(data, id: \.id) { item in
                dayCell(item)
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ item: CalendarDay) -> some View {
        if item.day == 0 {
            Color.clear.frame(height: 36)
        } else {
            let dayId = dayIdentifier(for: item.day)
            let isToday = dayId == DateHelper.todayIdentifier()
            let hasMemos = daysWithMemos.contains(dayId)

            Button {
                if hasMemos { onSelectDay(dayId) }
            } label: {
                VStack(spacing: 2) {
                    Text("\(item.day)")
                        .font(.system(size: 15, weight: isToday ? .bold : .regular))
                        .foregroundColor(isToday ? .white : .primary)
                        .frame(width: 30, height: 30)
                        .background {
                            if isToday {
                                Circle().fill(Color.app_accent)
                            }
                        }
                    Circle()
                        .fill(hasMemos ? Color.app_accent : Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .disabled(!hasMemos)
            .frame(height: 36)
        }
    }

    // MARK: - Helpers

    private var monthYearString: String {
        DateHelper.format(displayedMonth, dateFormat: "yyyy.M")
    }

    private var reorderedWeekdaySymbols: [String] {
        let first = calendar.firstWeekday - 1
        return Array(weekdaySymbols[first...]) + Array(weekdaySymbols[..<first])
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func dayIdentifier(for day: Int) -> Int {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        return comps.year! * 10000 + comps.month! * 100 + day
    }

    private func calendarDays() -> [CalendarDay] {
        var result = [CalendarDay]()
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return result
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7

        for i in 0..<offset {
            result.append(CalendarDay(id: -i - 1, day: 0))
        }
        for day in range {
            result.append(CalendarDay(id: day, day: day))
        }
        return result
    }
}

private struct CalendarDay {
    let id: Int
    let day: Int
}
