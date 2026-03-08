import SwiftUI

struct SidebarView: View {
    
    @ObservedObject var bottleManager: BottleManager
    @EnvironmentObject var appState: AppState
    @State private var showNewBottle  = false
    @State private var searchText     = ""
    @State private var showDeleteAlert = false
    @State private var bottleToDelete: Bottle?
    
    var filteredBottles: [Bottle] {
        if searchText.isEmpty { return bottleManager.bottles }
        return bottleManager.bottles.filter { (bottle: Bottle) -> Bool in
            bottle.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Logo
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(BourbonColors.accent)
                Text("Bourbon")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // MARK: - Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(BourbonColors.textSecondary)
                    .font(.system(size: 12))
                TextField("Search bottles...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(BourbonColors.textSecondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
            Divider()
                .background(BourbonColors.border)
            
            // MARK: - Bottles List
            ScrollView {
                LazyVStack(spacing: 2) {
                    if bottleManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Creating bottle...")
                                .font(.caption)
                                .foregroundStyle(BourbonColors.textSecondary)
                        }
                        .padding(.top, 20)
                    } else if filteredBottles.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "cylinder")
                                .font(.largeTitle)
                                .foregroundStyle(BourbonColors.textSecondary)
                            Text(searchText.isEmpty
                                 ? "No bottles yet"
                                 : "No results")
                                .font(.subheadline)
                                .foregroundStyle(BourbonColors.textSecondary)
                            if searchText.isEmpty {
                                Text("Create one to get started")
                                    .font(.caption)
                                    .foregroundStyle(BourbonColors.textSecondary)
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredBottles) { bottle in
                            SidebarBottleRow(
                                bottle: bottle,
                                isSelected: appState.selectedBottle?.id == bottle.id
                            ) {
                                appState.selectedBottle = bottle
                            } onDelete: {
                                bottleToDelete = bottle
                                showDeleteAlert = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
            
            Spacer()
            
            Divider()
                .background(BourbonColors.border)
            
            // MARK: - Bottom Bar
            HStack {
                StatusBadge(status: appState.engineStatus)
                Spacer()
                Button(action: { showNewBottle = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("New Bottle")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(BourbonColors.accentLight)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(BourbonColors.sidebar)
        .sheet(isPresented: $showNewBottle) {
            NewBottleView(bottleManager: bottleManager)
        }
        .alert(
            "Delete \(bottleToDelete?.name ?? "Bottle")?",
            isPresented: $showDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                if let bottle = bottleToDelete {
                    // Deselect if this bottle was selected
                    if appState.selectedBottle?.id == bottle.id {
                        appState.selectedBottle = nil
                    }
                    bottleManager.deleteBottle(bottle)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the bottle and all its contents.")
        }
    }
}

// MARK: - Sidebar Bottle Row
struct SidebarBottleRow: View {
    
    let bottle:     Bottle
    let isSelected: Bool
    let onSelect:   () -> Void
    let onDelete:   () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected
                            ? BourbonColors.accent
                            : Color.white.opacity(0.07)
                        )
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: "cylinder.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(
                            isSelected ? .white : BourbonColors.accent
                        )
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(bottle.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text("\(bottle.programCount) · \(bottle.windowsVersion.displayName)")
                        .font(.system(size: 11))
                        .foregroundStyle(BourbonColors.textSecondary)
                }
                
                Spacer()
                
                // Warning if not initialized
                if !bottle.isInitialized {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                        ? BourbonColors.accent.opacity(0.15)
                        : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open C: Drive") {
                NSWorkspace.shared.open(bottle.cDrivePath)
            }
            Divider()
            Button("Delete Bottle", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Empty Detail View
struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 56))
                .foregroundStyle(BourbonColors.accent.opacity(0.4))
            
            Text("No Bottle Selected")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            Text("Select a bottle from the sidebar\nor create a new one to get started")
                .font(.subheadline)
                .foregroundStyle(BourbonColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BourbonColors.background)
    }
}
