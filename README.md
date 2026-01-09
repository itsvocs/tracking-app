# Gefühl & Kalorie Tracker

Eine iOS-App zur Verfolgung von Emotionen und Gesundheitsdaten mit Integration von Apple Health.

## Team
- Vocs Pouani (vocs.pouani@ges.thm.de)
- Joyce Manoudjeu (joyce.lavoine.manoudjeu@ges.thm.de)

## Projektübersicht

Die App ermöglicht es Nutzern, ihre emotionale und körperliche Gesundheit zu tracken durch:
- Integration mit Apple Health (Schritte, Kalorien, Schlaf, Wasser)
- Emotionales Tagebuch mit Chatbot-Interface
- Visualisierung durch Graphen
- Tägliche Erinnerungen

## Technologie-Stack

- **Framework:** SwiftUI
- **Datenpersistenz:** SwiftData
- **Architektur:** MVVM (Model-View-ViewModel)
- **Health-Daten:** HealthKit API
- **Authentifizierung:** Google Sign-In
- **Benachrichtigungen:** UserNotifications Framework
- **Design:** iOS 18+ native Design, Dark Mode Support

## Kern-Features

### Muss-Kriterien
1. Google-Authentifizierung (Login/Logout)
2. Apple Health Integration
   - Schritte
   - Verbrannte Kalorien
   - Schlafstunden
   - Wasseraufnahme
3. Gefühls-Tracking mit Tagebuchfunktion
4. Datenvisualisierung mit Graphen
5. Dark Mode Support
6. Benachrichtigungen zu konfigurierbaren Zeiten
7. Einstellungen für Benutzerprofil
8. Datenschutzkonforme lokale Speicherung

### Kann-Kriterien
1. Mehrsprachigkeit (DE/EN/FR)
2. Erweiterte Statistiken
3. Export-Funktion

## Projektstruktur

```
tracking-app/
├── Models/              # SwiftData Models und Health Data Models
├── ViewModels/          # MVVM ViewModels
├── Views/               # SwiftUI Views
│   ├── Authentication/  # Login/Registration
│   ├── Home/           # Dashboard
│   ├── Tracking/       # Gefühls- und Daten-Eingabe
│   ├── Statistics/     # Graphen und Visualisierung
│   └── Settings/       # Einstellungen
├── Services/           # HealthKit, Notifications, etc.
├── Utilities/          # Helper, Extensions
└── Resources/          # Assets, Localizations

```

## Entwicklungsplan (4 Wochen)

### Woche 1: Setup & Grundstruktur
- [ ] Xcode-Projekt erstellen
- [ ] MVVM-Struktur aufsetzen
- [ ] SwiftData Models definieren
- [ ] Google Sign-In Integration
- [ ] Basis-Navigation

### Woche 2: Core Features
- [ ] HealthKit Integration
- [ ] Gefühls-Tracking UI
- [ ] Datenerfassung und -speicherung
- [ ] Basic Dashboard

### Woche 3: Visualisierung & Features
- [ ] Graphen-Komponenten
- [ ] Statistik-Ansichten
- [ ] Benachrichtigungen
- [ ] Einstellungen

### Woche 4: Polish & Testing
- [ ] Dark Mode Feinschliff
- [ ] UI/UX Verbesserungen
- [ ] Testing im Simulator
- [ ] Dokumentation
- [ ] Bug Fixes

## Installation & Setup

### Voraussetzungen
- Xcode 15+
- iOS 17+ SDK
- Google Cloud Console Projekt für OAuth

### Setup-Schritte
1. Repository klonen
2. Dependencies installieren (Google Sign-In SDK)
3. `GoogleService-Info.plist` hinzufügen
4. HealthKit Capabilities aktivieren
5. Info.plist Berechtigungen konfigurieren

## Datenschutz & Sicherheit

- Alle Daten werden lokal mit SwiftData gespeichert
- HealthKit-Daten werden nur mit Nutzererlaubnis abgerufen
- Keine Weitergabe von Daten an Dritte
- DSGVO-konform

## Lizenz

Projekt für das Modul "App Entwicklung in der Medizin" - THM
