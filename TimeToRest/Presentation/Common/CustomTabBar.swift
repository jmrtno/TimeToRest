import SwiftUI

// MARK: - CustomTabBar
/// Barra de navegación inferior personalizada con dos botones:
/// - Modo noche (icono de luna)
/// - Estadísticas (icono de gráfico)
/// El botón seleccionado se muestra en naranja.
struct CustomTabBar: View {
    
    @Binding var currentView: HomeScreen.ViewType
    
    var body: some View {
        HStack(spacing: 0) {
            // Botón de Modo Noche (Home)
            Button {
                currentView = .home
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: currentView == .home ? "moon.fill" : "moon")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(currentView == .home ? .orange : .gray)
                    
                    Text("Rest")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(currentView == .home ? .orange : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Stats button
            Button {
                currentView = .stats
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: currentView == .stats ? "chart.bar.fill" : "chart.bar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(currentView == .stats ? .orange : .gray)
                    
                    Text("Statistics")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(currentView == .stats ? .orange : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())

            // Settings button
            Button {
                currentView = .settings
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: currentView == .settings ? "gearshape.fill" : "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(currentView == .settings ? .orange : .gray)
                    
                    Text("Settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(currentView == .settings ? .orange : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .background(
            Color.black.opacity(0.9)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(.white.opacity(0.1)),
                    alignment: .top
                )
        )
    }
}
