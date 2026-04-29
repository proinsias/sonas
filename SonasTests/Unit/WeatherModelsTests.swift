@testable import Sonas
import Testing

// MARK: - AQICategory Tests

@Suite("AQICategory")
struct AQICategoryTests {
    @Test(arguments: [
        (0, AQICategory.good),
        (25, AQICategory.good),
        (50, AQICategory.good),
        (51, AQICategory.moderate),
        (100, AQICategory.moderate),
        (101, AQICategory.unhealthySensitive),
        (150, AQICategory.unhealthySensitive),
        (151, AQICategory.unhealthy),
        (200, AQICategory.unhealthy),
        (201, AQICategory.veryUnhealthy),
        (300, AQICategory.veryUnhealthy),
        (301, AQICategory.hazardous),
        (500, AQICategory.hazardous)
    ])
    func `given usAQI when init then returns correct category`(usAQI: Int, expected: AQICategory) {
        #expect(AQICategory(usAQI: usAQI) == expected)
    }

    @Test(arguments: [
        (AQICategory.good, "Good"),
        (AQICategory.moderate, "Moderate"),
        (AQICategory.unhealthySensitive, "Unhealthy for Sensitive"),
        (AQICategory.unhealthy, "Unhealthy"),
        (AQICategory.veryUnhealthy, "Very Unhealthy"),
        (AQICategory.hazardous, "Hazardous")
    ])
    func `given category when label then returns correct string`(category: AQICategory, expected: String) {
        #expect(category.label == expected)
    }

    @Test(arguments: [
        (AQICategory.good, "#00E400"),
        (AQICategory.moderate, "#FFFF00"),
        (AQICategory.unhealthySensitive, "#FF7E00"),
        (AQICategory.unhealthy, "#FF0000"),
        (AQICategory.veryUnhealthy, "#8F3F97"),
        (AQICategory.hazardous, "#7E0023")
    ])
    func `given category when color then returns correct hex`(category: AQICategory, expected: String) {
        #expect(category.color == expected)
    }
}

// MARK: - PressureTrend Tests

@Suite("PressureTrend")
struct PressureTrendTests {
    @Test(arguments: [
        (PressureTrend.rising, "arrow.up.right"),
        (PressureTrend.steady, "arrow.right"),
        (PressureTrend.falling, "arrow.down.right")
    ])
    func `given trend when symbolName then returns correct sf symbol`(trend: PressureTrend, expected: String) {
        #expect(trend.symbolName == expected)
    }
}

// MARK: - MoonPhase Tests

@Suite("MoonPhase")
struct MoonPhaseTests {
    @Test(arguments: [
        (0.0, MoonPhase.newMoon),
        (0.03, MoonPhase.newMoon),
        (0.0625, MoonPhase.waxingCrescent),
        (0.125, MoonPhase.waxingCrescent),
        (0.1875, MoonPhase.firstQuarter),
        (0.25, MoonPhase.firstQuarter),
        (0.3125, MoonPhase.waxingGibbous),
        (0.375, MoonPhase.waxingGibbous),
        (0.4375, MoonPhase.fullMoon),
        (0.5, MoonPhase.fullMoon),
        (0.5625, MoonPhase.waningGibbous),
        (0.625, MoonPhase.waningGibbous),
        (0.6875, MoonPhase.lastQuarter),
        (0.75, MoonPhase.lastQuarter),
        (0.8125, MoonPhase.waningCrescent),
        (0.9, MoonPhase.waningCrescent)
    ])
    func `given fraction when init then returns correct moon phase`(fraction: Double, expected: MoonPhase) {
        #expect(MoonPhase(fraction: fraction) == expected)
    }

    @Test
    func `given moon phase when displayName then returns rawValue`() {
        for phase in MoonPhase.allCases {
            #expect(phase.displayName == phase.rawValue)
        }
    }

    @Test(arguments: [
        (MoonPhase.newMoon, "moonphase.new.moon"),
        (MoonPhase.waxingCrescent, "moonphase.waxing.crescent"),
        (MoonPhase.firstQuarter, "moonphase.first.quarter"),
        (MoonPhase.waxingGibbous, "moonphase.waxing.gibbous"),
        (MoonPhase.fullMoon, "moonphase.full.moon"),
        (MoonPhase.waningGibbous, "moonphase.waning.gibbous"),
        (MoonPhase.lastQuarter, "moonphase.last.quarter"),
        (MoonPhase.waningCrescent, "moonphase.waning.crescent")
    ])
    func `given moon phase when symbolName then returns correct sf symbol`(phase: MoonPhase, expected: String) {
        #expect(phase.symbolName == expected)
    }
}
