import Foundation
import SwiftData

// MARK: - CacheServiceProtocol (T022)

protocol CacheServiceProtocol: Sendable {
    // Weather
    func saveWeather(_ snapshot: WeatherSnapshot, forecast: [DayForecast]) async throws
    func loadWeather() async -> WeatherSnapshot?
    func loadForecast() async -> [DayForecast]

    // Location
    func saveLocations(_ members: [FamilyMember]) async throws
    func loadLocations() async -> [FamilyMember]

    // Calendar
    func saveEvents(_ events: [CalendarEvent]) async throws
    func loadEvents() async -> [CalendarEvent]

    // Tasks
    func saveTasks(_ tasks: [Task]) async throws
    func loadTasks() async -> [Task]

    // Jam
    func saveJamSession(_ session: JamSession?) async throws
    func loadJamSession() async -> JamSession?

    /// Maintenance
    func evictStaleEntries() async throws
}

// MARK: - CacheService (T024)

/// SwiftData-backed on-device cache for all dashboard panels.
/// When SwiftData is unavailable the service runs as a no-op cache so the app still launches.
@MainActor
final class CacheService: CacheServiceProtocol {
    private let modelContainer: ModelContainer?

    static var shared: CacheService = {
        do {
            // Pre-create Application Support so SwiftData/CoreData doesn't need to self-recover.
            // Without this, CoreData logs several pages of filesystem diagnostics before creating
            // the directory itself; the store still opens successfully but the noise is misleading.
            if let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first {
                try? FileManager.default.createDirectory(
                    at: appSupport, withIntermediateDirectories: true
                )
            }
            let config = ModelConfiguration(cloudKitDatabase: .none)
            let container = try ModelContainer(
                for: CachedWeatherSnapshot.self,
                CachedLocationSnapshot.self,
                CachedCalendarEvent.self,
                CachedTask.self,
                CachedJamSession.self,
                configurations: config
            )
            return CacheService(container: container)
        } catch {
            SonasLogger.app.error("CacheService: ModelContainer unavailable (\(error)) — running without cache")
            return CacheService(container: nil)
        }
    }()

    init(container: ModelContainer?) {
        modelContainer = container
    }

    // MARK: - TTL constants (research.md §Decision 9)

    private enum TTL {
        static let weather: TimeInterval = 3600 // 1 hour
        static let location: TimeInterval = 300 // 5 minutes
        static let task: TimeInterval = 86400 // 24 hours
        // Calendar events: evicted if past their endDate (handled in evictStaleEntries)
    }
}

// MARK: - Weather

extension CacheService {
    func saveWeather(_ snapshot: WeatherSnapshot, forecast: [DayForecast]) async throws {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext
        try context.delete(model: CachedWeatherSnapshot.self)
        let forecastData = try JSONEncoder().encode(forecast.map(DayForecastCodable.init))
        let cached = CachedWeatherSnapshot(
            temperature: snapshot.temperature,
            feelsLike: snapshot.feelsLike,
            conditionDescription: snapshot.conditionDescription,
            conditionSymbolName: snapshot.conditionSymbolName,
            humidity: snapshot.humidity,
            windSpeed: snapshot.windSpeed,
            windDirection: snapshot.windDirection,
            windCompassLabel: snapshot.windCompassLabel,
            pressure: snapshot.pressure,
            pressureTrendRaw: snapshot.pressureTrend.rawValue,
            airQualityIndex: snapshot.airQualityIndex,
            sunriseTime: snapshot.sunriseTime,
            sunsetTime: snapshot.sunsetTime,
            moonPhaseRaw: snapshot.moonPhase.rawValue,
            forecastJSON: forecastData,
            lastUpdated: snapshot.fetchedAt
        )
        context.insert(cached)
        try context.save()
    }

    func loadWeather() async -> WeatherSnapshot? {
        guard let modelContainer else { return nil }
        let context = modelContainer.mainContext
        guard let cached = try? context.fetch(FetchDescriptor<CachedWeatherSnapshot>()).first else {
            return nil
        }
        guard Date.now.timeIntervalSince(cached.lastUpdated) < TTL.weather else { return nil }
        return cached.toWeatherSnapshot()
    }

    func loadForecast() async -> [DayForecast] {
        guard let modelContainer else { return [] }
        let context = modelContainer.mainContext
        guard
            let cached = try? context.fetch(FetchDescriptor<CachedWeatherSnapshot>()).first,
            let forecasts = try? JSONDecoder().decode([DayForecastCodable].self, from: cached.forecastJSON)
        else { return [] }
        return forecasts.map(\.toDayForecast)
    }
}

// MARK: - Location

extension CacheService {
    func saveLocations(_ members: [FamilyMember]) async throws {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext
        try context.delete(model: CachedLocationSnapshot.self)
        for member in members {
            guard let loc = member.location else { continue }
            let cached = CachedLocationSnapshot(
                memberID: member.id,
                displayName: member.displayName,
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                placeName: loc.placeName,
                recordedAt: loc.recordedAt,
                lastUpdated: .now
            )
            context.insert(cached)
        }
        try context.save()
    }

    func loadLocations() async -> [FamilyMember] {
        guard let modelContainer else { return [] }
        let context = modelContainer.mainContext
        guard let snapshots = try? context.fetch(FetchDescriptor<CachedLocationSnapshot>()) else {
            return []
        }
        return snapshots.map { $0.toFamilyMember() }
    }
}

// MARK: - Calendar

extension CacheService {
    func saveEvents(_ events: [CalendarEvent]) async throws {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext
        try context.delete(model: CachedCalendarEvent.self)
        for event in events {
            let attendeesData = (try? JSONEncoder().encode(event.attendees)) ?? Data()
            let cached = CachedCalendarEvent(
                eventID: event.id,
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                calendarName: event.calendarName,
                sourceRaw: event.source.rawValue,
                attendeesJSON: attendeesData,
                calendarColorHex: event.calendarColorHex,
                lastUpdated: .now
            )
            context.insert(cached)
        }
        try context.save()
    }

    func loadEvents() async -> [CalendarEvent] {
        guard let modelContainer else { return [] }
        let context = modelContainer.mainContext
        guard let cached = try? context.fetch(FetchDescriptor<CachedCalendarEvent>()) else { return [] }
        return cached.compactMap { $0.toCalendarEvent() }
    }
}

// MARK: - Tasks

extension CacheService {
    func saveTasks(_ tasks: [Task]) async throws {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext
        try context.delete(model: CachedTask.self)
        for task in tasks {
            let cached = CachedTask(
                taskID: task.id,
                content: task.content,
                taskDescription: task.description,
                projectID: task.projectID,
                projectName: task.projectName,
                priorityRaw: task.priority.rawValue,
                isCompleted: task.isCompleted,
                dueDate: task.due?.date,
                dueString: task.due?.string,
                isRecurring: task.due?.isRecurring ?? false,
                orderIndex: task.orderIndex,
                lastUpdated: .now
            )
            context.insert(cached)
        }
        try context.save()
    }

    func loadTasks() async -> [Task] {
        guard let modelContainer else { return [] }
        let context = modelContainer.mainContext
        guard let cached = try? context.fetch(FetchDescriptor<CachedTask>()) else { return [] }
        return cached.map { $0.toTask() }
    }
}

// MARK: - Jam

extension CacheService {
    func saveJamSession(_ session: JamSession?) async throws {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext
        try context.delete(model: CachedJamSession.self)
        if let session, let joinURL = Optional(session.joinURL.absoluteString) {
            let cached = CachedJamSession(
                sessionID: session.id,
                joinURLString: joinURL,
                statusRaw: session.status.rawValue,
                startedAt: session.startedAt,
                lastUpdated: .now
            )
            context.insert(cached)
        }
        try context.save()
    }

    func loadJamSession() async -> JamSession? {
        guard let modelContainer else { return nil }
        let context = modelContainer.mainContext
        guard let cached = try? context.fetch(FetchDescriptor<CachedJamSession>()).first else { return nil }
        return cached.toJamSession()
    }
}

// MARK: - Eviction (research.md §Decision 9)

extension CacheService {
    func evictStaleEntries() async throws {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext
        evictStaleWeather(context: context)
        evictStaleLocations(context: context)
        evictStaleEvents(context: context)
        evictStaleTasks(context: context)
        evictStaleJamSessions(context: context)
        try context.save()
    }

    private func evictStaleWeather(context: ModelContext) {
        guard let weather = try? context.fetch(FetchDescriptor<CachedWeatherSnapshot>()).first,
              Date.now.timeIntervalSince(weather.lastUpdated) > TTL.weather
        else { return }
        context.delete(weather)
    }

    private func evictStaleLocations(context: ModelContext) {
        guard let locations = try? context.fetch(FetchDescriptor<CachedLocationSnapshot>()) else { return }
        for loc in locations where Date.now.timeIntervalSince(loc.lastUpdated) > TTL.location {
            context.delete(loc)
        }
    }

    private func evictStaleEvents(context: ModelContext) {
        guard let events = try? context.fetch(FetchDescriptor<CachedCalendarEvent>()) else { return }
        for event in events where event.endDate < .now {
            context.delete(event)
        }
    }

    private func evictStaleTasks(context: ModelContext) {
        guard let tasks = try? context.fetch(FetchDescriptor<CachedTask>()) else { return }
        for task in tasks where Date.now.timeIntervalSince(task.lastUpdated) > TTL.task {
            context.delete(task)
        }
    }

    private func evictStaleJamSessions(context: ModelContext) {
        guard let jams = try? context.fetch(FetchDescriptor<CachedJamSession>()) else { return }
        for jam in jams where jam.statusRaw == JamStatus.ended.rawValue {
            context.delete(jam)
        }
    }
}
