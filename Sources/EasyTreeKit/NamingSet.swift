public enum NamingSet: String, Codable, Sendable, CaseIterable {
    case cities
    case rivers
    case parks
    case mountains

    public var names: [String] {
        switch self {
        case .cities:
            CityNames.all
        case .rivers:
            RiverNames.all
        case .parks:
            ParkNames.all
        case .mountains:
            MountainNames.all
        }
    }
}
