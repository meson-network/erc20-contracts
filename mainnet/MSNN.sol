// SPDX-License-Identifier: GPL v3
// README: https://github.com/daqnext/msn_contracts/blob/main/assets/koa_static/contracts/v2/MSN.md

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {

    uint256 public payable_eth;
     
    address private contract_owner;
    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "Only contractOwner");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 inisupply
    ) ERC20(name, symbol) {
        contract_owner = msg.sender;
        _mint(msg.sender, inisupply * (10**uint256(decimals())));
    }

     
    // mint is open for mining inflation increment
    event mint_EVENT(
        address trigger_user_addr,
        uint256 amount,
        uint256 blocktime
    );

    function mint(uint256 amount) public onlyContractOwner {
        _mint(msg.sender, amount);
        emit mint_EVENT(msg.sender, amount, block.timestamp);
    }

    // anyone can burn their own token
    event burn_EVENT(
        address trigger_user_addr,
        uint256 amount,
        uint256 blocktime
    );

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit burn_EVENT(msg.sender, amount, block.timestamp);
    }

    
    receive() external payable {
        payable_eth += msg.value;
    }

    fallback() external payable {
        payable_eth += msg.value;
    }

    event withdraw_eth_EVENT(
        address trigger_user_addr,
        uint256 _amount,
        uint256 blocktime
    );

    function withdraw_eth() external onlyContractOwner {
        uint256 amout_to_t = address(this).balance;
        payable(msg.sender).transfer(amout_to_t);
        payable_eth = 0;
        emit withdraw_eth_EVENT(msg.sender, amout_to_t, block.timestamp);
    }

    event withdraw_contract_EVENT(
        address trigger_user_addr,
        address _from,
        uint256 amount,
        uint256 blocktime
    );

    function withdraw_contract() public onlyContractOwner {
        uint256 left = balanceOf(address(this));
        require(left > 0, "No balance");
        _transfer(address(this), msg.sender, left);
        emit withdraw_contract_EVENT(
            msg.sender,
            address(this),
            left,
            block.timestamp
        );
    }
}
