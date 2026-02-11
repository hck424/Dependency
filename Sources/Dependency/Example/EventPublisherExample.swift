//
//  EventPublisherExample.swift
//  Dependency
//
//  Created by 김학철 on 2/10/26.
//

import SwiftUI

struct NavigationEvent: AppEvent {
    let id: Int
}
struct AppLoading: AppEvent {
    var isLoading: Bool
}
struct TaskCompletedEvent: AppEvent {
    let taskName: String
}

struct UserInfo: Codable, AppEvent {
    var name: String
    var age: Int
}

struct ToastItem: Hashable, Equatable, Identifiable, AppEvent {
    var id: Int { hashValue }
    var iconName: String?
    var message: String
    var position: Alignment = .bottom
    var duration: Double = 2.5
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(iconName)
        hasher.combine(message)
        hasher.combine(duration)
    }
    static func ==(lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension EventPublisher {
    public func showLoading(_ isLoading: Bool) {
        self.send(AppLoading(isLoading: isLoading))
    }
    public func showToast(_ msg: String, position: Alignment = .bottom) {
        self.send(ToastItem(message: msg, position: position))
    }
}

@MainActor
class EventPublisherAppViewModel: ObservableObject {
    @Dependency(\.eventPublisher) var eventPublisher
    
    @Published var eventNaviId: Int?
    @Published var eventTaskName: String?
    @Published var toastItem: ToastItem?
    @Published var userInfo: UserInfo?
    @Published var isLoading: Bool = false
    
    func observeEvents() async {
        for await event in eventPublisher.values() {
            await self.handleEvent(event)
        }
    }
    
    func handleEvent(_ event: AppEvent) async {
        eventNaviId = nil
        eventTaskName = nil
        toastItem = nil
        userInfo = nil
        isLoading = false
        
        if let item = event as? NavigationEvent {
            self.eventNaviId = item.id
        }
        else if let item = event as? TaskCompletedEvent {
            self.eventTaskName = item.taskName
        }
        else if let item = event as? ToastItem {
            self.toastItem = item
            try? await Task.sleep(for: .seconds(item.duration))
            self.toastItem = nil
        }
        else if let item = event as? AppLoading {
            self.isLoading = item.isLoading
        }
        else if let item = event as? UserInfo {
            self.userInfo = item
        }
        print(event)
    }
}

struct EventPublisherAppView: View {
    @StateObject var appState = Appstate.shared
    @StateObject private var viewModel = EventPublisherAppViewModel()
    
    var body: some View {
        NavigationStack(path: $appState.path) {
            VStack(spacing: 20) {
                Text("AppView")
                    .padding(.top, 60)
                
    
                if let naviId = viewModel.eventNaviId {
                    Text("Navigation ID: \(naviId)")
                }
                
                if let taskName = viewModel.eventTaskName {
                    Text("Task: \(taskName)")
                }
                
                if let userInfo = viewModel.userInfo {
                    Text("User: \(userInfo.name), Age: \(userInfo.age)")
                }
                
                Button {
                    appState.path.append(1)
                } label: {
                    Label("Go to Child View", systemImage: "arrow.2.circlepath.circle")
                }
            }
            .navigationDestination(for: Int.self) { item in
                EventPublisherChildView(id: item)
            }
        }
        .task {
            await viewModel.observeEvents()
        }
        .overlay {
            GeometryReader { geo in
                if let toast = viewModel.toastItem {
                    
                    let offetY: CGFloat = {
                        if toast.position == .top {
                            return 100
                        }
                        else if toast.position == .bottom {
                            return geo.size.height - 100
                        }
                        else {
                            return geo.size.height/2
                        }
                    }()
                    Text(toast.message)
                        .foregroundColor(.white)
                        .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .background(.black.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .position(x: geo.size.width/2, y: offetY)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(2.0)  // 2배 크기
                        .tint(.red)
                        .progressViewStyle(.circular)
                        .position(x: geo.size.width/2, y: geo.size.height/2)
                }
            }
        }
        
    }
}

#Preview {
    @Previewable @StateObject var appState = Appstate.shared
    EventPublisherAppView()
}


extension EventPublisherChildView {
    class ViewModel: ObservableObject {
        @Dependency(\.eventPublisher) var eventPublisher
        @Published var isLoading: Bool = false
        
        var id: Int
        init(id: Int) {
            self.id = id
        }
        
        enum Action {
            case naviIdTaped
            case taskMsgTapped(String)
            case userInfoTaped
            case showToastTapped
            case showLoadingTapped
        }
        func send(_ action: Action) {
            switch action {
            case .naviIdTaped:
                eventPublisher.send(NavigationEvent(id: id))
            
            case .taskMsgTapped(let msg):
                eventPublisher.send(TaskCompletedEvent(taskName: msg))
                
            case .userInfoTaped:
                let user = UserInfo(name: "Hong gil dong", age: 20)
                eventPublisher.send(user)
            
            case .showToastTapped:
                eventPublisher.showToast("Bula Blala Blala!")
            
            case .showLoadingTapped:
                isLoading.toggle()
                eventPublisher.showLoading(isLoading)
            }
        }
    }
}

struct EventPublisherChildView: View {
    @StateObject var appState = Appstate.shared
    @StateObject private var vm: Self.ViewModel
    
    init(id: Int) {
        _vm = StateObject(wrappedValue: Self.ViewModel(id: id))
    }
    var body: some View {
        VStack(spacing: 16) {
            Text("ChildView: \(vm.id)")
                .padding()
            
            Button {
                vm.send(.naviIdTaped)
            } label: {
                Text("Naivigation Id Taped")
            }
            
            Button {
                vm.send(.taskMsgTapped("Hellow World!"))
            } label: {
                Text("Event Task Message")
            }
            
            Button {
                vm.send(.userInfoTaped)
            } label: {
                Text("UserInfo send Taped")
            }
            
            Button {
                vm.send(.showToastTapped)
            } label: {
                Text("Show Toast Taped")
            }
            
            Button {
                vm.send(.showLoadingTapped)
                
            } label: {
                Text("Loading toggle Tapped")
            }
            Button {
                appState.path.append(vm.id+1)
            } label: {
                Label("Nest Child View", systemImage: "chevron.right")
            }
            .padding(.top, 50)
        }
        .navigationTitle("ChildView \(vm.id)")
    }
}


final class Appstate: ObservableObject {
    nonisolated(unsafe) static var shared = Appstate()
    @Published var path: NavigationPath = .init()
}

@main
struct EventPublisherExample: App {
    
    var body: some Scene {
        WindowGroup {
            EventPublisherAppView()
        }
    }
}

