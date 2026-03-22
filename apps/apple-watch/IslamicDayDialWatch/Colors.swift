import SwiftUI

/// Segment colors. Mirrors apps/web-dashboard/src/lib/colors.ts and segment-gradients.ts
/// Simplified for watch: solid colors, no gradients

let RING_GAP = Color(red: 0.04, green: 0.04, blue: 0.09)

let NIGHT = Color(red: 0.04, green: 0.04, blue: 0.07)
let BLUE_MID = Color(red: 0.23, green: 0.51, blue: 0.66)
let YELLOW = Color(red: 0.92, green: 0.70, blue: 0.03)

/// Sun marker colors (from web CORE_SPEC)
let SUN_NORMAL = Color(red: 1.0, green: 0.79, blue: 0.16)   // #ffca28
let SUN_ORANGE = Color(red: 1.0, green: 0.44, blue: 0)    // #ff6f00
let SUN_RED = Color(red: 0.78, green: 0.16, blue: 0.16)   // #c62828
let MOON_LUNAR = Color(red: 0.75, green: 0.72, blue: 0.63) // #C0B8A0

/// Tick marks — warm ivory, matches web #fbeccb
let MARKER_STROKE = Color(red: 0.984, green: 0.925, blue: 0.796)

/// Ivory for sector names and countdown
enum Colors {
    static let ivory = Color(red: 0.96, green: 0.94, blue: 0.88)
}

/// Segment colors for watch (simplified). All 3 Isha arcs = same dark color.
func segmentColor(phase: IslamicPhaseId, isActive: Bool) -> Color {
    let ishaDark: Set<IslamicPhaseId> = [.isha_to_midnight, .last_third_to_fajr]
    if ishaDark.contains(phase) { return RING_GAP }
    
    switch phase {
    case .fajr_to_sunrise: return isActive ? Color(red: 0.36, green: 0.64, blue: 0.83) : BLUE_MID
    case .sunrise_to_dhuhr: return isActive ? Color(red: 0.99, green: 0.87, blue: 0.28) : YELLOW
    case .dhuhr_to_asr: return isActive ? Color(red: 0.99, green: 0.87, blue: 0.28) : YELLOW
    case .asr_to_maghrib: return isActive ? Color(red: 0.36, green: 0.64, blue: 0.83) : BLUE_MID
    case .maghrib_to_isha: return isActive ? Color(red: 0.36, green: 0.64, blue: 0.83) : BLUE_MID
    default: return RING_GAP
    }
}
