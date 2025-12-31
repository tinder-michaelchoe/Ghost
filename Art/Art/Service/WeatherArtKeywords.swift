//
//  WeatherArtKeywords.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import CoreContracts

/// Maps weather conditions to art search keywords.
/// Keywords are ordered by specificity - more evocative terms first.
enum WeatherArtKeywords {

    /// Returns an ordered list of keywords for the given weather condition.
    /// The service will try each keyword in order until art is found.
    static func keywords(for condition: WeatherCondition) -> [String] {
        switch condition {
        case .clear:
            return ["sunlight", "golden", "radiant", "pastoral", "meadow", "serene", "luminous", "dawn", "horizon", "bright"]

        case .partlyCloudy:
            return ["afternoon", "pastoral", "countryside", "gentle", "idyllic", "tranquil", "breeze", "dappled", "scenic", "verdant"]

        case .cloudy:
            return ["overcast", "gray", "mist", "veiled", "subdued", "somber", "melancholy", "dusk", "shadow", "pensive"]

        case .rain:
            return ["rain", "storm", "deluge", "umbrella", "puddle", "wet", "shower", "autumn", "gloomy", "reflections"]

        case .heavyRain:
            return ["storm", "tempest", "downpour", "flood", "dramatic", "turbulent", "dark", "torrent", "monsoon", "fury"]

        case .thunderstorm:
            return ["lightning", "tempest", "dramatic", "chaos", "turbulent", "ominous", "thunder", "violent", "fury", "electric"]

        case .snow:
            return ["snow", "winter", "frost", "frozen", "ice", "cold", "white", "december", "blizzard", "arctic"]

        case .sleet:
            return ["frost", "ice", "winter", "cold", "frozen", "gray", "bleak", "harsh", "bitter", "chill"]

        case .fog:
            return ["fog", "mysterious", "ethereal", "shrouded", "ghostly", "obscured", "vapor", "dim", "haunting", "dreamlike"]

        case .windy:
            return ["wind", "movement", "flowing", "billowing", "dynamic", "swept", "gust", "motion", "turbulent", "wild"]
        }
    }

    /// Returns a generic "art of the day" keyword list as fallback.
    static var fallbackKeywords: [String] {
        ["masterpiece", "portrait", "landscape", "classical", "renaissance", "impressionist", "beauty", "nature", "figure", "romantic"]
    }
}
