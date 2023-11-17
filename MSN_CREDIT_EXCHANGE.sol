// SPDX-License-Identifier: GPL v3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MSN_CREDIT_EXCHANGE {
    address public msn_contract_address;
    uint256 public exchange_ratio; // exchanged msn credit amount = (msn amount) * exchange_ratio

    address public contract_owner;
    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "Only contractOwner");
        _;
    }

    mapping(address => uint256) private address_msn_credit_map; // address => msn credit amount

    function msn_credit_balance_of(address addr) public view returns (uint256) {
        return address_msn_credit_map[addr];
    }

    mapping(address => uint256) private address_tx_counter_map; // address => accumulated exchange times

    function tx_counter_of(address addr) public view returns (uint256) {
        return address_tx_counter_map[addr];
    }

    constructor(address _msn_contract_addr) {
        msn_contract_address = _msn_contract_addr;
        contract_owner = msg.sender;
        exchange_ratio = 1;
    }

    function set_exchange_ratio(uint256 _new_ratio) external onlyContractOwner {
        require(_new_ratio > 0, "exchange ratio shoud be bigger then 0");
        exchange_ratio = _new_ratio;
    }

    function exchange(uint256 amount) public {
        require(amount > 0, "exchange amount should be bigger then 0");

        //transfer
        bool result = IERC20(msn_contract_address).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(result == true, "transfer error");

        uint256 msn_credit = amount * exchange_ratio;

        address_msn_credit_map[msg.sender] =
            address_msn_credit_map[msg.sender] +
            msn_credit;

        address_tx_counter_map[msg.sender] =
            address_tx_counter_map[msg.sender] +
            1;
    }
}
