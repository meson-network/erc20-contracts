// SPDX-License-Identifier: GPL v3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {
    uint256 public initial_supply;
    uint256 public mining_mint_limit; // maximal mining amount
    uint256 public mining_minted_amount; // sum of all past mining amount

    address public contract_owner;
    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "Only contractOwner");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 ini_supply
    ) ERC20(name, symbol) {
        contract_owner = msg.sender;
        initial_supply = ini_supply * (10**uint256(decimals()));
        mining_minted_amount = 0;
        mining_mint_limit = (initial_supply * 275) / 1000; //in 10 years total inflation for mining is 27.5%
        _mint(msg.sender, initial_supply);
    }

    function mint_for_mining(uint256 amount) public onlyContractOwner {
        //
        uint256 after_add = mining_minted_amount + amount;
        assert(after_add > mining_minted_amount); //safe math check

        require(after_add <= mining_mint_limit, "mint exceeds mining limit");
        mining_minted_amount = after_add;
        _mint(msg.sender, amount);
    }
}
