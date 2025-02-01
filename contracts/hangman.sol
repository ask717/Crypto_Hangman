// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

contract Hangman {  //dictionary of words
    string [50] wordDict = [
    "apple pie", "happy cat", "big bear", "rainbow sky", "magic hat", "sunny day",
    "tiny house", "lemon tea", "puppy love", "wild west", "orange moon", "silver star",
    "laughing owl", "forest path", "flying fish", "cotton cloud", "cherry tree",
    "secret key", "brave knight", "blue ocean", "twinkling light", "snowy night",
    "giant turtle", "fairy tale", "hidden treasure", "silent river", "cuddly bunny",
    "dancing dolphin", "frozen lake", "chocolate cake", "friendly ghost", "golden ring",
    "peaceful garden", "whispering wind", "shiny penny", "mountain peak", "calm waters",
    "bright sun", "sleepy fox", "starry sky", "tiny flower", "gentle breeze", "rainbow fish",
    "singing bird", "bold tiger", "spinning wheel", "shadow puppet", "green valley",
    "fluttering butterfly", "secret cave"];

    string[8] hangman = [  //string to hold the hangman images
    "   ____\n   |    |\n   |\n   |\n   |\n   |\n  / \\\n",
    "   ____\n   |    |\n   |    O\n   |\n   |\n   |\n  / \\\n",
    "   ____\n   |    |\n   |    O\n   |    |\n   |\n   |\n  / \\\n",
    "   ____\n   |    |\n   |    O\n   |   \\|/\n   |\n   |\n  / \\\n",
    "   ____\n   |    |\n   |    O\n   |   \\|/\n   |    |\n   |\n  / \\\n",
    "   ____\n   |    |\n   |    O\n   |   \\|/\n   |    |\n   |\n  / \\\n",
    "   ____\n   |    |\n   |    O\n   |   \\|/\n   |    |\n   |   /\n  / \\\n",
    "   ____\n   |    |\n   |    O\n   |   \\|/\n   |    |\n   |   / \\\n  / \\\n"];

    
    string currWord;      // The word to guess
    string hangmanWord;   // Word with underscores
    uint attemptsLeft;    //total attempts available=7 
    string wrongGuesses;  //stores wrong letters guesess
    bool  gameActive;     //True when game is ON
    uint256  gameStartTime; 
    uint256  gameDuration = 1 minutes;
    //string[] wrongGuessesArray; 

    // Event to emit guess result
    event GuessMade(string hangmanWord, uint attemptsLeft, string wrongGuesses);
    event GameStarted(uint256 startTime, uint256 duration);
    event GameTimeLeft(string reason);
    event GameEnded();

    function startGame() public {

        require(!gameActive, "Game already in progress. End it first.");
        
        gameActive = true;

        gameStartTime = block.timestamp; // Store game start time
        emit GameStarted(gameStartTime, gameDuration);


        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % wordDict.length;
        currWord = wordDict[randomIndex];

        bytes memory wordBytes = bytes(currWord); 
        bytes memory hangmanBytes = new bytes(wordBytes.length * 2);


        wrongGuesses = ""; 
        attemptsLeft = 7;

        //display hangman word with underscores
        for(uint i=0; i < bytes(currWord).length ;i++){
           if(bytes(currWord)[i]==" "){
                hangmanBytes[i * 2] = "|";
                hangmanBytes[i * 2 + 1] = "|";
           }else{
                hangmanBytes[i * 2] = "_";
                hangmanBytes[i * 2 +1] = " ";
           }
        }
        hangmanWord = string(hangmanBytes);
    }

    // Get the current state of the game...
    function getGameState() public view returns (string memory, uint, string memory) {
        return (hangmanWord, attemptsLeft, wrongGuesses);
    }

    function contains(string memory haystack, string memory needle) internal pure returns (bool) {
        bytes memory haystackBytes = bytes(haystack);
        bytes memory needleBytes = bytes(needle);

        if (needleBytes.length == 0 || haystackBytes.length < needleBytes.length) {
            return false;
        }

        for (uint i = 0; i <= haystackBytes.length - needleBytes.length; i++) {
            bool matchFound = true;
            for (uint j = 0; j < needleBytes.length; j++) {
                if (haystackBytes[i + j] != needleBytes[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) {
                return true;
            }
        }
        return false;
    }
    // Function to compare the guesses...
    function guess(string memory input) public returns (string memory, uint, string memory) {
        bytes memory inputBytes = bytes(input);
        require(inputBytes.length == 1, "Input must be a single character");

        bool correctGuess = false;
        bytes memory hangmanBytes = bytes(hangmanWord);

        for (uint i = 0; i < bytes(currWord).length; i++) {
            if (bytes(currWord)[i] == bytes(input)[0]) {
                hangmanBytes[i * 2] = bytes(input)[0];
                correctGuess = true;
            }
        }

        hangmanWord = string(hangmanBytes);

        if (!correctGuess) {
            //wrongGuessesArray.push(input);
            if (!contains(wrongGuesses, input)) {
            // Append the new wrong guess with a space
                wrongGuesses = string(abi.encodePacked(wrongGuesses, input, " "));
            }
            //wrongGuesses = string(abi.encodePacked(wrongGuesses, input, " "));
            attemptsLeft--;

            if (attemptsLeft == 0) {
                revert("Game Over: No attempts left.");  // End the game
            }
        }

        emit GuessMade(hangmanWord, attemptsLeft, wrongGuesses);

        return (hangmanWord, attemptsLeft, wrongGuesses);
    }


    function getHangmanFigure() public view returns (string memory) {
    return hangman[7-attemptsLeft];
}





    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

    function checkGameTimeout() public {
        require(gameActive, "No active game to end.");
        if ( block.timestamp > gameStartTime + gameDuration) {
            emit GameTimeLeft("Time limit reached.");
            gameActive = false;
            emit GameEnded();
        }else{
            uint256 timeLeft = gameStartTime + gameDuration - block.timestamp;
            emit GameTimeLeft(string(abi.encodePacked("You have ",uintToString(timeLeft)," seconds left")));
        }
    }

    function quit() public {
        require(gameActive, "No active game to end.");
        
        gameActive = false;
        emit GameEnded();
    }
}