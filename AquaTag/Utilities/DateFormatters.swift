//
//  DateFormatters.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation

struct DateFormatters {
    // The two ISO formatters are the only ones used off the main actor (by
    // HAService, which is nonisolated so its JSON work stays off the main
    // thread). They're `nonisolated(unsafe)` because ISO8601DateFormatter
    // predates Sendable and can't be marked as such — not because the safety
    // is in doubt: `formatOptions` is set once during static initialisation
    // and never touched again, so every subsequent use is a concurrent read of
    // an effectively immutable object. The display formatters below stay
    // main-actor isolated; they're only ever touched from views.

    // ISO 8601 formatter for HA API
    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // ISO 8601 without fractional seconds (for HA datetime helpers)
    nonisolated(unsafe) static let iso8601NoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    // Relative date formatter (e.g., "3 days ago")
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    // Short date formatter (e.g., "Apr 5, 2026")
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // Compact day + abbreviated month, locale-aware. en-US "Apr 25" / de-DE "25. Apr.".
    // Used in narrow stat tiles where the full year would wrap.
    static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    // Full month name + year, locale-aware. en-US "April 2026" / de-DE "April 2026".
    // Used as the calendar header.
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()

    // Weekday + day + full month, locale-aware. en-US "Monday, April 27" /
    // de-DE "Montag, 27. April". Used as the day-detail eyebrow.
    static let weekdayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return formatter
    }()
    
    // Date and time formatter (e.g., "Apr 5, 2026 at 2:30 PM")
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Time only formatter (e.g., "2:30 PM")
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
