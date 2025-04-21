// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TicTacToe {
    // State variables
    address public host;
    address public challenger;
    uint8 public winner; // 0: Empty, 1: Host, 2: Challenger, 3: Draw
    uint8[3][3] public game; // Game board
    uint256 public turns; // Number of turns played

    // Constants
    uint8 constant EMPTY = 0;
    uint8 constant HOST = 1;
    uint8 constant CHALLENGER = 2;
    uint8 constant DRAW = 3;

    // Events
    event GameStarted(address indexed host, uint8 column, uint8 row);
    event ChallengerJoined(address indexed challenger, uint8 column, uint8 row);
    event MoveMade(address indexed player, uint8 column, uint8 row);
    event GameWon(address indexed winner);
    event GameDrawn();

    // Start a new game
    function newGame(uint8 column, uint8 row) external {
        require(column < 3 && row < 3, "Move must be in range");

        // Ensure any ongoing game is completed
        if (challenger != address(0)) {
            require(winner != 0, "Game isn't over");
        }

        // Reset game state
        challenger = address(0);
        winner = 0;
        turns = 0;
        host = msg.sender;

        // Clear the board
        for (uint8 i = 0; i < 3; i++) {
            for (uint8 j = 0; j < 3; j++) {
                game[i][j] = EMPTY;
            }
        }

        // Make the first move as the host
        game[row][column] = HOST;
        turns++;

        emit GameStarted(host, column, row);
    }

    // Join the game as a challenger
    function joinGame(uint8 column, uint8 row) external {
        require(challenger == address(0), "Host already has a challenger");
        require(column < 3 && row < 3, "Move must be in range");

        challenger = msg.sender;
        makeMove(CHALLENGER, column, row);

        emit ChallengerJoined(challenger, column, row);
    }

    // Get whose turn it is
    function whoseTurn() public view returns (uint8) {
        return turns % 2 == 1 ? HOST : CHALLENGER;
    }

    // Play a move
    function play(uint8 column, uint8 row) external {
        require(winner == 0, "Game is already finished");
        require(column < 3 && row < 3, "Move must be in range");

        uint8 player;
        if (turns % 2 == 1) {
            require(msg.sender == host, "It is the host's turn");
            player = HOST;
        } else {
            require(msg.sender == challenger, "It is the challenger's turn");
            player = CHALLENGER;
        }

        makeMove(player, column, row);

        emit MoveMade(msg.sender, column, row);
    }

    // Internal function to make a move
    function makeMove(uint8 player, uint8 column, uint8 row) internal {
        require(game[row][column] == EMPTY, "Square is already taken");

        game[row][column] = player;
        turns++;

        // Check for winner or draw
        if (didWin(player, column, row)) {
            winner = player;
            emit GameWon(player == HOST ? host : challenger);
        } else if (turns == 9) {
            winner = DRAW;
            emit GameDrawn();
        }
    }

    // Internal function to check if a player has won
    function didWin(uint8 player, uint8 column, uint8 row) internal view returns (bool) {
        // Check the row
        if (game[row][0] == player && game[row][1] == player && game[row][2] == player) {
            return true;
        }

        // Check the column
        if (game[0][column] == player && game[1][column] == player && game[2][column] == player) {
            return true;
        }

        // Check diagonals if the player owns the center
        if (game[1][1] == player) {
            if (game[0][0] == player && game[2][2] == player) {
                return true;
            }
            if (game[0][2] == player && game[2][0] == player) {
                return true;
            }
        }

        return false;
    }
}
