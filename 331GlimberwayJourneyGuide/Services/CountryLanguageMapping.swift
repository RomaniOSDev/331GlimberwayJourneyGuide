import Foundation

enum HomeLeaveCatalog {
    static func makeItems() -> [HomeLeaveItem] {
        titles.map { HomeLeaveItem(title: $0) }
    }

    static let titles = [
        "Windows latched",
        "Stove and oven off",
        "Taps fully closed",
        "Plants watered or moved",
        "Trash and recycling out",
        "Thermostat on away",
        "Lights off except porch",
        "Chargers unplugged",
        "Washer / dryer empty",
        "Deadbolt and keys in hand"
    ]
}
