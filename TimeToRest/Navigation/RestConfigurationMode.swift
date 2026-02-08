enum RestConfigurationMode: Identifiable, Equatable {
    case mandatory   // primer uso
    case editable    // edición posterior

    var id: String {
        switch self {
        case .mandatory: return "mandatory"
        case .editable: return "editable"
        }
    }
}
