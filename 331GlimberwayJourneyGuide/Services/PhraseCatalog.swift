import Foundation

enum TimelineCatalog {
    static func makeTasks(for mode: LeaveMode) -> [TimelineTask] {
        switch mode {
        case .flight:
            return flight
        case .road:
            return road
        case .rail:
            return rail
        case .overnight:
            return overnight
        }
    }

    private static var flight: [TimelineTask] {
        [
            task(.t24h, "Lay out the leave pouch", "Passport, cards, and cash in one envelope.", airport: false),
            task(.t24h, "Download boarding pass offline", "Screenshot plus wallet pass if you use one.", airport: false),
            task(.t24h, "Charge the brick overnight", "Phone, watch, and power bank to 100%.", airport: false),
            task(.t24h, "Set liquids in a clear quart bag", "Only what you will actually use on the plane.", airport: true),
            task(.t24h, "Confirm gate window, not just departure", "Build a 3-hour buffer before the wheels-up time.", airport: false),
            task(.t3h, "Lock the ride", "Taxi, train, or friend — confirm pickup now.", airport: false),
            task(.t3h, "Run the house loop once", "Windows, stove, taps, plants, bins.", airport: false),
            task(.t3h, "Wear the heavy layers", "Coat and boots stay off the scale.", airport: false),
            task(.t3h, "Meds and glasses in the pouch", "Do not bury them in checked anything.", airport: true),
            task(.t30m, "Last house pass", "Stove off, lights off, deadbolt, keys in hand.", airport: false),
            task(.t30m, "Trash out if pickup is tomorrow", "No food sitting for a week.", airport: false),
            task(.t30m, "Phone on airplane playlist offline", "One album so you are not hunting Wi-Fi.", airport: true),
            task(.airport, "Liquids out before the belt", "Laptop and 100ml bag in their own tray.", airport: true),
            task(.airport, "Belt bag only after security", "Water bottle empty until the fountain.", airport: true),
            task(.airport, "Boarding group written on the pass", "Stand up only when your group is called.", airport: true)
        ]
    }

    private static var road: [TimelineTask] {
        [
            task(.t24h, "Fuel and washer fluid", "Do not start a leave-day with a quarter tank.", airport: false),
            task(.t24h, "Paper license plus digital backup", "Photo of registration in the wallet folder.", airport: false),
            task(.t24h, "Cooler ice or empty bottles", "Water for the first three hours.", airport: false),
            task(.t24h, "Download the offline map tile", "First 200 km without signal.", airport: false),
            task(.t3h, "House loop and thermostat", "Set away temperature before you pack the car.", airport: false),
            task(.t3h, "Load the overnight bag last", "So the first hotel stop is the top zipper.", airport: false),
            task(.t3h, "Share ETA with one person", "One text, not a live story.", airport: false),
            task(.t30m, "Trash, stove, deadbolt", "Walk the rooms once, then lock.", airport: false),
            task(.t30m, "Phone mount and cable already in the car", "No hunting in the driveway.", airport: false),
            task(.airport, "First stop is fuel if below half", "Treat the first station as your gate.", airport: true)
        ]
    }

    private static var rail: [TimelineTask] {
        [
            task(.t24h, "Coach and seat screenshot", "Plus the PDF in Files, not only Mail.", airport: false),
            task(.t24h, "Layer for the car AC", "Trains run colder than the platform.", airport: false),
            task(.t24h, "Earplugs and eye mask in the pouch", "Not buried in the big bag.", airport: false),
            task(.t3h, "House loop", "Windows, stove, plants, bins.", airport: false),
            task(.t3h, "Platform time, not departure time", "Be on the concourse 40 minutes early.", airport: false),
            task(.t30m, "Deadbolt and keys", "Wallet, ticket, phone in the same hand.", airport: false),
            task(.airport, "Coach letter on a sticky note", "Walk the train once, sit, then unpack.", airport: true)
        ]
    }

    private static var overnight: [TimelineTask] {
        [
            task(.t24h, "One bag, one pouch", "If it does not fit, it stays.", airport: false),
            task(.t24h, "Charger and meds only", "Skip the extras you never used last time.", airport: false),
            task(.t3h, "House loop", "Windows, stove, plants.", airport: false),
            task(.t30m, "Deadbolt", "Keys, wallet, phone.", airport: false),
            task(.airport, "You are out the door", "No second trip upstairs.", airport: true)
        ]
    }

    private static func task(
        _ phase: TimelinePhase,
        _ title: String,
        _ detail: String,
        airport: Bool
    ) -> TimelineTask {
        TimelineTask(
            title: title,
            detail: detail,
            minutesBeforeDeparture: phase.minutesBefore,
            phase: phase,
            notify: phase != .airport,
            airportRelevant: airport || phase == .airport
        )
    }
}
