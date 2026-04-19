import Foundation
import SwiftData

// MARK: - CachedWeatherSnapshot

@Model
final class CachedWeatherSnapshot {
    var temperature: Double = 0
    var feelsLike: Double = 0
    var conditionDescription: String = ""
    var conditionSymbolName: String = ""
    var humidity: Double = 0
    var windSpeed: Double = 0
    var windDirection: Double = 0
    var windCompassLabel: String = ""
    var pressure: Double = 0
    var pressureTrendRaw: String = ""
    var airQualityIndex: Int?
    var sunriseTime = Date.distantPast
    var sunsetTime = Date.distantPast
    var moonPhaseRaw: String = ""
    var forecastJSON = Data() // Encoded [DayForecast] via JSONEncoder
    var lastUpdated = Date.distantPast

    init(
        temperature: Double, feelsLike: Double,
        conditionDescription: String, conditionSymbolName: String,
        humidity: Double, windSpeed: Double, windDirection: Double, windCompassLabel: String,
        pressure: Double, pressureTrendRaw: String, airQualityIndex: Int?,
        sunriseTime: Date, sunsetTime: Date, moonPhaseRaw: String,
        forecastJSON: Data, lastUpdated: Date,
    ) {
        self.temperature = temperature; self.feelsLike = feelsLike
        self.conditionDescription = conditionDescription; self.conditionSymbolName = conditionSymbolName
        self.humidity = humidity; self.windSpeed = windSpeed
        self.windDirection = windDirection; self.windCompassLabel = windCompassLabel
        self.pressure = pressure; self.pressureTrendRaw = pressureTrendRaw
        self.airQualityIndex = airQualityIndex
        self.sunriseTime = sunriseTime; self.sunsetTime = sunsetTime; self.moonPhaseRaw = moonPhaseRaw
        self.forecastJSON = forecastJSON; self.lastUpdated = lastUpdated
    }
}

// MARK: - CachedLocationSnapshot

@Model
final class CachedLocationSnapshot {
    var memberID: String = ""
    var displayName: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var placeName: String = ""
    var recordedAt = Date.distantPast
    var lastUpdated = Date.distantPast

    init(memberID: String, displayName: String,
         latitude: Double, longitude: Double,
         placeName: String, recordedAt: Date, lastUpdated: Date) {
        self.memberID = memberID; self.displayName = displayName
        self.latitude = latitude; self.longitude = longitude
        self.placeName = placeName; self.recordedAt = recordedAt; self.lastUpdated = lastUpdated
    }
}

// MARK: - CachedCalendarEvent

@Model
final class CachedCalendarEvent {
    var eventID: String = ""
    var title: String = ""
    var startDate = Date.distantPast
    var endDate = Date.distantPast
    var isAllDay: Bool = false
    var calendarName: String = ""
    var sourceRaw: String = ""
    var attendeesJSON = Data() // Encoded [String] via JSONEncoder
    var calendarColorHex: String?
    var lastUpdated = Date.distantPast

    init(eventID: String, title: String, startDate: Date, endDate: Date,
         isAllDay: Bool, calendarName: String, sourceRaw: String,
         attendeesJSON: Data, calendarColorHex: String?, lastUpdated: Date) {
        self.eventID = eventID; self.title = title
        self.startDate = startDate; self.endDate = endDate; self.isAllDay = isAllDay
        self.calendarName = calendarName; self.sourceRaw = sourceRaw
        self.attendeesJSON = attendeesJSON; self.calendarColorHex = calendarColorHex
        self.lastUpdated = lastUpdated
    }
}

// MARK: - CachedTask

@Model
final class CachedTask {
    var taskID: String = ""
    var content: String = ""
    var taskDescription: String = ""
    var projectID: String = ""
    var projectName: String = ""
    var priorityRaw: Int = 0
    var isCompleted: Bool = false
    var dueDate: Date?
    var dueString: String?
    var isRecurring: Bool = false
    var orderIndex: Int = 0
    var lastUpdated = Date.distantPast

    init(taskID: String, content: String, taskDescription: String,
         projectID: String, projectName: String, priorityRaw: Int,
         isCompleted: Bool, dueDate: Date?, dueString: String?,
         isRecurring: Bool, orderIndex: Int, lastUpdated: Date) {
        self.taskID = taskID; self.content = content; self.taskDescription = taskDescription
        self.projectID = projectID; self.projectName = projectName; self.priorityRaw = priorityRaw
        self.isCompleted = isCompleted; self.dueDate = dueDate; self.dueString = dueString
        self.isRecurring = isRecurring; self.orderIndex = orderIndex; self.lastUpdated = lastUpdated
    }
}

// MARK: - CachedJamSession

@Model
final class CachedJamSession {
    var sessionID: String = ""
    var joinURLString: String = ""
    var statusRaw: String = ""
    var startedAt = Date.distantPast
    var lastUpdated = Date.distantPast

    init(sessionID: String, joinURLString: String, statusRaw: String,
         startedAt: Date, lastUpdated: Date) {
        self.sessionID = sessionID; self.joinURLString = joinURLString
        self.statusRaw = statusRaw; self.startedAt = startedAt; self.lastUpdated = lastUpdated
    }
}
