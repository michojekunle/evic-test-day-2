// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract LudoContract {
    uint constant TOTAL_BOARD_SPACES = 52;
    uint constant MAX_PLAYERS = 4;
    uint constant TOTAL_TOKENS = 4;

    struct Player {
        address playerAddress;
        uint8[4] tokenPositions;
        bool hasFinished;
        uint color;
    }

    address[] public playersArray;
    mapping(address => Player) public players;
    uint public currentTurnIndex;
    bool public gameStarted;
    bool public gameEnded;

    function _onlyPlayer() private view {
        require(isPlayer(msg.sender), "You are not a player in this game");
    }

    function _gameStarted() private view {
        require(gameStarted, "The game has not started yet");
    }

    function _gameNotEnded() private view {
        require(!gameEnded, "The game has already ended");
    }

    function _currentTurn() private view {
        require(
            playersArray[currentTurnIndex] == msg.sender,
            "It's not your turn"
        );
    }

    // Check if the msg.sender has registered as a player
    function isPlayer(address _player) internal view returns (bool) {
        for (uint i = 0; i < playersArray.length; i++) {
            if (playersArray[i] == _player) {
                return true;
            }
        }
        return false;
    }

    // Register Player
    function registerPlayer() external {
        require(
            playersArray.length < MAX_PLAYERS,
            "Maximum players for ludo game reached"
        );
        require(!isPlayer(msg.sender), "Player already registered for game");

        Player memory newPlayer;
        newPlayer.playerAddress = msg.sender;
        newPlayer.tokenPositions = [0, 0, 0, 0];
        newPlayer.hasFinished = false;

        players[msg.sender] = newPlayer;
        playersArray.push(msg.sender);

        // Start the game if max-players are reached
        if (playersArray.length == MAX_PLAYERS) {
            gameStarted = true;
        }
    }

    // Dice rolling function (simulates a 6-sided dice roll)
    function rollDice() external view returns (uint) {
        _gameStarted();
        _currentTurn();
        _onlyPlayer();
        uint diceResult = (uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 6) + 1;
        return diceResult;
    }

    // Check if a player has won by moving all tokens to the end
    function _checkPlayerWon(
        address playerAddress
    ) internal view returns (bool) {
        Player memory player = players[playerAddress];
        for (uint i = 0; i < TOTAL_TOKENS; i++) {
            if (player.tokenPositions[i] < TOTAL_BOARD_SPACES) {
                return false;
            }
        }
        return true;
    }

    // Rotate turns between players
    function _nextTurn() internal {
        currentTurnIndex = (currentTurnIndex + 1) % playersArray.length;
    }

    // Function to get the current player's address
    function getCurrentPlayer() external view returns (address) {
        return playersArray[currentTurnIndex];
    }
}
