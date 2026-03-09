# ProyectoBruma - Memory Log

## Project Overview
A 3D Isometric RPG built in Godot 4, inspired by Argentum Online, Diablo, and Ragnarok Online. Now focusing on a robust **Solo/Co-op RPG** foundation with deep itemization and modular AI.

## Core Architecture (Updated)
- **Event-Driven UI/FX**: 
    - `EventBus` (Autoload): Global signal hub for combat, items, and system events.
    - `FXManager` (Autoload): Centralized handler for world-space effects (floating text, rarity glows).
- **Persistence 2.0**:
    - `GameManager`: Now supports Disk I/O (`user://`), multiple save slots, and automated JSON serialization for all components.
    - `SaveSlotUI`: New menu for selecting/managing character progress.
- **Modular NPC AI**:
    - `StateMachine` & `State`: Robust Finite State Machine (FSM) implementation.
    - NPC behaviors decoupled into `Idle`, `Wander`, and `Talk` states.
- **Decoupled Input**:
    - `InputComponent`: Separates player intent from the entity, enabling easy P2P/Local Co-op support.

## Features Implemented Today (Deep Itemization & Polish)
- **Dynamic Item System (Diablo-Style)**:
    - `ItemInstance`: unique objects containing base `ItemData` + randomized rolls.
    - `Affix` System: Support for prefixes/suffixes (e.g., "Sharp", "of the Whale") that modify stats.
    - **Rarity tiers**: Common, Uncommon, Rare, Epic, Legendary with visual pillars and color-coded labels.
- **Enhanced Character UI**:
    - `CharacterWindow`: Dual-pane layout for Attributes (STR, INT, etc.) and Equipment slots.
    - `RichItemTooltip`: Custom tooltips with **Stat Comparison** (Green/Red indicators).
- **Combat & Co-op Foundation**:
    - **Threat System**: Enemies now track damage from multiple sources and target the highest threat.
    - **Minimap Portal Markers**: Added VIOLET markers for world transitions (Town <-> Wild).
- **World Interaction Polish**:
    - Reduced interaction distance to **1.5m** for NPCs and objects.
    - Standardized all characters to **-Z as Forward** orientation (fixed "walking backwards" and interaction alignment).

## Technical Fixes
- **Orientation Fix**: Corrected rotation logic across `Player.gd`, `NPC.gd`, `Enemy.gd`, and `WanderState.gd` to align with Godot's -Z forward standard.
- **UI Stability**: Resolved `RichItemTooltip` null access, fixed `AIState` type collision in `Enemy.gd`, and cleaned invalid UIDs from `.tscn` files.
- **Equip Sync**: Updated `EquipmentComponent` to fully support `ItemInstance` and affix-based stat calculation.

## Current Status
The game is now a stable "Loot-ARPG" prototype. Players can manage saves, hunt enemies with intelligent target switching, find rare loot with visual pillars, and compare gear via rich tooltips. Movement and interaction are now intuitive and follow engine standards.

---
*Last Update: March 8, 2026*
