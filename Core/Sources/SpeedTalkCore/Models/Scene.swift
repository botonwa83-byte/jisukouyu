import Foundation

public enum Scene: String, Codable, CaseIterable, Sendable {
    case life, transit, dining, work, campus, social, emergency, slang

    public var title: String {
        switch self {
        case .life: return "生活"
        case .transit: return "出行"
        case .dining: return "餐饮"
        case .work: return "职场"
        case .campus: return "校园"
        case .social: return "社交"
        case .emergency: return "应急"
        case .slang: return "地道表达"
        }
    }

    public var symbol: String {
        switch self {
        case .life: return "house"
        case .transit: return "airplane"
        case .dining: return "fork.knife"
        case .work: return "briefcase"
        case .campus: return "graduationcap"
        case .social: return "person.2"
        case .emergency: return "exclamationmark.triangle"
        case .slang: return "text.bubble"
        }
    }
}

public enum Register: String, Codable, Sendable {
    case casual, neutral, formal, avoid

    public var title: String {
        switch self {
        case .casual: return "随口说"
        case .neutral: return "通用"
        case .formal: return "正式"
        case .avoid: return "少用"
        }
    }
}
