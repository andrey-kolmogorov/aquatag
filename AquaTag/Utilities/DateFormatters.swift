//
//  DateFormatters.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation

struct DateFormatters {
    // `iso8601` and `haDateTime()` are used off the main actor by HAService,
    // which is nonisolated so its JSON work stays off the main thread — hence
    // the explicit annotations. `iso8601` is `nonisolated(unsafe)` because
    // ISO8601DateFormatter predates Sendable, not because the safety is in
    // doubt: `formatOptions` is set once during static initialisation and
    // never touched again, so every later use is a concurrent read of an
    // effectively immutable object. The display formatters below stay
    // main-actor isolated; views are their only caller.

    /// ISO 8601 with fractional seconds — used for the `aquatag_plant_watered`
    /// event payload, where an unambiguous absolute timestamp is what
    /// automations want. Note this is *not* the format HA's `input_datetime`
    /// helpers use; see `haDateTime()`.
    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Home Assistant's `input_datetime` wire format: `2026-08-18 09:00:00`.
    ///
    /// Not ISO 8601 — space-separated and **timezone-naive**. HA stores plain
    /// local wall-clock, so sending an ISO string with a `Z` suffix makes it
    /// keep the UTC digits and drop the offset, recording every timestamp
    /// hours early. Read and write both have to go through this.
    ///
    /// A factory rather than a shared instance: `DateFormatter` captures its
    /// timeZone when set, so a cached one would go stale if the device changes
    /// zone, and a fresh instance sidesteps the Sendable question entirely.
    /// Create one per operation and reuse it within a loop.
    nonisolated static func haDateTime() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
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
