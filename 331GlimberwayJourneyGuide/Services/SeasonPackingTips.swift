import Foundation

enum ForecastPackingAdvisor {
    static func extras(for forecast: ForecastCondition, mode: LeaveMode) -> [(title: String, category: PackingCategory, grams: Int, placement: BagPlacement)] {
        var items: [(String, PackingCategory, Int, BagPlacement)] = []

        switch forecast {
        case .unset:
            break
        case .fair:
            items += [
                ("Cap or visor", .clothing, 80, .packed),
                ("Sunglasses", .other, 40, .wear)
            ]
        case .rain:
            items += [
                ("Packable rain shell", .clothing, 280, .packed),
                ("Compact umbrella", .other, 190, .packed),
                ("Dry bag for electronics", .other, 60, .packed)
            ]
        case .heat:
            items += [
                ("Breathable shirt", .clothing, 140, .wear),
                ("Electrolyte sachets", .other, 40, .packed),
                ("Refill bottle (empty at security)", .other, 90, .packed)
            ]
        case .freeze:
            items += [
                ("Insulating mid-layer", .clothing, 320, .wear),
                ("Gloves", .clothing, 80, .wear),
                ("Lip balm", .toiletries, 20, .toiletry)
            ]
        case .mixed:
            items += [
                ("Light layer you can peel", .clothing, 220, .packed),
                ("Thin rain shell", .clothing, 240, .packed)
            ]
        }

        if mode == .flight && (forecast == .rain || forecast == .mixed) {
            items.append(("Spare socks in pouch", .clothing, 70, .packed))
        }
        if mode == .road && forecast == .freeze {
            items.append(("Ice scraper already in car", .other, 0, .wear))
        }

        return items
    }

    static func tipLines(for forecast: ForecastCondition, mode: LeaveMode) -> [String] {
        var lines: [String] = []
        switch forecast {
        case .unset:
            lines.append("Set the leave-day forecast so the bag list can add weather extras.")
        case .fair:
            lines.append("Fair weather: keep the bag light and wear the heavier shoes.")
        case .rain:
            lines.append("Rain leave: shell and dry bag go in the top pocket, not the bottom.")
        case .heat:
            lines.append("Hot leave: bottle stays empty through security; electrolytes in the pouch.")
        case .freeze:
            lines.append("Freeze leave: gloves and mid-layer stay on your body to save bag kilos.")
        case .mixed:
            lines.append("Mixed day: one peel layer in the bag, one on you.")
        }
        switch mode {
        case .flight:
            lines.append("Wear the coat. The scale only cares what is in the bag.")
        case .road:
            lines.append("Car weight does not replace a house loop before you lock.")
        case .rail:
            lines.append("Keep the ticket pouch in the jacket, not the hold bag.")
        case .overnight:
            lines.append("If you need a second bag, it is not an overnight.")
        }
        return lines
    }
}
