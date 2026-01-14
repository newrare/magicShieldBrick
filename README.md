# Magic Shield Brick

A breakout-like game but without bricks, where the goal is to protect your player using a circular magical shield. A simple mobile game where you protect your character with a circular magical shield. The goal is to survive as long as possible by collecting stars to achieve a higher score. Addictive, simple, and efficient gameplay. A quick and casual experience for mobile.


## 🎮 Game Features

- **Unique Gameplay**: Protect the player character using a circular shield instead of breaking bricks
- **Magical Shield System**: Dynamic shield mechanics with visual effects
- **Multi-language Support**: Available in French and English
- **Heart Animation System**: Animated life display with loss effects
- **Pause System**: Complete pause functionality with options menu
- **Score Management**: High score tracking and ranking system
- **🎯 Touch Support**: Full touch/mouse support for PC and mobile (Android/iOS)
  - Shield follows finger/mouse position
  - All buttons work with touch and mouse
  - Adaptive sound effects (hover on PC, tap on mobile)

## 🚀 Getting Started

### Prerequisites
- **Godot Engine 4.5+** (recommended)
- Basic knowledge of GDScript (for development)

### Installation
1. Clone this repository
2. Open the project in Godot Engine
3. Press F5 to run the game

## 📁 Project Structure

```
magicShieldBrick/
├── assets/                     # Game assets
│   ├── images/                 # Game textures and sprites
│   └── sounds/                 # Audio files
├── managers/                   # Manager scripts
│   ├── AudioManager.gd         # Audio system management
│   ├── BonusLifeManager.gd     # Bonus life system
│   ├── GameManager.gd          # Game state management
│   ├── GameStatsManager.gd     # Game statistics tracking
│   ├── LanguageManager.gd      # Localization system
│   ├── ScoreManager.gd         # Score tracking system
│   └── ToolsManager.gd         # Utility tools
├── menus/                      # Menu scripts
│   ├── GameOverMenu.gd         # Game over menu logic
│   ├── MainMenu.gd             # Main menu logic
│   ├── OptionsMenu.gd          # Options menu functionality
│   ├── PauseMenu.gd            # Pause menu system
│   ├── RankingMenu.gd          # Ranking menu logic
│   └── widgets/                # UI widgets
│       └── UIButton.gd         # Custom button component
├── objects/                    # Game objects
│   ├── Ball.gd                 # Ball physics and behavior
│   ├── BonusBall.gd            # Bonus ball mechanics
│   ├── BonusBall.tscn          # Bonus ball scene
│   ├── Player.gd               # Player character
│   ├── Shield.gd               # Shield mechanics
│   └── visuals/                # Visual effects
│       └── ShieldVisual.gd     # Shield visual effects
├── scenes/                     # Godot scene files
│   ├── BonusLifeAdScene.gd     # Bonus life ad scene logic
│   ├── BonusLifeAdScene.tscn   # Bonus life ad scene
│   ├── GameOverMenu.tscn       # Game over menu
│   ├── GameScene.gd            # Main game logic
│   ├── GameScene.tscn          # Main game scene
│   ├── MainMenu.tscn           # Main menu
│   ├── OptionsMenu.tscn        # Options/settings menu
│   └── RankingScene.tscn       # Score ranking scene
├── project.godot               # Godot project configuration
└── README.md                   # This file
```

## Commands
```
cd <project_folder>
godot
godot project.godot
godot --export-debug "Android" ./magicShieldBrick.apk
```

## 🎯 Game Mechanics

### Core Gameplay
- **Shield Protection**: Use the magical circular shield to deflect ball attacks
- **Life System**: Hearts represent player lives with animated loss effects
- **Progressive Difficulty**: Game becomes more challenging over time

### Controls

#### PC (Desktop)
- **Shield**: Mouse movement to position the shield
- **Pause**: ESC or SPACE key
- **Language**: Toggle in options menu

#### Mobile (Android/iOS)
- **Shield**: Touch and drag with finger
- **Pause**: Tap the PAUSE button
- **Buttons**: Tap any button to activate

> **Note**: Mouse and touch work identically - the same code handles both!

## 🛠️ Development

### Built With
- **Godot Engine 4.5**: Game engine
- **GDScript**: Programming language
- **Tween System**: For smooth animations
- **Signal System**: For component communication

### Key Systems
- **Language Management**: Centralized localization system
- **Score Tracking**: Persistent high score system
- **Animation System**: Tween-based heart and UI animations
- **Input Handling**: Comprehensive input management with conflict resolution

## 🌍 Localization

The game supports multiple languages:
- 🇺🇸 English
- 🇫🇷 French

Language can be switched dynamically through the options menu.

## 📊 Technical Details

- **Engine**: Godot 4.5+
- **Rendering**: Mobile renderer with GL compatibility
- **Physics**: CharacterBody2D for player movement
- **Collision**: Area2D for shield interactions
- **Animation**: Tween nodes for smooth effects
- **Input**: Unified mouse/touch input system
- **Platform**: PC (Windows, Linux, Mac), Mobile (Android, iOS)

### 📱 Mobile Support

Full touch support implemented:
- **Touch Input**: `emulate_mouse_from_touch` enabled in project settings
- **Test Mode**: `emulate_touch_from_mouse` for PC testing
- **Smart Sounds**: Adaptive audio feedback based on platform detection

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

