import CoreGraphics
import Foundation

struct TimedTaskLayoutInput: Identifiable, Equatable {
    let id: String
    let startDate: Date
    let endDate: Date

    init(id: String, startDate: Date, endDate: Date) {
        self.id = id
        self.startDate = startDate
        self.endDate = max(endDate, startDate.addingTimeInterval(TaskScheduleValidator.minimumDuration))
    }
}

struct TimedTaskPlacement: Equatable {
    let id: String
    let column: Int
    let columnCount: Int

    var widthFraction: CGFloat {
        1 / CGFloat(max(columnCount, 1))
    }

    var xFraction: CGFloat {
        CGFloat(column) * widthFraction
    }
}

enum CalendarTaskLayoutService {
    static func placements(for inputs: [TimedTaskLayoutInput]) -> [String: TimedTaskPlacement] {
        let sorted = inputs.sorted {
            if $0.startDate == $1.startDate {
                return $0.endDate < $1.endDate
            }
            return $0.startDate < $1.startDate
        }

        var placements: [String: TimedTaskPlacement] = [:]
        var cluster: [TimedTaskLayoutInput] = []
        var clusterEnd: Date?

        for input in sorted {
            guard let currentClusterEnd = clusterEnd else {
                cluster = [input]
                clusterEnd = input.endDate
                continue
            }

            if input.startDate < currentClusterEnd {
                cluster.append(input)
                clusterEnd = max(currentClusterEnd, input.endDate)
            } else {
                placements.merge(layoutCluster(cluster)) { current, _ in current }
                cluster = [input]
                clusterEnd = input.endDate
            }
        }

        if !cluster.isEmpty {
            placements.merge(layoutCluster(cluster)) { current, _ in current }
        }

        return placements
    }

    private static func layoutCluster(_ cluster: [TimedTaskLayoutInput]) -> [String: TimedTaskPlacement] {
        var columnEndDates: [Date] = []
        var assignments: [(id: String, column: Int)] = []

        for input in cluster {
            if let reusableColumn = columnEndDates.firstIndex(where: { $0 <= input.startDate }) {
                columnEndDates[reusableColumn] = input.endDate
                assignments.append((input.id, reusableColumn))
            } else {
                columnEndDates.append(input.endDate)
                assignments.append((input.id, columnEndDates.count - 1))
            }
        }

        let columnCount = max(columnEndDates.count, 1)
        return Dictionary(uniqueKeysWithValues: assignments.map { assignment in
            (
                assignment.id,
                TimedTaskPlacement(
                    id: assignment.id,
                    column: assignment.column,
                    columnCount: columnCount
                )
            )
        })
    }
}
