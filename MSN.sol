// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {
    address public contract_owner;
    uint256 public ini_supply;
    uint256 public ini_timestamp;

    // day => total airdrop claimed in that day
    mapping(uint256 => uint256) public daily_airdrop;
    // airdrop_sig_id => amount
    mapping(uint256 => uint256) public airdrop_map;
    // day => total miner token mint in that day
    mapping(uint256 => uint256) public daily_mining_minted;
    // mining_mint_sig_id => amount
    mapping(uint256 => uint256) public mining_minted_map;

    // how many tokens can be mint for today
    function today_mining_mint_limit() public view returns (uint256) {
        uint256 past_years = years_num();
        uint256 mint_ratio_this_year = 50 - 5 * past_years;
        if (mint_ratio_this_year < 0) {
            mint_ratio_this_year = 0;
        }
        uint256 today_mint_limit = ((mint_ratio_this_year * ini_supply) /
            1000) / 365;
        return today_mint_limit;
    }

    // how many tokens can be airdropped for today ,limited for safety
    function today_airdrop_limit() public view returns (uint256) {
        return ini_supply / 1000;
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

        //check daily reward pool of miners
        uint256 today_m_mint_limit = today_mining_mint_limit();
        require(today_m_mint_limit > 0, "no more mint");
        //
        uint256 past_day = days_num();
        uint256 after_add = daily_mining_minted[past_day] + amount;
        assert(after_add >= daily_mining_minted[past_day]); //safe math check
        require(
            after_add > today_m_mint_limit,
            "no token left to mint today, try tomorrow"
        );
        daily_mining_minted[past_day] = after_add;
        _mint(msg.sender, amount);
    }

    function airdrop_claim(
        uint256 signature_id,
        uint256 amount,
        bytes memory signature
    ) public {
        //amount check
        require(amount > 0, "claim amount should be bigger then 0");
        //
        require(airdrop_map[signature_id] == 0, "repeated claim");
        airdrop_map[signature_id] = amount;

        check_mint_sig(signature_id, amount, signature);
        //
        uint256 past_day = days_num();
        uint256 after_add = daily_airdrop[past_day] + amount;
        assert(after_add >= daily_airdrop[past_day]); //safe math check
        require(
            after_add > today_airdrop_limit(),
            "airdrop reach limit today, try tomorrow"
        );
        daily_airdrop[past_day] = after_add;
        transfer(msg.sender, amount);
    }

    //how many years passed since initial deployed
    function years_num() private view returns (uint256) {
        return (block.timestamp - ini_timestamp) / 365 days;
    }

    //how many days passed since initial deployed
    function days_num() private view returns (uint256) {
        return (block.timestamp - ini_timestamp) / 1 days;
    }
}
