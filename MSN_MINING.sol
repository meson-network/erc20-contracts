// SPDX-License-Identifier: GPL v3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MSN_MINING {
    address public msn_contract_address;
    uint256 public mining_inflation_base;

    //mining
    address public miner_signer;
    uint256 public mining_start_timestamp;
    uint256 public miner_total_mint; //total tokens minted by all miners in the past
    mapping(uint256 => uint256) private mining_sig_minted_map; // mining mint signature id => amount

    //sum(inflation rate)*1000 for mining in each year
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

    address public contract_owner;
    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "Only contractOwner");
        _;
    }

    constructor(
        address _msn_contract_addr,
        uint256 _mining_inflation_base,
        uint256 _mining_start_time
    ) {
        msn_contract_address = _msn_contract_addr;
        mining_inflation_base = _mining_inflation_base;
        contract_owner = msg.sender;
        mining_start_timestamp = _mining_start_time;
    }

    function check_mining_minted(uint256 sig_id) public view returns (bool) {
        if (mining_sig_minted_map[sig_id] == 0) {
            return false;
        } else {
            return true;
        }
    }

    // sum of all the tokens can be minted currently
    function mining_mint_limit() public view returns (uint256) {
        uint256 past_years_num = past_years();
        uint256 past_days_num = past_days();

        /////////past years total limit //////////////
        uint256 past_years_mint_limit = 0;
        if (past_years_num == 0) {
            //keeps past_years_mint_limit 0
        } else if (past_years_num < 10)
            past_years_mint_limit =
                (miner_mint_years_limit[past_years_num - 1] *
                    mining_inflation_base) /
                1000;
        else {
            past_years_mint_limit =
                (miner_mint_years_limit[9] * mining_inflation_base) /
                1000;
        }

        /////////this year total limit /////////////////////
        uint256 mint_ratio_this_year = 0;
        if (past_years_num == 0) {
            mint_ratio_this_year = miner_mint_years_limit[past_years_num];
        } else if (past_years_num < 10) {
            mint_ratio_this_year =
                miner_mint_years_limit[past_years_num] -
                miner_mint_years_limit[past_years_num - 1];
        } else {
            //keeps mint_ratio_this_year 0
        }

        uint256 this_year_limit = ((past_days_num + 1 - 365 * past_years_num) *
            mining_inflation_base *
            mint_ratio_this_year) /
            365 /
            1000;

        ///////////////////////////////////////////////////
        return past_years_mint_limit + this_year_limit;
    }

    function set_miner_signer(address _new_signer) external onlyContractOwner {
        miner_signer = _new_signer;
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
        require(msg_signer == miner_signer, "signature error");
    }

 
    function miner_mint(
        uint256 signature_id,
        uint256 amount,
        bytes memory signature
    ) public {
        require(amount > 0, "mint amount should be bigger then 0");
        
        require(mining_sig_minted_map[signature_id] == 0, "repeated mint");
        mining_sig_minted_map[signature_id] = amount;

        uint256 after_add = miner_total_mint + amount;
        assert(after_add > miner_total_mint); //safe math check
        require(after_add <= mining_mint_limit(), "mining over limit");
        miner_total_mint = after_add;

        check_mint_sig(signature_id, amount, signature);

        //transfer
        bool result = IERC20(msn_contract_address).transfer(msg.sender, amount);
        require(result == true, "transfer error");
    }

    //how many years passed since initial deployed
    function past_years() public view returns (uint256) {
        return (block.timestamp - mining_start_timestamp) / 365 days;
    }

    //how many days passed since initial deployed
    function past_days() public view returns (uint256) {
        return (block.timestamp - mining_start_timestamp) / 1 days;
    }
}
