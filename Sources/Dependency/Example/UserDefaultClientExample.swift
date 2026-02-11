//
//  UserDefaultClientExample.swift
//  Dependency
//
//  Created on 2/10/26.
//

import SwiftUI

enum UserKeys: String, UserDefaultKey {
    case userName
    case userAge
    case isLoggedIn
    case lastLoginDate
    case userSettings
    case pushToken
}

// MARK: - 사용 예제: ViewModel
final class UserViewModel: ObservableObject {
    @Dependency(\.userDefaults) var userDefaults
    
    
    func getUserName() -> String {
        userDefaults.string(UserKeys.userName)
    }
    
    func setUserName(_ value: String) {
        userDefaults.setValue(value, UserKeys.userName)
    }
    
    func getUserAge() -> Int {
        userDefaults.int(UserKeys.userAge)
    }
    
    func setUserAge(_ value: Int) {
        userDefaults.setValue(value, UserKeys.userAge)
    }
    
    func getIsLoggedIn() -> Bool {
        userDefaults.bool(UserKeys.isLoggedIn)
    }
    
    func setIsLoggedIn(_ value: Bool) {
        userDefaults.setValue(value, UserKeys.isLoggedIn)
    }
    
    func getPushToken() -> String {
        userDefaults.string(UserKeys.pushToken)
    }
    
    func setPushToken(_ value: String) {
        userDefaults.setValue(value, UserKeys.pushToken)
    }
    
    func saveLastLoginDate() {
        let data = try? JSONEncoder().encode(Date())
        if let data = data {
            userDefaults.setValue(data, UserKeys.lastLoginDate)
        }
    }
    
    func getLastLoginDate() -> Date? {
        guard let data = userDefaults.data(UserKeys.lastLoginDate) else { return nil }
        return try? JSONDecoder().decode(Date.self, from: data)
    }
    
    func logout() {
        userDefaults.remove(UserKeys.userName)
        userDefaults.remove(UserKeys.userAge)
        setIsLoggedIn(false)
        userDefaults.remove(UserKeys.pushToken)
    }
}

// MARK: - 사용 예제: SwiftUI View
struct UserProfileView: View {
    @State private var viewModel = UserViewModel()
    @State private var nameInput = ""
    @State private var ageInput = ""
    
    var body: some View {
        Form {
            Section("사용자 정보") {
                TextField("이름", text: $nameInput)
                    .onSubmit {
                        viewModel.setUserName(nameInput)
                    }
                
                TextField("나이", text: $ageInput)
                    .keyboardType(.numberPad)
                    .onSubmit {
                        if let age = Int(ageInput) {
                            viewModel.setUserAge(age)
                        }
                    }
                
                Button("저장") {
                    viewModel.setUserName(nameInput)
                    if let age = Int(ageInput) {
                        viewModel.setUserAge(age)
                    }
                    viewModel.saveLastLoginDate()
                }
            }
            
            Section("저장된 정보") {
                LabeledContent("이름", value: viewModel.getUserName())
                LabeledContent("나이", value: "\(viewModel.getUserAge())")
                LabeledContent("로그인 상태", value: viewModel.getIsLoggedIn() ? "로그인됨" : "로그아웃됨")
                
                if let lastLogin = viewModel.getLastLoginDate() {
                    LabeledContent("마지막 로그인", value: lastLogin.formatted())
                }
            }
            
            Section {
                Button("로그인") {
                    viewModel.setIsLoggedIn(true)
                    viewModel.saveLastLoginDate()
                }
                .disabled(viewModel.getIsLoggedIn())
                
                Button("로그아웃", role: .destructive) {
                    viewModel.logout()
                    nameInput = ""
                    ageInput = ""
                }
                .disabled(!viewModel.getIsLoggedIn())
            }
        }
        .navigationTitle("사용자 프로필")
        .onAppear {
            nameInput = viewModel.getUserName()
            ageInput = viewModel.getUserAge() > 0 ? "\(viewModel.getUserAge())" : ""
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        UserProfileView()
    }
}
