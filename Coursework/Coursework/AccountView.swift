//
//  AccountView.swift
//  Coursework
//
//  Created by Leon Liao on 1/1/2025.
//

import SwiftUI
import LocalAuthentication
import Combine

struct AccountView: View {
    @EnvironmentObject var locationsManager: LocationsManager // 獲取共享的數據模型
    
    @State private var username: String = "" // 用戶名
    @State private var password: String = "" // 密碼
    @State private var isLoggedIn: Bool = false // 登錄狀態
    @State private var savedLocations: [AnnotatedItem] = [] // 用戶保存的地點列表
    @State private var showBiometricPrompt: Bool = false // 是否顯示 Biometric 登錄提示
    @State private var biometricError: String? = nil // Biometric Error 信息
    @State private var isRegistering: Bool = false // 是否處於註冊模式
    @State private var showLocationsView: Bool = false // 是否顯示 LocationsView

    var body: some View {
        NavigationView {
            VStack {
                if isLoggedIn {
                    // 已登錄狀態
                    Text("Welcome, \(username)!")
                        .font(.largeTitle)
                        .padding()

                    // 顯示保存地點列表
                    List {
                        Section(header: Text("Saved Locations")) {
                            if locationsManager.savedLocations.isEmpty {
                                Text("No saved locations yet.")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(locationsManager.savedLocations, id: \.id) { location in
                                    VStack(alignment: .leading) {
                                        Text(location.name).font(.headline)
                                        Text("\(location.coordinate.latitude), \(location.coordinate.longitude)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())

                    Button("Logout") {
                        logout()
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.red)
                } else {
                    Text("Please log in to see saved locations.")
                        .foregroundColor(.gray)
                    // 未登錄狀態
                    Text(isRegistering ? "Register" : "Login")
                        .font(.largeTitle)
                        .padding()

                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .padding(.bottom)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.bottom)

                    if isRegistering {
                        Button("Register") {
                            register()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom)
                    } else {
                        Button("Login") {
                            login()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom)

                        Button("Login with Face ID / Touch ID") {
                            authenticateWithBiometrics()
                        }
                        .buttonStyle(.bordered)
                        .padding(.bottom)

                        if let biometricError = biometricError {
                            Text(biometricError)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.top, 5)
                        }
                    }

                    Button(isRegistering ? "Already have an account? Login" : "Don't have an account? Register") {
                        isRegistering.toggle()
                    }
                    .foregroundColor(.blue)
                    .padding(.top)
                }
            }
            .padding()
            .navigationTitle("CityNavigator")
            .sheet(isPresented: $showLocationsView) {
                // 傳遞閉包給 LocationsView
                LocationsView { newLocation in
                    addNewLocation(newLocation)
                }
            }
            .onAppear {
                if isLoggedIn {
                    loadSavedLocations()
                }
            }
        }
    }

    // MARK: - 添加新地點
    private func addNewLocation(_ location: AnnotatedItem) {
        savedLocations.append(location)
        saveLocationsToUserDefaults()
    }

    // MARK: - 從 UserDefaults 加載保存的地點
    private func loadSavedLocations() {
        if let data = UserDefaults.standard.data(forKey: "locations_\(username)"),
           let locations = try? JSONDecoder().decode([AnnotatedItem].self, from: data) {
            savedLocations = locations
        }
    }

    // MARK: - 保存地點到 UserDefaults
    private func saveLocationsToUserDefaults() {
        if let data = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(data, forKey: "locations_\(username)")
        }
    }

    // MARK: - 登錄方法
    private func login() {
        guard !username.isEmpty && !password.isEmpty else {
            biometricError = "Username and password cannot be empty."
            return
        }
        

        if let storedPassword = UserDefaults.standard.string(forKey: "password_\(username)"), storedPassword == password {
            isLoggedIn = true
            biometricError = nil
            saveAccountForBiometric()
            locationsManager.syncWithAccount(username: username) // 同步用戶地點數據
        } else {
            biometricError = "Invalid username or password."
        }
    }

    // MARK: - 註冊方法
    private func register() {
        guard !username.isEmpty && !password.isEmpty else {
            biometricError = "Username and password cannot be empty."
            return
        }

        if UserDefaults.standard.string(forKey: "password_\(username)") == nil {
            UserDefaults.standard.set(password, forKey: "password_\(username)")
            UserDefaults.standard.set([], forKey: "locations_\(username)")
            biometricError = nil
            isRegistering = false
            saveAccountForBiometric()
        } else {
            biometricError = "Username already exists."
        }
    }

    // MARK: - 注銷登錄
    private func logout() {
        isLoggedIn = false
        username = ""
        password = ""
        locationsManager.logout() // 清空用戶地點數據
    }

    // MARK: - 保存賬戶以便 Biometric 登錄
    private func saveAccountForBiometric() {
        UserDefaults.standard.set(username, forKey: "lastLoggedInUsername")
    }

    // MARK: - 使用 Biometric 登錄
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your account with Face ID / Touch ID."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        if let savedUsername = UserDefaults.standard.string(forKey: "lastLoggedInUsername"),
                           let savedPassword = UserDefaults.standard.string(forKey: "password_\(savedUsername)") {
                            self.username = savedUsername
                            self.password = savedPassword
                            self.login()
                        } else {
                            self.biometricError = "No saved account for biometric login."
                        }
                    } else {
                        self.biometricError = "Biometric authentication failed."
                    }
                }
            }
        } else {
            biometricError = "Biometric authentication not available."
        }
    }
}

#Preview {
    AccountView()
}
