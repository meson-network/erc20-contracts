// SPDX-License-Identifier: GPL v3
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/token/ERC20/IERC20.sol";

contract MSN_STAKE {
    address public msn_contract_address;

    constructor(address _msn_contract_addr) {
        msn_contract_address = _msn_contract_addr;
    }

    uint256 private total_credit;

    function get_total_credit() external view returns (uint256) {
        return total_credit;
    }

    mapping(address => uint256) private credit_map;

    function get_credit(address addr) external view returns (uint256) {
        return credit_map[addr];
    }

    mapping(address => uint256) private stake_token_map;

    function get_stake_token(address addr) external view returns (uint256) {
        return stake_token_map[addr];
    }

    mapping(address => uint256) private stake_last_time_map;

    function get_stake_last_time(address addr) external view returns (uint256) {
        return stake_last_time_map[addr];
    }

    function cal_credit_reward(address addr) public view returns (uint256) {
        return (stake_token_map[addr] *(block.timestamp - stake_last_time_map[msg.sender])) / 1000;
    }

    function get_total_credit_prediction(address addr) external view returns (uint256) {
        return cal_credit_reward(addr) + credit_map[msg.sender];
    }

    function harvest() public {
        uint256 credit_reward = cal_credit_reward(msg.sender);
        require(credit_reward >= 0, "credit_reward smaller then 0 err in harvest");
        stake_last_time_map[msg.sender] = block.timestamp;
        credit_map[msg.sender] = credit_map[msg.sender] + credit_reward;
        total_credit += credit_reward;
        require(total_credit >= 0, "total_credit overflow err");
    }

    event stake_EVENT(address trigger_user_addr, uint256 amount);

    function stake(uint256 amount) external {
        require(amount > 0, "stake amount must bigger then 0");

        uint256 allowance = IERC20(msn_contract_address).allowance(msg.sender, address(this));

        require(allowance > 0, "please approve tokens before staking");
        require(allowance >= amount, "please approve more tokens");

        harvest();

        bool t_result = IERC20(msn_contract_address).transferFrom(msg.sender, address(this), amount);
        require(t_result == true, "transfer error");

        stake_token_map[msg.sender] += amount;

        emit stake_EVENT(msg.sender, amount);
    }

    event unstake_EVENT(address trigger_user_addr, uint256 amount);

    function unstake(uint256 amount) external {
        require(stake_token_map[msg.sender] >= amount, "not enough balance");

        harvest();

        stake_token_map[msg.sender] -= amount;

        //transfer
        bool result = IERC20(msn_contract_address).transfer(msg.sender, amount);
        require(result == true, "transfer error");

        emit unstake_EVENT(msg.sender, amount);
    }
}
