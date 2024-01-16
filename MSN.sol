// SPDX-License-Identifier: GPL v3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {
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
        _mint(msg.sender, ini_supply * (10 ** uint256(decimals())));
    }

    //mint and burn functions for cross-chain token amount balancing
    //sum(tokens on all chains) == 100% tokens amount  
    //token price on each chain is equal

    event Mint_log(address addr, uint256 amount, string log);

    function mint(uint256 amount, string memory log) public onlyContractOwner {
        _mint(msg.sender, amount);
        emit Mint_log(msg.sender, amount, log);
    }

    event Burn_log(address addr, uint256 amount, string log);

    function burn(uint256 amount, string memory log) public {
        _burn(msg.sender, amount);
        emit Burn_log(msg.sender, amount, log);
    }
}
