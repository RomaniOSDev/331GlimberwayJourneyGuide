import Foundation

enum PackingTemplate: String, CaseIterable, Identifiable {
    case flightMorning
    case roadLeave
    case overnightRail
    case weekendCarry
    case familyHandoff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flightMorning: return "Flight morning"
        case .roadLeave: return "Road leave"
        case .overnightRail: return "Overnight rail"
        case .weekendCarry: return "Weekend carry-on"
        case .familyHandoff: return "Family handoff"
        }
    }

    var symbol: String {
        switch self {
        case .flightMorning: return "airplane.departure"
        case .roadLeave: return "car.fill"
        case .overnightRail: return "tram.fill"
        case .weekendCarry: return "bag.fill"
        case .familyHandoff: return "person.2.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .flightMorning: return "Gate-ready pouch + one cabin bag"
        case .roadLeave: return "Car day bag, not a suitcase dump"
        case .overnightRail: return "Coach seat kit for one night"
        case .weekendCarry: return "Two days, one bag, wear the coat"
        case .familyHandoff: return "Kids, seats, and the house loop"
        }
    }

    var items: [(title: String, category: PackingCategory, grams: Int, placement: BagPlacement)] {
        switch self {
        case .flightMorning:
            return [
                ("Passport / ID", .docs, 40, .packed),
                ("Boarding pass print or screenshot", .docs, 5, .packed),
                ("Payment cards in pouch", .docs, 20, .packed),
                ("Travel insurance card", .docs, 5, .packed),
                ("Phone", .other, 200, .wear),
                ("Power bank under 100Wh", .other, 180, .packed),
                ("USB-C cable", .other, 40, .packed),
                ("Empty refill bottle", .other, 90, .packed),
                ("Clear liquids bag", .toiletries, 80, .toiletry),
                ("Toothbrush + mini paste", .toiletries, 50, .toiletry),
                ("Deodorant stick", .toiletries, 70, .toiletry),
                ("Lens solution mini", .toiletries, 60, .toiletry),
                ("Meds in original strip", .toiletries, 30, .toiletry),
                ("Spare underwear", .clothing, 80, .packed),
                ("Spare socks", .clothing, 60, .packed),
                ("Base layer tee", .clothing, 140, .packed),
                ("Comfortable trousers", .clothing, 320, .wear),
                ("Coat / heavy shoes", .clothing, 0, .wear),
                ("Eye mask", .other, 30, .packed),
                ("Earplugs", .other, 10, .packed),
                ("Pen for forms", .other, 10, .packed),
                ("Snack that is not liquid", .other, 80, .packed),
                ("House keys (leave hook)", .other, 40, .wear),
                ("Compression bag", .other, 50, .packed)
            ]
        case .roadLeave:
            return [
                ("Driver license", .docs, 15, .wear),
                ("Registration photo", .docs, 0, .packed),
                ("Insurance card", .docs, 5, .packed),
                ("Cash for tolls", .docs, 20, .packed),
                ("Phone mount already in car", .other, 0, .wear),
                ("Car charger", .other, 60, .packed),
                ("Offline map downloaded", .docs, 0, .packed),
                ("Water bottles filled at home", .other, 500, .packed),
                ("Cooler ice pack", .other, 200, .packed),
                ("Paper towels roll", .other, 180, .packed),
                ("Trash bags", .other, 40, .packed),
                ("Sunglasses", .other, 40, .wear),
                ("Light jacket", .clothing, 280, .packed),
                ("Change of shirt", .clothing, 160, .packed),
                ("Spare socks", .clothing, 60, .packed),
                ("Tooth kit", .toiletries, 80, .toiletry),
                ("Sunscreen", .toiletries, 90, .toiletry),
                ("Meds", .toiletries, 30, .toiletry),
                ("Blanket for the back seat", .other, 400, .packed),
                ("Ice scraper if winter", .other, 0, .wear),
                ("House keys", .other, 40, .wear),
                ("Printed first hotel address", .docs, 5, .packed)
            ]
        case .overnightRail:
            return [
                ("Ticket PDF + screenshot", .docs, 0, .packed),
                ("ID", .docs, 20, .packed),
                ("Seat/coach note", .docs, 0, .packed),
                ("Neck layer for AC", .clothing, 180, .wear),
                ("Socks you can sleep in", .clothing, 70, .packed),
                ("Eye mask", .other, 30, .packed),
                ("Earplugs", .other, 10, .packed),
                ("Power bank", .other, 180, .packed),
                ("Cable", .other, 40, .packed),
                ("Tooth kit", .toiletries, 70, .toiletry),
                ("Face wipe pack", .toiletries, 40, .toiletry),
                ("Meds", .toiletries, 30, .toiletry),
                ("Soft shoes / slides", .clothing, 220, .packed),
                ("Water after you board", .other, 0, .packed),
                ("Snack", .other, 80, .packed),
                ("Book or offline show", .other, 0, .packed),
                ("House keys", .other, 40, .wear),
                ("Thin rain shell", .clothing, 240, .packed)
            ]
        case .weekendCarry:
            return [
                ("ID / passport", .docs, 40, .packed),
                ("Cards + some cash", .docs, 25, .packed),
                ("Two shirts", .clothing, 280, .packed),
                ("One pair trousers", .clothing, 320, .wear),
                ("Underwear x2", .clothing, 140, .packed),
                ("Socks x2", .clothing, 120, .packed),
                ("Sleep shirt", .clothing, 140, .packed),
                ("Coat on body", .clothing, 0, .wear),
                ("Shoes on body", .clothing, 0, .wear),
                ("Toiletry minis", .toiletries, 220, .toiletry),
                ("Meds", .toiletries, 30, .toiletry),
                ("Charger brick", .other, 80, .packed),
                ("Cable", .other, 40, .packed),
                ("Power bank", .other, 180, .packed),
                ("Empty bottle", .other, 90, .packed),
                ("Laundry bag", .other, 30, .packed),
                ("House keys", .other, 40, .wear),
                ("Thin sweater", .clothing, 260, .packed)
            ]
        case .familyHandoff:
            return [
                ("Adult IDs", .docs, 40, .packed),
                ("Kids' IDs / consent note", .docs, 10, .packed),
                ("Insurance cards", .docs, 10, .packed),
                ("Pediatric meds + spoon", .toiletries, 80, .toiletry),
                ("Wipes", .toiletries, 120, .toiletry),
                ("Spare outfit per child", .clothing, 250, .packed),
                ("Spare adult shirt", .clothing, 150, .packed),
                ("Snacks that are not sticky", .other, 150, .packed),
                ("Empty bottles + one filled at home", .other, 200, .packed),
                ("Charger + cable", .other, 120, .packed),
                ("Tablet offline show", .other, 0, .packed),
                ("Headphones splitter or two pairs", .other, 60, .packed),
                ("Stroller rain cover if used", .other, 180, .packed),
                ("Car seat already clicked", .other, 0, .wear),
                ("House plant sitter note", .docs, 0, .packed),
                ("Neighbor trash plan", .docs, 0, .packed),
                ("House keys + spare with sitter", .other, 40, .wear),
                ("Thermostat set", .other, 0, .wear)
            ]
        }
    }
}
