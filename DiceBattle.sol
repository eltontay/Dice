pragma solidity ^0.5.0;
import "./Dice.sol";

/*
1. First create dice using the Dice contract
2. Transfer both die to this contract using the contract's address
3. Use setBattlePair from each player's account to decide enemy
4. Use the battle function to roll, stop rolling and then compare the numbers
5. The player with the higher number gets BOTH dice
6. If there is a tie, return the dice to their previous owner
*/


contract DiceBattle {
    Dice diceContract;
    mapping(address => address) battle_pair;
    address _DiceBattleOwner = msg.sender;

    enum battleState { noBattle, awaitingBattle, battleStart }
    battleState state = battleState.noBattle;

    event diceWon (uint256 diceId);
    event diceDraw ();

    constructor(Dice diceAddress) public {
        diceContract = diceAddress; 
    }

    function setBattlePair(address enemy) public {
        // Require that only prev owner can allow an enemy
        // Each player can only select one enemy
        require(battle_pair[msg.sender] == address(0), "You can only select one enemy");
        battle_pair[msg.sender] = enemy;
        battle_pair[enemy] = msg.sender;
    }

    function battle(uint256 myDice, uint256 enemyDice) public payable {
        require(myDice != enemyDice, "Please choose two distinctive dice");
        // Require that battle_pairs align, ie each player has accepted a battle with the other

        // noBattle means you are the first to initialise battle function
        if (msg.sender == diceContract.getPrevOwner(myDice) && state == battleState.noBattle) {
            state = battleState.awaitingBattle;
            setBattlePair(diceContract.getPrevOwner(enemyDice));
        } 
        // check if battlepair already has the pair to change state to start battle
        else if (msg.sender == diceContract.getPrevOwner(myDice) && state == battleState.awaitingBattle) {
            // low-level assumption that only two dice can be in this contract at any one time
            state = battleState.battleStart;
        }

        // run battle
        
        if (state == battleState.battleStart) {
            diceContract.roll(myDice);
            diceContract.roll(enemyDice);
            diceContract.stopRoll(myDice);
            diceContract.stopRoll(enemyDice);
            uint256 myNumber = diceContract.getDiceNumber(myDice);
            uint256 enemyNumber = diceContract.getDiceNumber(enemyDice);
            if (myNumber > enemyNumber) {
                diceContract.transfer(enemyDice,battle_pair[diceContract.getPrevOwner(enemyDice)]);
                diceContract.transfer(myDice,battle_pair[diceContract.getPrevOwner(enemyDice)]);
                emit diceWon(myDice);
            } else if (myNumber < enemyNumber) {
                diceContract.transfer(myDice,battle_pair[diceContract.getPrevOwner(myDice)]);
                diceContract.transfer(enemyDice,battle_pair[diceContract.getPrevOwner(myDice)]);
                emit diceWon(enemyDice);
            } else {
                diceContract.transfer(myDice,battle_pair[diceContract.getPrevOwner(enemyDice)]);
                diceContract.transfer(enemyDice,battle_pair[diceContract.getPrevOwner(myDice)]);
                emit diceDraw();
            }
        }




    }
    
    //Add relevant getters and setters

    function getBattleState() public view returns (battleState) {
        return state;
    }

    // function getBattleAddress() public view returns (address) {
    //     return diceContract.owner;
    // }
}