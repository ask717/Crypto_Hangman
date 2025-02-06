// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Hangman {
    string[50] private wordDict = [
        "apple pie", "happy cat", "big bear", "rainbow sky", "magic hat", "sunny day",
        "tiny house", "lemon tea", "puppy love", "wild west", "orange moon", "silver star",
        "laughing owl", "forest path", "flying fish", "cotton cloud", "cherry tree",
        "secret key", "brave knight", "blue ocean", "twinkling light", "snowy night",
        "giant turtle", "fairy tale", "hidden treasure", "silent river", "cuddly bunny",
        "dancing dolphin", "frozen lake", "chocolate cake", "friendly ghost", "golden ring",
        "peaceful garden", "whispering wind", "shiny penny", "mountain peak", "calm waters",
        "bright sun", "sleepy fox", "starry sky", "tiny flower", "gentle breeze", "rainbow fish",
        "singing bird", "bold tiger", "spinning wheel", "shadow puppet", "green valley",
        "fluttering butterfly", "secret cave"
    ];

    string private currWord;
    string private hangmanWord;
    uint private attemptsLeft;
    bool private gameActive;
    uint256 private gameStartTime;
    uint256 private constant gameDuration = 2 minutes;

    mapping(bytes1 => bool) private wrongGuesses;

    string[8] private hangmanStages = [
        unicode" |-", unicode" |-o", unicode" |-o-", unicode" |-o--",
        unicode" |-o<", unicode" |-o<--", unicode" |-o<-<", unicode" |-o<--<"
    ];

    event GuessMade(string hangmanWord, uint attemptsLeft, string wrongGuesses, string hangmanFigure);
    event GameStarted(uint256 startTime, uint256 duration);
    event GameTimeLeft(string reason);
    event GameEnded(string reason);

    function startGame() public {
    require(!gameActive, "Game already in progress. End it first.");
    
    // Reset game state
    gameActive = true;
    gameStartTime = block.timestamp; // Reset start time when starting new game
    attemptsLeft = 7;

    emit GameStarted(gameStartTime, gameDuration);

    uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % wordDict.length;
    currWord = wordDict[randomIndex];

    bytes memory wordBytes = bytes(currWord);
    bytes memory hangmanBytes = new bytes(wordBytes.length * 2);

    // Reset wrong guesses
    for (uint8 i = 97; i <= 122; i++) {
        wrongGuesses[bytes1(i)] = false;
    }

    for (uint i = 0; i < wordBytes.length; i++) {
        if (wordBytes[i] == " ") {
            hangmanBytes[i * 2] = "|";
            hangmanBytes[i * 2 + 1] = "|";
        } else {
            hangmanBytes[i * 2] = "_";
            hangmanBytes[i * 2 + 1] = " ";
        }
    }
    hangmanWord = string(hangmanBytes);
}



    function getGameState() public view returns (string memory, uint, string memory, string memory) {
        require(gameActive, "No active game.");
        return (hangmanWord, attemptsLeft, getWrongGuesses(), getHangmanFigure());
    }

    function guess(string memory input) public returns (string memory, uint, string memory, string memory) {
        require(gameActive, "Game has ended.");
        require(bytes(input).length == 1, "Input must be a single character.");

        if (block.timestamp > gameStartTime + gameDuration) {
            gameActive = false;
            emit GameTimeLeft("Time limit reached.");
            emit GameEnded("Game over. You didn't finish in time.");
            return (hangmanWord, attemptsLeft, getWrongGuesses(), getHangmanFigure());
        }

        bytes1 guessedLetter = toLowerCase(bytes(input)[0]);
        bool correctGuess = false;
        bytes memory hangmanBytes = bytes(hangmanWord);
        bytes memory wordBytes = bytes(currWord);

        for (uint i = 0; i < wordBytes.length; i++) {
            if (toLowerCase(wordBytes[i]) == guessedLetter) {
                hangmanBytes[i * 2] = wordBytes[i];
                correctGuess = true;
            }
        }

        hangmanWord = string(hangmanBytes);

        if (!correctGuess) {
            if (!wrongGuesses[guessedLetter]) {
                wrongGuesses[guessedLetter] = true;
                attemptsLeft--;

                if (attemptsLeft == 0) {
                    gameActive = false;
                    emit GameEnded("Game over. No attempts left.");
                }
            }
        }

        emit GuessMade(hangmanWord, attemptsLeft, getWrongGuesses(), getHangmanFigure());
        return (hangmanWord, attemptsLeft, getWrongGuesses(), getHangmanFigure());
    }

    function getWrongGuesses() internal view returns (string memory) {
        bytes memory guessedChars;

        for (uint8 i = 97; i <= 122; i++) {
            if (wrongGuesses[bytes1(i)]) {
                guessedChars = abi.encodePacked(guessedChars, bytes1(i), " ");
            }
        }

        return string(abi.encodePacked("Wrong guesses: ", string(guessedChars)));
    }

    function getHangmanFigure() internal view returns (string memory) {
        return string(abi.encodePacked("Hangman: ", hangmanStages[7 - attemptsLeft]));
    }

    function displayTimeLeft() public view returns (string memory) {
        require(gameActive, "No active game.");
        uint256 timeLeft = gameStartTime + gameDuration > block.timestamp ? gameStartTime + gameDuration - block.timestamp : 0;
        return string(abi.encodePacked("You have ", uintToString(timeLeft), " seconds left"));
    }

    function quit() public {
    require(gameActive, "No active game to end.");
    gameActive = false;
    gameStartTime = 0; // Reset time
    emit GameEnded("Game over. You quit.");
}


    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

    function toLowerCase(bytes1 char) internal pure returns (bytes1) {
        if (char >= 0x41 && char <= 0x5A) {
            return bytes1(uint8(char) + 32);
        }
        return char;
    }
}
