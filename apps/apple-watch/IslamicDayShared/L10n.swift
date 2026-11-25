import Foundation

enum AppLanguage {
    static let supported = ["tr", "id", "ur", "bn", "fr", "ru"]

    static var code: String {
        for tag in Locale.preferredLanguages {
            let base = tag.split(separator: "-").first.map(String.init)?.lowercased() ?? "en"
            if base == "en" { return "en" }
            if supported.contains(base) { return base }
        }
        return "en"
    }

    static var isRightToLeft: Bool { code == "ur" }
}

enum L10n {
    static func t(_ key: String) -> String {
        localized[key] ?? english[key] ?? key
    }

    /// Sentence-case Turkish vakit name. Other languages keep the English sector title.
    static func sectorProse(_ name: String) -> String {
        guard AppLanguage.code == "tr", let mapped = turkishSectors[name] else { return name }
        return mapped
    }

    /// Capital form for the ring. Turkish dotted İ is uppercased with a Turkish locale.
    static func sectorRing(_ name: String) -> String {
        let prose = sectorProse(name)
        if AppLanguage.code == "tr", turkishSectors[name] != nil {
            return prose.uppercased(with: Locale(identifier: "tr"))
        }
        return prose.uppercased()
    }

    private static let turkishSectors = [
        "Fajr": "İmsak",
        "Sunrise": "Güneş",
        "Duha": "Kuşluk",
        "Midday": "Zeval",
        "Dhuhr": "Öğle",
        "Asr": "İkindi",
        "Maghrib": "Akşam",
        "Isha": "Yatsı",
        "Last 3rd": "Son üçte bir",
        "Jumu'ah": "Cuma",
    ]

    private static let english = load("ui-en")
    private static let localized: [String: String] = {
        let code = AppLanguage.code
        if code == "en" { return english }
        let table = load("ui-\(code)")
        return table.isEmpty ? english : table
    }()

    private static func load(_ name: String) -> [String: String] {
        guard
            let url = Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else {
            return [:]
        }
        return object
    }
}

enum Scripture {
    struct Passage {
        let text: String
        let notes: String
        let credit: String
    }

    static func display(id: String, fallback: String) -> String {
        guard AppLanguage.code != "en", let passage = passage(id) else { return fallback }
        return [passage.text, passage.notes]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private static func passage(_ id: String) -> Passage? {
        let table = load(AppLanguage.code)
        guard
            let raw = table[id] as? [String: String],
            let text = raw["text"],
            !text.isEmpty
        else {
            return nil
        }
        return Passage(text: text, notes: raw["notes"] ?? "", credit: raw["credit"] ?? "")
    }

    private static func load(_ code: String) -> [String: Any] {
        guard
            let url = Bundle(for: BundleToken.self).url(forResource: "scripture-\(code)", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return object
    }
}

private final class BundleToken {}
