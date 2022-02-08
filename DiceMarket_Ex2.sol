pragma solidity ^0.5.0;
import "./Dice.sol";
import "./DiceToken.sol";

contract DiceMarket {
    Dice diceContract;
    DiceToken DT;
    uint256 public comissionFee;
    address _owner = msg.sender;
    mapping (uint256 => uint256) listPrice;

    constructor(Dice diceAddress, uint256 fee) public {
        diceContract = diceAddress;
        comissionFee = fee;
    }

    // listing a die for sale. price needs to be >= value + fee
    function list(uint256 id, uint256 price) public {
        require(msg.sender==diceContract.getPrevOwner(id));
        listPrice[id] = price;
    }

    function delist(uint256 id) public {
        require(msg.sender==diceContract.getPrevOwner(id));
        listPrice[id] = 0;
    }

    function checkPrice(uint256 id) public view returns (uint256) {
        return listPrice[id];
    }

    function buy(uint256 id) public payable {
        // require(DT.approveBuy(msg.sender,msg.value),"Only DT is accepted");
        require(listPrice[id] != 0);
        require(msg.value >= (listPrice[id] + comissionFee));
        // address payable recipient = address(uint160(diceContract.getPrevOwner(id)));  
        // address payable owner = address(uint160(getContractOwner()));
        DT.transferERC20(diceContract.getPrevOwner(id),checkPrice(id));
        DT.transferERC20(getContractOwner(),comissionFee);
        diceContract.transfer(id,msg.sender); // sending NFT
        // DT.transferERC20(msg.sender,msg.value - checkPrice(id) - comissionFee); // change
        
    }

    function getContractOwner() public view returns(address) {
        return _owner;
    }

    function withdraw() public {
        if(msg.sender == _owner) 
            msg.sender.transfer(address(this).balance);
    }
}