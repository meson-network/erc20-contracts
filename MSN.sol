// SPDX-License-Identifier: GPL v3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {
    address public contract_owner;
    uint256 public ini_supply;
    uint256 public ini_timestamp;

    //how many tokens have been minted by all the miners
    uint256 public miner_total_mint;
    uint256[10] public miner_mint_years_limit = [
        50,
        95,
        135,
        170,
        200,
        225,
        245,
        260,
        270,
        275
    ];
    // mining_mint_sig_id => amount
    mapping(uint256 => uint256) public mining_minted_map;

    // how many tokens can be mint for today
    function mining_mint_limit() public view returns (uint256) {
        uint256 past_years_num = past_years();
        uint256 past_days_num = past_days();

        uint256 past_years_mint_limit = 0;
        if (past_years_num == 0) {
            //nothing keeps 0
        } else {
            past_years_mint_limit = miner_mint_years_limit[past_years_num];
        }

        uint256 mint_ratio_this_year = 0;
        if (past_years_num == 0) {
            mint_ratio_this_year = miner_mint_years_limit[past_years_num];
        } else if (past_years_num < 9) {
            mint_ratio_this_year =miner_mint_years_limit[past_years_num + 1] - miner_mint_years_limit[past_years_num];
        } else {
            //nothing keeps 0
        }

        return past_years_mint_limit + mint_ratio_this_year * (past_days_num + 1 - 365 * past_years_num) * mint_ratio_this_year;
    }

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
        ini_timestamp = block.timestamp;
        ini_supply = inisupply * (10**uint256(decimals()));
        _mint(msg.sender, ini_supply);
    }

    address public contract_signer;

    function set_contract_signer(address _new_signer)
        external
        onlyContractOwner
    {
        contract_signer = _new_signer;
    }

    /**
     * Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
     * @dev Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function check_mint_sig(
        uint256 sig_id,
        uint256 amount,
        bytes memory sig
    ) private view {
        bytes32 hash = keccak256(abi.encodePacked(sig_id, msg.sender, amount));
        address msg_signer = recover(hash, sig);
        require(msg_signer == contract_signer, "signature error");
    }

    function miner_mint(
        uint256 signature_id,
        uint256 amount,
        bytes memory signature
    ) public {
        //amount check
        require(amount > 0, "mint amount should be bigger then 0");
        //
        require(mining_minted_map[signature_id] == 0, "repeated mint");
        mining_minted_map[signature_id] = amount;

        check_mint_sig(signature_id, amount, signature);

        uint256 after_add = miner_total_mint + amount;
        assert(after_add >= miner_total_mint); //safe math check
        require(after_add <= mining_mint_limit(), "mining over limit");

        miner_total_mint = after_add;
        _mint(msg.sender, amount);
    }

    //how many years passed since initial deployed
    function past_years() public view returns (uint256) {
        return (block.timestamp - ini_timestamp) / 365 days;
    }

    //how many days passed since initial deployed
    function past_days() public view returns (uint256) {
        return (block.timestamp - ini_timestamp) / 1 days;
    }
}
