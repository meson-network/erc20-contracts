// SPDX-License-Identifier: GPL v3
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract MSN is ERC20, ERC20Capped {
    address public contract_owner;
    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "Only contractOwner");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 ini_supply,
        uint256 cap
    ) ERC20(name, symbol) ERC20Capped(cap * (10 ** uint256(decimals()))) {
        contract_owner = msg.sender;
        _mint(msg.sender, ini_supply * (10 ** uint256(decimals())));
    }

    //mint and burn functions for cross-chain token amount balancing and mining token inflation
    //sum(tokens on all chains) == 100% tokens amount
    //token price on each chain is equal

    event Mint_log(address addr, uint256 amount, string log);

    function mint(uint256 amount, string memory log) public onlyContractOwner {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(msg.sender, amount);
        emit Mint_log(msg.sender, amount, log);
    }

    event Burn_log(address addr, uint256 amount, string log);

    function burn(uint256 amount, string memory log) public {
        _burn(msg.sender, amount);
        emit Burn_log(msg.sender, amount, log);
    }
}
