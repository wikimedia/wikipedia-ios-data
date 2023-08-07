import Foundation

public enum WKProject: Equatable, Hashable {
    public static func == (lhs: WKProject, rhs: WKProject) -> Bool {
        switch lhs {
        case .wikipedia(let lhsLanguage):
            switch rhs {
            case .wikipedia(let rhsLanguage):
                return lhsLanguage == rhsLanguage
            default:
                return false
            }
        case .commons:
            switch rhs {
            case .commons:
                return true
            default:
                return false
            }
        case .wikidata:
            switch rhs {
            case .wikidata:
                return true
            default:
                return false
            }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .wikipedia(let language):
            hasher.combine("wikipedia")
            hasher.combine(language.languageCode)
            hasher.combine(language.languageVariantCode)
        case .wikidata:
            hasher.combine("wikidata")
        case .commons:
            hasher.combine("commons")
        }
    }
    
    case wikipedia(WKLanguage)
    case wikidata
    case commons
    
    static func projectsFromLanguages(languages: [WKLanguage]) -> [WKProject] {
        return languages.map { .wikipedia($0) }
    }
    
    var languageVariantCode: String? {
        switch self {
        case .wikipedia(let language):
            return language.languageVariantCode
        default:
            break
        }
        
        return nil
    }
}
