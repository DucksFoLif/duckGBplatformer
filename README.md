
# Duck Game Platformer (WIP)

A work-in-progress Game Boy platformer tech demo built in assembly language. This project demonstrates basic game mechanics like gravity, jumping, level switching, and sprite interactivity.

## Features
- **Mostly working gravity** and jumping mechanics.
- **Level switching** and loading different environments.
- **Multiple sprites** on-screen with interactive elements.
- Basic **player controls** and environment interactions.

## Current Status
This game is still in development and serves as a technical demo for showcasing basic platformer mechanics on the Game Boy.

## How to Build and Run
1. Clone the repository:
   ```bash
   git clone git@github.com:DucksFoLif/duckGBplatformer.git
   cd duckGBplatformer
   ```

2. Build the game:
   ```bash
   make
   make fix
   ```

3. Run the ROM on a Game Boy emulator (like BGB or Gambatte):
   ```bash
   bgb duckgame.gb
   ```

## Notes
- The game is still in progress, and many features are subject to change or improvement.
- Make sure to run `make fix` to ensure the ROM is runnable after compiling.
