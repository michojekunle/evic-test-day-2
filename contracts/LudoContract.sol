// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";

/**
 * @title LudoContract
 * @notice A decentralized Ludo game with pellet movement, collisions, and randomness provided by Chainlink VRF.
 */
contract LudoContract is VRFConsumerBase {
    uint8 constant TOTAL_BOARD_SPACES = 52;
    uint8 constant MAX_PLAYERS = 4;
    uint8 constant TOTAL_PELLETS = 4;
    uint256 public turnTimeout = 5 minutes;

    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => address) public requestIdToPlayer;

    struct Player {
        address playerAddress;
        uint8[4] pelletPositions;
        bool hasFinished;
        uint color;
    }

    address[] public playersArray;
    mapping(address => Player) public players;
    uint public currentTurnIndex;
    bool public gameStarted;
    bool public gameEnded;
    uint256 public lastMoveTime;

    /// Events
    event PlayerRegistered(address indexed player);
    event GameStarted();
    event DiceRolled(address indexed player, uint8 result);
    event PelletMoved(
        address indexed player,
        uint8 pelletIndex,
        uint8 newPosition
    );
    event CollisionOccurred(
        address indexed player,
        address victim,
        uint8 pelletIndex
    );
    event GameWon(address indexed winner);
    event GameTerminated(address indexed terminator);

    // Custom Errors
    error NotAPlayer();
    error GameNotStarted();
    error GameAlreadyEnded();
    error NotYourTurn();
    error InvalidPelletIndex();
    error InvalidMove();
    error PelletCollision();
    error TurnTimedOut();

    constructor(
        address _vrfCoordinator,
        address _link
    ) VRFConsumerBase(_vrfCoordinator, _link) {}

    /**
     * @notice Registers a new player for the game.
     * @dev Can only register up to MAX_PLAYERS.
     * Emits a PlayerRegistered event.
     */
    function registerPlayer() external {
        require(
            playersArray.length < MAX_PLAYERS,
            "Maximum players for ludo game reached"
        );
        _onlyPlayer();

        Player memory newPlayer;
        newPlayer.playerAddress = msg.sender;
        newPlayer.pelletPositions = [0, 0, 0, 0];
        newPlayer.hasFinished = false;

        players[msg.sender] = newPlayer;
        playersArray.push(msg.sender);

        emit PlayerRegistered(msg.sender);

        if (playersArray.length == MAX_PLAYERS) {
            gameStarted = true;
            emit GameStarted();
            lastMoveTime = block.timestamp;
        }
    }

    /**
     * @notice Rolls the dice using Chainlink VRF to generate randomness.
     * @dev Only the player whose turn it is can call this function.
     * @return requestId The request ID for Chainlink VRF randomness.
     */
    function rollDice() external returns (bytes32 requestId) {
        _onlyPlayer();
        _gameStarted();
        _currentTurn();

        require(
            block.timestamp <= lastMoveTime + turnTimeout,
            "Turn timeout, move to next player"
        );
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK to pay fee"
        );

        requestId = requestRandomness(keyHash, fee);
        requestIdToPlayer[requestId] = msg.sender;
    }

    /**
     * @notice Moves a player's pellet by a number of steps.
     * @dev Handles pellet movement, collisions, and checks for valid moves.
     * @param pelletIndex The index of the pellet to move (0-3).
     * @param steps The number of steps to move the pellet.
     */
    function movePellet(uint8 pelletIndex, uint8 steps) external {
        _onlyPlayer();
        _gameStarted();
        _currentTurn();

        if (pelletIndex >= TOTAL_PELLETS) revert InvalidPelletIndex();

        Player storage player = players[msg.sender];
        uint8 currentPos = player.pelletPositions[pelletIndex];

        if (currentPos == 0 && steps != 6) revert InvalidMove(); // Can only move out on a roll of 6

        uint8 newPosition = currentPos + steps;
        if (newPosition > TOTAL_BOARD_SPACES) revert InvalidMove(); // Cannot move beyond board

        // Check for pellet collision and handle displacement
        address collisionVictim = checkCollision(newPosition);
        if (collisionVictim != address(0)) {
            _handleCollision(msg.sender, pelletIndex, collisionVictim);
        } else {
            player.pelletPositions[pelletIndex] = newPosition;
            emit PelletMoved(msg.sender, pelletIndex, newPosition);
        }

        if (checkPlayerWon(msg.sender)) {
            gameEnded = true;
            emit GameWon(msg.sender);
        }

        _nextTurn();
    }

    // Callback function for Chainlink VRF randomness
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        address player = requestIdToPlayer[requestId];
        uint8 diceResult = uint8((randomness % 6) + 1); // Dice result 1 to 6
        emit DiceRolled(player, diceResult);
    }

    /**
     * @notice Checks if there is a pellet collision at the new position.
     * @param newPosition The position to check for a collision.
     * @return The address of the player whose pellet was collided with, or address(0) if no collision.
     */
    function checkCollision(uint8 newPosition) internal view returns (address) {
        for (uint i = 0; i < playersArray.length; i++) {
            Player storage player = players[playersArray[i]];
            for (uint j = 0; j < TOTAL_PELLETS; j++) {
                if (player.pelletPositions[j] == newPosition) {
                    return playersArray[i];
                }
            }
        }
        return address(0);
    }

    /**
     * @notice Handles the displacement of a victim pellet in a collision, moving the displacing pellet to the final board position.
     * @param displacer The address of the player whose pellet caused the displacement.
     * @param pelletIndex The index of the displacer pellet.
     * @param victim The address of the player whose pellet was displaced.
     */
    function _handleCollision(
        address displacer,
        uint8 pelletIndex,
        address victim
    ) internal {
        Player storage victimPlayer = players[victim];
        Player storage displacerPlayer = players[displacer];

        for (uint8 i = 0; i < TOTAL_PELLETS; i++) {
            if (
                victimPlayer.pelletPositions[i] ==
                displacerPlayer.pelletPositions[pelletIndex]
            ) {
                victimPlayer.pelletPositions[i] = 0; // Return victim to start
                emit CollisionOccurred(displacer, victim, i);
                break;
            }
        }

        displacerPlayer.pelletPositions[pelletIndex] = TOTAL_BOARD_SPACES; // Move displacer to final space
        emit PelletMoved(displacer, pelletIndex, TOTAL_BOARD_SPACES);
    }

    /**
     * @notice Checks if a player has won the game by moving all their pellets to the final space.
     * @param playerAddress The address of the player to check.
     * @return True if the player has won, false otherwise.
     */
    function checkPlayerWon(
        address playerAddress
    ) internal view returns (bool) {
        Player memory player = players[playerAddress];
        for (uint i = 0; i < TOTAL_PELLETS; i++) {
            if (player.pelletPositions[i] < TOTAL_BOARD_SPACES) {
                return false;
            }
        }
        return true;
    }

    // Private helper functions for access control, game states, and turn management
    function _onlyPlayer() private view {
        if (!isPlayer(msg.sender)) revert NotAPlayer();
    }

    function _gameStarted() private view {
        if (!gameStarted) revert GameNotStarted();
    }

    function _currentTurn() private view {
        if (playersArray[currentTurnIndex] != msg.sender) revert NotYourTurn();
    }

    function _nextTurn() private {
        currentTurnIndex = (currentTurnIndex + 1) % playersArray.length;
        lastMoveTime = block.timestamp;
    }

    function isPlayer(address _player) internal view returns (bool) {
        for (uint i = 0; i < playersArray.length; i++) {
            if (playersArray[i] == _player) {
                return true;
            }
        }
        return false;
    }
}
