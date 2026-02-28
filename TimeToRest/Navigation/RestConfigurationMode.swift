enum RestConfigurationMode: Identifiable, Equatable {
    case mandatory
    case editable

    var id: String {
        switch self {
        case .mandatory: return "mandatory"
        case .editable: return "editable"
        }
    }
}
