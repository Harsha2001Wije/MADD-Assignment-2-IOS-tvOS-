F1 Race Hub TV

F1 Race Hub TV is a modern, big-screen Formula 1 experience designed exclusively for tvOS. It combines a dynamic Race Weekend Dashboard with an immersive F1 Legends Archive, transforming the Apple TV into a motorsport information hub with stunning visuals and intuitive navigation.

Overview

F1 Race Hub TV delivers two major experiences:

Race Weekend Hub – View race information, track layouts, schedules, standings, and weather for the ongoing Grand Prix.

F1 Legends Archive – Explore a curated gallery of legendary F1 drivers, their iconic cars, championship achievements, and historic moments.

The app uses static data and auto-generated images to create a professional, immersive experience while keeping the prototype lightweight.

Key Features
Race Weekend Hub

Race Overview
* Track map
* Grand Prix name
* Country flag
* Race weekend dates

Session Schedule
* FP1, FP2, FP3
* Qualifying
* Race

Driver Standings
* Position
* Driver portrait
* Team color
* Points

Constructor Standings
* Team logos
* Points table

Weather Forecast
* Temperature
* Track conditions
* Dynamic visual backgrounds

F1 Legends Archive

Driver Gallery
* Legendary drivers
* Portraits
* Country & team color variations

Driver Profile Pages
* Full portrait
* Championships
* Wins
* Poles
* Career timeline
* Iconic car associated with the driver

Legendary Cars Collection
* Side-view renders
* Engine, year, team, wins
* High-quality auto-generated visuals

Settings

Theme selection (Light, Dark, Team Color Mode)

Favorite team selector

About & version information

tvOS UI and Experience

Fully optimized for the tvOS Focus Engine

Smooth animations and card scaling

Distance-friendly large typography

Professional F1-inspired dark theme with red and metallic accents

Auto image placement using Windsurf’s image generator tags

Project Structure

The project is organized into the following layers:

Screens
Home, Race Overview, Session Schedule, Driver Standings, Constructor Standings, Weather, Driver Gallery, Driver Profile, Legendary Cars, Settings

Models
Race data, Drivers, Constructors, Legend drivers, Cars

Local JSON Data
Static race weekend data, standings, driver history, car details

Resources
Auto-generated images handled by Windsurf based on structured image tags

Data Handling

All data is stored locally in simple JSON files covering:

Race weekend information

Driver standings

Constructor standings

Legendary driver profiles

Iconic car information

No external API is required.

Windsurf generates each image automatically based on these tags.

Setup Instructions

Import or clone the project into Windsurf or Xcode.

Run on a tvOS Simulator or Apple TV device.

Ensure image auto-generation is enabled for all image tags.

Navigate using Apple TV remote controls or keyboard arrows.

Testing Checklist

Test focus behavior for all cards and grids

Validate smooth transitions and animations

Confirm all images auto-generate properly

Verify JSON data loads correctly into UI components

Ensure Scan-from-distance readability

Future Enhancements

For future expansion or assignment value, potential features include:

Real-time race results (API integration)

Live telemetry visualizations

Team radio audio snippets

Multi-user profiles

3D interactive track viewer

Apple Watch companion notifications

License

This project is created for educational and demonstration purposes.
Not affiliated with Formula 1®, Formula One Management, or any racing teams.
