///
//  WeatherView.swift
//  Coursework
//

import SwiftUI
import CoreLocation

struct WeatherView: View {
    @EnvironmentObject var locationsManager: LocationsManager
    @State private var weatherInfo: String = "Select a location to see weather."
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Fetching weather...")
            } else {
                Text(weatherInfo)
                    .font(.title)
                    .padding()
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            fetchWeather()
        }
    }

    private func fetchWeather() {
        guard let selectedLocation = locationsManager.selectedLocation else {
            errorMessage = "No location selected. Please select a location first."
            return
        }

        isLoading = true
        errorMessage = nil
        weatherInfo = ""

        let apiKey = "98c9baa219b52887db058b4b38006233"
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(selectedLocation.latitude)&lon=\(selectedLocation.longitude)&units=metric&appid=\(apiKey)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch weather: \(error?.localizedDescription ?? "Unknown error")"
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    weatherInfo = "Weather: \(response.weather.first?.description ?? "N/A"), Temp: \(response.main.temp)°C"
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Error decoding weather data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct WeatherResponse: Codable {
    let weather: [Weather]
    let main: MainWeather

    struct Weather: Codable {
        let description: String
    }

    struct MainWeather: Codable {
        let temp: Double
    }
}
