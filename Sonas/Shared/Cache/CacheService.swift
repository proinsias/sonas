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

    // Maintenance
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
            let container = try ModelContainer(
                for: CachedWeatherSnapshot.self,
                     CachedLocationSnapshot.self,
                     CachedCalendarEvent.self,
                     CachedTask.self,
                     CachedJamSession.self
            )
            return CacheService(container: container)
        } catch {
            SonasLogger.app.error("CacheService: ModelContainer unavailable (\(error)) — running without cache")
            return CacheService(container: nil)
        }
    }()

    init(container: ModelContainer?) {
        self.modelContainer = container
    }

    // MARK: - TTL constants (research.md §Decision 9)

    private enum TTL {
        static let weather: TimeInterval   = 3600       // 1 hour
        static let location: TimeInterval  = 300        // 5 minutes
        static let task: TimeInterval      = 86400      // 24 hours
        // Calendar events: evicted if past their endDate (handled in evictStaleEntries)
    }

    // MARK: - Weather

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
        guard Date.now.timeIntervalSince(cached.lastUpdated) < TTL.weather else {
            return nil
        }
        return cached.toWeatherSnapshot()
    }

    func loadForecast() async -> [DayForecast] {
        guard let modelContainer else { return [] }
        let context = modelContainer.mainContext
        guard let cached = try? context.fetch(FetchDescriptor<CachedWeatherSnapshot>()).first,
              let forecasts = try? JSONDecoder().decode([DayForecastCodable].self, from: cached.forecastJSON)
        else { return [] }
        return forecasts.map(\.toDayForecast)
    }

    // MARK: - Location

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

    // MARK: - Calendar

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
        guard let cached = try? context.fetch(FetchDescriptor<CachedCalendarEvent>()) else {
            return []
        }
        return cached.compactMap { $0.toCalendarEvent() }
    }

    // MARK: - Tasks

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
        guard let cached = try? context.fetch(FetchDescriptor<CachedTask>()) else {
            return []
        }
        return cached.map { $0.toTask() }
    }

    // MARK: - Jam

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
        guard let cached = try? context.fetch(FetchDescriptor<CachedJamSession>()).first else {
            return nil
        }
        return cached.toJamSession()
    }

    // MARK: - Eviction (research.md §Decision 9)

    func evictStaleEntries() async throws {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext

        // Weather: evict if > 1 hour old
        if let weather = try? context.fetch(FetchDescriptor<CachedWeatherSnapshot>()).first,
           Date.now.timeIntervalSince(weather.lastUpdated) > TTL.weather {
            context.delete(weather)
        }

        // Location: evict individual snapshots > 5 min old
        if let locations = try? context.fetch(FetchDescriptor<CachedLocationSnapshot>()) {
            for loc in locations where Date.now.timeIntervalSince(loc.lastUpdated) > TTL.location {
                context.delete(loc)
            }
        }

        // Calendar events: evict past events
        if let events = try? context.fetch(FetchDescriptor<CachedCalendarEvent>()) {
            for event in events where event.endDate < .now {
                context.delete(event)
            }
        }

        // Tasks: evict if > 24 hours old
        if let tasks = try? context.fetch(FetchDescriptor<CachedTask>()) {
            for task in tasks where Date.now.timeIntervalSince(task.lastUpdated) > TTL.task {
                context.delete(task)
            }
        }

        // Jam: evict ended sessions
        if let jams = try? context.fetch(FetchDescriptor<CachedJamSession>()) {
            for jam in jams where jam.statusRaw == JamStatus.ended.rawValue {
                context.delete(jam)
            }
        }

        try context.save()
    }
}

// MARK: - Codable bridge types for DayForecast serialisation

private struct DayForecastCodable: Codable {
    let id, conditionSymbolName, conditionDescription: String
    let date: Date
    let highTemperature, lowTemperature, precipitationChance: Double

    init(_ forecast: DayForecast) {
        id = forecast.id
        conditionSymbolName = forecast.conditionSymbolName
        conditionDescription = forecast.conditionDescription
        date = forecast.date
        highTemperature = forecast.highTemperature
        lowTemperature = forecast.lowTemperature
        precipitationChance = forecast.precipitationChance
    }

    var toDayForecast: DayForecast {
        DayForecast(
            id: id, date: date,
            highTemperature: highTemperature, lowTemperature: lowTemperature,
            conditionSymbolName: conditionSymbolName, conditionDescription: conditionDescription,
            precipitationChance: precipitationChance
        )
    }
}

// MARK: - CachedModel → Domain model conversions

private extension CachedWeatherSnapshot {
    func toWeatherSnapshot() -> WeatherSnapshot {
        WeatherSnapshot(
            temperature: temperature, feelsLike: feelsLike,
            conditionDescription: conditionDescription, conditionSymbolName: conditionSymbolName,
            humidity: humidity, windSpeed: windSpeed,
            windDirection: windDirection, windCompassLabel: windCompassLabel,
            pressure: pressure,
            pressureTrend: PressureTrend(rawValue: pressureTrendRaw) ?? .steady,
            airQualityIndex: airQualityIndex,
            aiqCategory: airQualityIndex.map { AQICategory(usAQI: $0) },
            sunriseTime: sunriseTime, sunsetTime: sunsetTime,
            moonPhase: MoonPhase(rawValue: moonPhaseRaw) ?? .newMoon,
            fetchedAt: lastUpdated
        )
    }
}

private extension CachedLocationSnapshot {
    func toFamilyMember() -> FamilyMember {
        FamilyMember(
            id: memberID,
            displayName: displayName,
            location: LocationSnapshot(
                coordinate: .init(latitude: latitude, longitude: longitude),
                placeName: placeName,
                recordedAt: recordedAt
            )
        )
    }
}

private extension CachedCalendarEvent {
    func toCalendarEvent() -> CalendarEvent? {
        let attendees = (try? JSONDecoder().decode([String].self, from: attendeesJSON)) ?? []
        return CalendarEvent(
            id: eventID, title: title,
            startDate: startDate, endDate: endDate, isAllDay: isAllDay,
            calendarName: calendarName,
            source: CalendarSource(rawValue: sourceRaw) ?? .iCloud,
            attendees: attendees, calendarColorHex: calendarColorHex
        )
    }
}

private extension CachedTask {
    func toTask() -> Task {
        let due: TaskDue? = dueString.map {
            TaskDue(date: dueDate, string: $0, isRecurring: isRecurring)
        }
        return Task(
            id: taskID, content: content, description: taskDescription,
            projectID: projectID, projectName: projectName,
            due: due,
            priority: TaskPriority(rawValue: priorityRaw) ?? .normal,
            isCompleted: isCompleted, isCompleting: false,
            createdAt: nil, orderIndex: orderIndex
        )
    }
}

private extension CachedJamSession {
    func toJamSession() -> JamSession? {
        guard let url = URL(string: joinURLString) else { return nil }
        return JamSession(
            id: sessionID, joinURL: url,
            status: JamStatus(rawValue: statusRaw) ?? .ended,
            startedAt: startedAt
        )
    }
}
