import Foundation

public struct Curriculum: Codable, Sendable {
    public struct Plan: Codable, Sendable, Identifiable {
        public struct Stage: Codable, Sendable, Identifiable {
            public struct Unit: Codable, Sendable {
                public struct Day: Codable, Sendable, Identifiable {
                    public let day: Int
                    public let title: String
                    public let phraseIDs: [String]
                    public var id: Int { day }

                    public init(day: Int, title: String, phraseIDs: [String]) {
                        self.day = day
                        self.title = title
                        self.phraseIDs = phraseIDs
                    }
                }

                public let index: Int
                public let title: String
                public let days: [Day]

                public init(index: Int, title: String, days: [Day]) {
                    self.index = index
                    self.title = title
                    self.days = days
                }
            }

            public let id: String
            public let title: String
            public let units: [Unit]

            public init(id: String, title: String, units: [Unit]) {
                self.id = id
                self.title = title
                self.units = units
            }

            public var days: [Unit.Day] { units.flatMap(\.days) }
        }

        public let id: String
        public let title: String
        public let subtitle: String
        public let stages: [Stage]

        public init(id: String, title: String, subtitle: String, stages: [Stage]) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.stages = stages
        }
    }

    public let version: Int
    public let plans: [Plan]

    public init(version: Int, plans: [Plan]) {
        self.version = version
        self.plans = plans
    }

    public func plan(id: String) -> Plan? { plans.first { $0.id == id } }
}
