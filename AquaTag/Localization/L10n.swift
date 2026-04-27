//
//  L10n.swift
//  AquaTag · Localization helper
//
//  Thin wrapper so call sites stay readable:
//
//    Text(L10n.Plants.headerEyebrow)                // -> "NURSERY" / "KINDERSTUBE"
//    Text(L10n.Status.overdue(days: 3))             // -> "3d overdue" / "3 T überfällig"
//    Text(L10n.Plants.count(plants.count))          // plural-aware (see .stringsdict note)
//
//  Every key in here must exist in both en.lproj/Localizable.strings
//  and de.lproj/Localizable.strings.
//

import SwiftUI

enum L10n {

    // MARK: Tabs
    enum Tabs {
        static let plants   = LocalizedStringKey("tab.plants")
        static let history  = LocalizedStringKey("tab.history")
        static let settings = LocalizedStringKey("tab.settings")
    }

    // MARK: Plants list
    enum Plants {
        static let headerEyebrow = LocalizedStringKey("plants.header.eyebrow")
        static let emptyTitle    = LocalizedStringKey("plants.empty.title")
        static let emptyBody     = LocalizedStringKey("plants.empty.body")
        static let scanCTA       = LocalizedStringKey("plants.scan.cta")
        static let errorTitle    = LocalizedStringKey("plants.alert.error.title")
        static let successTitle  = LocalizedStringKey("plants.alert.success.title")
        static let alreadyTitle  = LocalizedStringKey("plants.alert.already.title")
        static let waterAnyway   = LocalizedStringKey("plants.alert.water.anyway")
        static let cancel        = LocalizedStringKey("plants.alert.cancel")
        static let ok            = LocalizedStringKey("plants.alert.ok")

        /// Singular/plural aware. Add a Localizable.stringsdict later for
        /// full ICU plural rules; for now we branch on count == 1.
        static func count(_ n: Int) -> String {
            if n == 1 {
                return String(localized: "plants.header.count.one")
            }
            return String(format: String(localized: "plants.header.count"), n)
        }

        static func alreadyBody(plantName: String) -> String {
            String(format: String(localized: "plants.alert.already.body"), plantName)
        }
    }

    // MARK: Row
    enum Row {
        static let neverWatered = LocalizedStringKey("row.never.watered")
        static func lastWatered(_ relative: String) -> String {
            String(format: String(localized: "row.last.watered"), relative)
        }
    }

    // MARK: Status badge
    enum Status {
        static let new      = LocalizedStringKey("status.new")
        static let today    = LocalizedStringKey("status.today")
        static let tomorrow = LocalizedStringKey("status.tomorrow")
        static func overdue(days: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString("status.overdue", comment: ""),
                days
            )
        }
        static func inDays(_ days: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString("status.in.days", comment: ""),
                days
            )
        }
    }

    // MARK: Detail
    enum Detail {
        static let sectionSchedule = LocalizedStringKey("detail.section.schedule")
        static let sectionNotes    = LocalizedStringKey("detail.section.notes")
        static let sectionSticker  = LocalizedStringKey("detail.section.sticker")
        static let sectionHA       = LocalizedStringKey("detail.section.ha")
        static let sectionDanger   = LocalizedStringKey("detail.section.danger")
        static let statEvery       = LocalizedStringKey("detail.stat.every")
        static let statDays        = LocalizedStringKey("detail.stat.days")
        static let statLast        = LocalizedStringKey("detail.stat.last.watered")
        static let statNext        = LocalizedStringKey("detail.stat.next.due")
        static let notWatered      = LocalizedStringKey("detail.not.watered")
        static let writeSticker    = LocalizedStringKey("detail.write.sticker")
        static let writeSuccess    = LocalizedStringKey("detail.write.success.title")
        static let writeFailed     = LocalizedStringKey("detail.write.failed.title")
        static let entityLabel     = LocalizedStringKey("detail.entity.label")
        static let tagID           = LocalizedStringKey("detail.tag.id")
        static let loggedBy        = LocalizedStringKey("detail.logged.by")
        static let toolbarDone     = LocalizedStringKey("detail.toolbar.done")
        static let toolbarCancel   = LocalizedStringKey("detail.toolbar.cancel")
        static let toolbarEdit     = LocalizedStringKey("detail.toolbar.edit")
        static let toolbarSave     = LocalizedStringKey("detail.toolbar.save")
        static let deletePlant     = LocalizedStringKey("detail.delete.plant")
        static let deleteTitle     = LocalizedStringKey("detail.delete.confirm.title")
        static let deleteAction    = LocalizedStringKey("detail.delete.action")
        static func deleteBody(plantName: String) -> String {
            String(format: String(localized: "detail.delete.confirm.body"), plantName)
        }
    }

    // MARK: Add
    enum Add {
        static let title            = LocalizedStringKey("add.title")
        static let cancel           = LocalizedStringKey("add.toolbar.cancel")
        static let save             = LocalizedStringKey("add.toolbar.save")
        static let sectionCharacter = LocalizedStringKey("add.section.character")
        static let sectionName      = LocalizedStringKey("add.section.name")
        static let sectionEvery     = LocalizedStringKey("add.section.water.every")
        static let sectionNotes     = LocalizedStringKey("add.section.notes")
        static let sectionHA        = LocalizedStringKey("add.section.ha")
        static let namePlaceholder  = LocalizedStringKey("add.name.placeholder")
        static let intervalDays     = LocalizedStringKey("add.interval.days")
        static let haHint           = LocalizedStringKey("add.ha.hint")
    }

    // MARK: History
    enum History {
        static let eyebrow         = LocalizedStringKey("history.eyebrow")
        static let eyebrowSixWeeks = LocalizedStringKey("history.eyebrow.six.weeks")
        static let title           = LocalizedStringKey("history.title")
        static let waterings       = LocalizedStringKey("history.waterings")
        static let dayStreak       = LocalizedStringKey("history.day.streak")
        static let thisWeek        = LocalizedStringKey("history.this.week")
        static let noneThisWeek    = LocalizedStringKey("history.none.this.week")
        static let emptyTitle      = LocalizedStringKey("history.empty.title")
        static let emptyBody       = LocalizedStringKey("history.empty.body")
        static let unknownWaterer  = LocalizedStringKey("history.watered.by.unknown")

        /// Positional substitution — order is preserved across locales.
        static func wateredBy(when: String, who: String) -> String {
            String(format: String(localized: "history.watered.by.when.who"), when, who)
        }
    }

    // MARK: Settings
    enum Settings {
        static let eyebrow             = LocalizedStringKey("settings.eyebrow")
        static let title               = LocalizedStringKey("settings.title")
        static let sectionHA           = LocalizedStringKey("settings.section.ha")
        static let sectionHASub        = LocalizedStringKey("settings.section.ha.subtitle")
        static let fieldURL            = LocalizedStringKey("settings.field.url")
        static let fieldToken          = LocalizedStringKey("settings.field.token")
        static let testConnection      = LocalizedStringKey("settings.test.connection")
        static let connected           = LocalizedStringKey("settings.connected")
        static let connectionFail      = LocalizedStringKey("settings.connection.failed")
        static let sectionDevice       = LocalizedStringKey("settings.section.device")
        static let sectionDeviceSub    = LocalizedStringKey("settings.section.device.subtitle")
        static let fieldDeviceName     = LocalizedStringKey("settings.field.device.name")
        static let sectionRemind       = LocalizedStringKey("settings.section.reminders")
        static let remindersToggle     = LocalizedStringKey("settings.reminders.toggle")
        static let remindersTime       = LocalizedStringKey("settings.reminders.time")
        static let defaultInterval     = LocalizedStringKey("settings.default.interval")
        static let sectionHelpers      = LocalizedStringKey("settings.section.helpers")
        static let helpersSub          = LocalizedStringKey("settings.helpers.subtitle")
        static let helpersEmpty        = LocalizedStringKey("settings.helpers.empty")
        static let footerVersion       = LocalizedStringKey("settings.footer.version")
        static let footerTagline       = LocalizedStringKey("settings.footer.tagline")

        static func defaultIntervalDays(_ n: Int) -> String {
            String(format: String(localized: "settings.default.interval.days"), n)
        }
    }

    // MARK: Watering success banner
    enum Water {
        static func success(plantName: String) -> String {
            String(format: String(localized: "water.success"), plantName)
        }
        static func successOffline(plantName: String) -> String {
            String(format: String(localized: "water.success.offline"), plantName)
        }
    }
}

// MARK: - Date formatter that respects the current locale
extension DateFormatter {
    /// Use for any user-facing date. Respects both system locale and the user's
    /// per-app language override (iOS 13+ `AppleLanguages`).
    static func localized(date: DateFormatter.Style, time: DateFormatter.Style) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.autoupdatingCurrent
        f.dateStyle = date
        f.timeStyle = time
        return f
    }
}

extension RelativeDateTimeFormatter {
    static let localized: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale.autoupdatingCurrent
        f.unitsStyle = .full
        return f
    }()
}
