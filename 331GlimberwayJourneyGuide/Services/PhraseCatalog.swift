import Foundation

enum PhraseCatalog {
    static let all: [PhraseEntry] = spanish + french + japanese + italian

    static func phrases(language: PhraseLanguage, category: PhraseCategory) -> [PhraseEntry] {
        all.filter { $0.language == language && $0.category == category }
    }

    static func phrase(id: String) -> PhraseEntry? {
        all.first { $0.id == id }
    }

    private static let spanish: [PhraseEntry] = [
        entry(.spanish, .greetings, "Hello", "Hola", "OH-lah"),
        entry(.spanish, .greetings, "Good morning", "Buenos días", "BWEH-nos DEE-as"),
        entry(.spanish, .greetings, "Thank you", "Gracias", "GRAH-see-as"),
        entry(.spanish, .greetings, "Please", "Por favor", "por fah-VOR"),
        entry(.spanish, .transport, "Where is the station?", "¿Dónde está la estación?", "DON-deh es-TAH lah es-tah-SYON"),
        entry(.spanish, .transport, "One ticket, please", "Un billete, por favor", "oon bee-YEH-teh por fah-VOR"),
        entry(.spanish, .transport, "Where is the exit?", "¿Dónde está la salida?", "DON-deh es-TAH lah sah-LEE-dah"),
        entry(.spanish, .dining, "A table for two", "Una mesa para dos", "OO-nah MEH-sah PAH-rah dos"),
        entry(.spanish, .dining, "The check, please", "La cuenta, por favor", "lah KWEN-tah por fah-VOR"),
        entry(.spanish, .dining, "I am allergic to nuts", "Soy alérgico a los frutos secos", "soy ah-LER-hee-koh ah los FROO-tos SEH-kos")
    ]

    private static let french: [PhraseEntry] = [
        entry(.french, .greetings, "Hello", "Bonjour", "bon-ZHOOR"),
        entry(.french, .greetings, "Good evening", "Bonsoir", "bon-SWAHR"),
        entry(.french, .greetings, "Thank you", "Merci", "mer-SEE"),
        entry(.french, .greetings, "Excuse me", "Excusez-moi", "ex-kuu-ZAY mwah"),
        entry(.french, .transport, "Where is the metro?", "Où est le métro?", "oo eh luh MAY-troh"),
        entry(.french, .transport, "One ticket, please", "Un billet, s'il vous plaît", "un bee-YAY seel voo PLAY"),
        entry(.french, .transport, "Which platform?", "Quel quai?", "kel kay"),
        entry(.french, .dining, "A table for two", "Une table pour deux", "ewn TAH-bl poor duh"),
        entry(.french, .dining, "The bill, please", "L'addition, s'il vous plaît", "lah-dee-SYON seel voo PLAY"),
        entry(.french, .dining, "Still water, please", "De l'eau plate, s'il vous plaît", "duh loh PLAHT seel voo PLAY")
    ]

    private static let japanese: [PhraseEntry] = [
        entry(.japanese, .greetings, "Hello", "こんにちは", "kon-nichi-wa"),
        entry(.japanese, .greetings, "Thank you", "ありがとう", "ah-ree-gah-toh"),
        entry(.japanese, .greetings, "Excuse me", "すみません", "soo-mee-mah-sen"),
        entry(.japanese, .greetings, "Goodbye", "さようなら", "sah-yoh-nah-rah"),
        entry(.japanese, .transport, "Where is the station?", "駅はどこですか?", "eh-kee wah doh-koh des-kah"),
        entry(.japanese, .transport, "One ticket, please", "切符を一枚ください", "ki-ppu oh ee-mai koo-dah-sai"),
        entry(.japanese, .transport, "Which line?", "どの線ですか?", "doh-noh sen des-kah"),
        entry(.japanese, .dining, "Table for two", "二人席をお願いします", "foo-tah-ree se-ki oh oh-neh-gai shee-mas"),
        entry(.japanese, .dining, "Check, please", "お会計お願いします", "oh-kai-kei oh-neh-gai shee-mas"),
        entry(.japanese, .dining, "No wasabi, please", "わさび抜きでお願いします", "wah-sah-bee nu-ki deh oh-neh-gai shee-mas")
    ]

    private static let italian: [PhraseEntry] = [
        entry(.italian, .greetings, "Hello", "Ciao", "chow"),
        entry(.italian, .greetings, "Good morning", "Buongiorno", "bwon-JOR-noh"),
        entry(.italian, .greetings, "Thank you", "Grazie", "GRAH-tsee-eh"),
        entry(.italian, .greetings, "Please", "Per favore", "per fah-VOH-reh"),
        entry(.italian, .transport, "Where is the train?", "Dov'è il treno?", "doh-VEH eel TREH-noh"),
        entry(.italian, .transport, "One ticket, please", "Un biglietto, per favore", "oon bee-LYET-toh per fah-VOH-reh"),
        entry(.italian, .transport, "Which stop?", "Quale fermata?", "KWAH-leh fer-MAH-tah"),
        entry(.italian, .dining, "A table for two", "Un tavolo per due", "oon TAH-voh-loh per DOO-eh"),
        entry(.italian, .dining, "The bill, please", "Il conto, per favore", "eel KON-toh per fah-VOH-reh"),
        entry(.italian, .dining, "Water, please", "Acqua, per favore", "AH-kwah per fah-VOH-reh")
    ]

    private static func entry(
        _ language: PhraseLanguage,
        _ category: PhraseCategory,
        _ english: String,
        _ translation: String,
        _ pronunciation: String
    ) -> PhraseEntry {
        PhraseEntry(
            id: PhraseEntry.makeId(language: language, category: category, english: english),
            language: language,
            category: category,
            english: english,
            translation: translation,
            pronunciation: pronunciation
        )
    }
}
