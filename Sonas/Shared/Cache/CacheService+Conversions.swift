import Foundation
import SwiftData

// MARK: - Codable bridge for DayForecast serialisation

struct DayForecastCodable: Codable {
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
            id: id,
            date: date,
            highTemperature: highTemperature,
            lowTemperature: lowTemperature,
            conditionSymbolName: conditionSymbolName,
            conditionDescription: conditionDescription,
            precipitationChance: precipitationChance
        )
    }
}

// MARK: - CachedModel → Domain model conversions

extension CachedWeatherSnapshot {
    func toWeatherSnapshot() -> WeatherSnapshot {
        WeatherSnapshot(
            temperature: temperature,
            feelsLike: feelsLike,
            conditionDescription: conditionDescription,
            conditionSymbolName: conditionSymbolName,
            humidity: humidity,
            windSpeed: windSpeed,
            windDirection: windDirection,
            windCompassLabel: windCompassLabel,
            pressure: pressure,
            pressureTrend: PressureTrend(rawValue: pressureTrendRaw) ?? .steady,
            airQualityIndex: airQualityIndex,
            aiqCategory: airQualityIndex.map { AQICategory(usAQI: $0) },
            sunriseTime: sunriseTime,
            sunsetTime: sunsetTime,
            moonPhase: MoonPhase(rawValue: moonPhaseRaw) ?? .newMoon,
            fetchedAt: lastUpdated
        )
    }
}

extension CachedLocationSnapshot {
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

extension CachedCalendarEvent {
    func toCalendarEvent() -> CalendarEvent? {
        let attendees = (try? JSONDecoder().decode([String].self, from: attendeesJSON)) ?? []
        return CalendarEvent(
            id: eventID,
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            calendarName: calendarName,
            source: CalendarSource(rawValue: sourceRaw) ?? .iCloud,
            attendees: attendees,
            calendarColorHex: calendarColorHex
        )
    }
}

extension CachedTask {
    func toTask() -> Task {
        let due: TaskDue? = dueString.map {
            TaskDue(date: dueDate, string: $0, isRecurring: isRecurring)
        }
        return Task(
            id: taskID,
            content: content,
            description: taskDescription,
            projectID: projectID,
            projectName: projectName,
            due: due,
            priority: TaskPriority(rawValue: priorityRaw) ?? .normal,
            isCompleted: isCompleted,
            isCompleting: false,
            createdAt: nil,
            orderIndex: orderIndex
        )
    }
}

extension CachedJamSession {
    func toJamSession() -> JamSession? {
        guard let url = URL(string: joinURLString) else { return nil }
        return JamSession(
            id: sessionID,
            joinURL: url,
            status: JamStatus(rawValue: statusRaw) ?? .ended,
            startedAt: startedAt
        )
    }
}
