//
//  SettingsView.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plants: [Plant]
    @State private var viewModel: SettingsViewModel?
    @State private var showingHASetupGuide = false
    
    var body: some View {
        NavigationStack {
            Form {
                homeAssistantSection
                deviceSection
                notificationsSection
                haSetupGuideSection
            }
            .navigationTitle("⚙️ Settings")
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(modelContext: modelContext)
                }
            }
            .onDisappear {
                viewModel?.saveSettings()
            }
        }
    }
    
    private var homeAssistantSection: some View {
        Section("Home Assistant") {
            TextField("Nabu Casa URL", text: Binding(
                get: { viewModel?.nabucasaURL ?? "" },
                set: { viewModel?.nabucasaURL = $0 }
            ))
            .keyboardType(.URL)
            .textContentType(.URL)
            .autocapitalization(.none)
            .textInputAutocapitalization(.never)
            
            HStack {
                if viewModel?.haToken.isEmpty == false {
                    SecureField("Long-Lived Access Token", text: Binding(
                        get: { viewModel?.haToken ?? "" },
                        set: { viewModel?.haToken = $0 }
                    ))
                } else {
                    TextField("Long-Lived Access Token", text: Binding(
                        get: { viewModel?.haToken ?? "" },
                        set: { viewModel?.haToken = $0 }
                    ))
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                }
                
                Button(action: {
                    viewModel?.showingTokenInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }
            
            if viewModel?.showingTokenInfo == true {
                Text("Create a Long-Lived Access Token in Home Assistant: Profile → Security → Long-Lived Access Tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: {
                Task {
                    await viewModel?.testConnection()
                }
            }) {
                HStack {
                    if viewModel?.isTesting == true {
                        ProgressView()
                    } else {
                        Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                    }
                }
            }
            .disabled(viewModel?.isTesting == true)
            
            if let testResult = viewModel?.testResult {
                switch testResult {
                case .success:
                    Label("Connection successful!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failure(let message):
                    VStack(alignment: .leading) {
                        Label("Connection failed", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var deviceSection: some View {
        Section("Device") {
            TextField("Device Name", text: Binding(
                get: { viewModel?.deviceName ?? "" },
                set: { viewModel?.deviceName = $0 }
            ))
            .textContentType(.name)
            
            Text("This name appears in Home Assistant events to identify who watered each plant")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Watering Reminders", isOn: Binding(
                get: { viewModel?.notificationsEnabled ?? true },
                set: { newValue in
                    viewModel?.notificationsEnabled = newValue
                    if newValue {
                        Task {
                            await viewModel?.requestNotificationPermission()
                        }
                    }
                }
            ))
            
            if viewModel?.notificationsEnabled == true {
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: { viewModel?.notificationTime ?? Date() },
                        set: { viewModel?.notificationTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
            
            Stepper(
                "Default Interval: \(viewModel?.defaultWateringIntervalDays ?? 7) days",
                value: Binding(
                    get: { viewModel?.defaultWateringIntervalDays ?? 7 },
                    set: { viewModel?.defaultWateringIntervalDays = $0 }
                ),
                in: 1...30
            )
        }
    }
    
    private var haSetupGuideSection: some View {
        Section {
            DisclosureGroup("Home Assistant Setup") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Manual Helper Creation Required")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("For each plant, create an input_datetime helper in Home Assistant:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steps:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text("1. Settings → Devices & Services → Helpers")
                            .font(.caption)
                        Text("2. + Create Helper → Date and/or time")
                            .font(.caption)
                        Text("3. Enable both 'Has date' and 'Has time'")
                            .font(.caption)
                        Text("4. Use the entity ID shown below")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    
                    if !plants.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Plant Helpers:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(plants) { plant in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(plant.emoji) \(plant.name)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text(plant.haEntityID)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.blue)
                                        .textSelection(.enabled)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    Text("💡 Tip: Create automations triggered by the aquatag_plant_watered event for notifications, logging, or smart home actions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }
}
