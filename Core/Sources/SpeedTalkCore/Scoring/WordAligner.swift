import Foundation

public enum WordAlignment: Equatable, Sendable {
    case matched(String)
    case missing(String)
    case extra(String)
    case replaced(expected: String, actual: String)
}

public enum WordAligner {
    public static func align(expected: [String], actual: [String]) -> [WordAlignment] {
        let n = expected.count
        let m = actual.count
        guard n > 0 || m > 0 else { return [] }

        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { dp[i][0] = i }
        for j in 0...m { dp[0][j] = j }

        if n > 0 && m > 0 {
            for i in 1...n {
                for j in 1...m {
                    if expected[i - 1] == actual[j - 1] {
                        dp[i][j] = dp[i - 1][j - 1]
                    } else {
                        dp[i][j] = 1 + min(dp[i - 1][j - 1], dp[i - 1][j], dp[i][j - 1])
                    }
                }
            }
        }

        var result: [WordAlignment] = []
        var i = n
        var j = m
        while i > 0 || j > 0 {
            if i > 0, j > 0, expected[i - 1] == actual[j - 1], dp[i][j] == dp[i - 1][j - 1] {
                result.append(.matched(expected[i - 1]))
                i -= 1
                j -= 1
            } else if i > 0, j > 0, dp[i][j] == dp[i - 1][j - 1] + 1 {
                result.append(.replaced(expected: expected[i - 1], actual: actual[j - 1]))
                i -= 1
                j -= 1
            } else if i > 0, dp[i][j] == dp[i - 1][j] + 1 {
                result.append(.missing(expected[i - 1]))
                i -= 1
            } else {
                result.append(.extra(actual[j - 1]))
                j -= 1
            }
        }
        return result.reversed()
    }
}
