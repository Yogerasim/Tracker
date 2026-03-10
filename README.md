# Tracker

Habit tracker iOS app built with **Swift**, **UIKit**, **MVVM**, and **CoreData**.

## Overview

Tracker is a production-style iOS application for tracking habits and irregular events with a strong focus on clean architecture, local persistence, scalable UI, and polished user flows.

The app combines a structured **MVVM** approach, **CoreData** persistence, reusable UI components, analytics integration, onboarding, statistics, filtering, search, and multi-language support. It was built to simulate a real mobile product rather than a simple demo app.

## Key Features

- Create and manage **habits** and **irregular events**
- Organize trackers into **categories**
- Configure **weekly schedules** for recurring habits
- Mark trackers as completed for selected dates
- Built-in **calendar-based date navigation**
- **Search** by tracker name
- **Filtering**: all / today / completed / not completed
- **Edit** and **delete** trackers with context menus
- **Statistics screen** with core usage metrics
- **Onboarding flow** for first launch
- Full **Dark Mode** support
- **Localization** support
- Analytics integration with **Yandex AppMetrica**
- Snapshot testing for UI verification

## Product Functionality

### Trackers Screen
The main screen contains:
- large iOS-style title
- add button
- current date selector
- search bar
- tracker collection grouped by category
- placeholder state for empty results
- long-press context menu for editing and deleting

### Tracker Creation Flow
The app supports two tracker types:
- **Habit** — recurring tracker with schedule selection
- **Irregular Event** — tracker without fixed schedule

The creation flow includes:
- title input
- category selection
- schedule configuration
- emoji selection
- color selection
- validation and duplicate prevention

### Statistics
The statistics screen displays:
- best streak
- ideal days
- completed trackers count
- average completions per day

## Architecture

The project follows **MVVM** and separates responsibilities between view controllers, view models, reusable UI elements, and persistence stores.

### Main architectural points
- **MVVM**
- reusable UI components / lightweight design system
- **CoreData** storage layer with dedicated store classes
- **NSFetchedResultsController** for reactive persistence updates
- **Combine** for filter-related reactive flows
- delegate-based communication between layers
- structured feature-based folders

## Tech Stack

- **Swift**
- **UIKit**
- **MVVM**
- **CoreData**
- **Combine**
- **NSFetchedResultsController**
- **UserDefaults**
- **Yandex AppMetrica**
- **swift-log**
- **Snapshot Testing**
- **Programmatic UI**
- **Dark Mode**
- **Localization**

## Data Layer

The application uses **CoreData** for local persistence and includes dedicated stores for:
- trackers
- tracker categories
- completion records

This allows the app to support CRUD operations, statistics, and dynamic UI updates based on persisted data.

## Localization

The project includes localization support with complete or partial setup for multiple languages, including:
- Russian
- English
- French

It also includes pluralization handling and locale-aware date formatting.

## Why this project is strong

Tracker demonstrates not just UI implementation, but a more complete product mindset:

- app architecture
- persistence
- state handling
- reusable UI
- onboarding
- analytics
- statistics
- filtering and search
- dark mode
- localization
- release-oriented structure

This makes it closer to a real-world junior / middle iOS product codebase than a basic educational CRUD app.

## Potential Next Steps

Possible product extensions:
- push notifications / reminders
- iCloud or backend sync
- widgets
- settings screen
- accessibility improvements
- unit tests
- export / import flows
- monetization

## Author

**Philip Gerasimov**  
iOS Developer  
GitHub: [Yogerasim](https://github.com/Yogerasim)
