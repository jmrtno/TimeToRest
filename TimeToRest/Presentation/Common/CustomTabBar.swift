import SwiftUI

// MARK: - CustomTabBar
/// Barra de navegación inferior personalizada con dos botones:
/// - Modo noche (icono de luna)
/// - Estadísticas (icono de gráfico)
/// El botón seleccionado se muestra en naranja.
struct CustomTabBar: View {
    
    @EnvironmentObject private var router: Router
    @State private var selectedTab: TabItem = .home
    
    enum TabItem {
        case home
        case stats
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Botón de Modo Noche (Home)
            Button {
                selectedTab = .home
                if !router.navigationPath.isEmpty {
                    router.popToRoot()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(selectedTab == .home ? .orange : .gray)
                    
                    Text("Descanso")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(selectedTab == .home ? .orange : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Botón de Estadísticas
            Button {
                selectedTab = .stats
                router.push(.stats)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(selectedTab == .stats ? .orange : .gray)
                    
                    Text("Estadísticas")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(selectedTab == .stats ? .orange : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.9)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(.white.opacity(0.1)),
                    alignment: .top
                )
        )
        .onAppear {
            updateSelectedTab()
        }
        .onChange(of: router.navigationPath) { _, newPath in
            updateSelectedTab()
        }
    }
    
    private func updateSelectedTab() {
        if router.navigationPath.isEmpty {
            selectedTab = .home
        } else if router.navigationPath.contains(.stats) {
            selectedTab = .stats
        }
    }
}
