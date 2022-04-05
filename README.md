# erc20-contracts
### main network
### test network 


# address case issue:
We convert all address to lowercase for meson.network standard


# main network
```
MSNN
0x96311848c9977682eef4156424e4e447b1af23ad
MSNN_OWNER_WALLET
0xcc5a0850e51a9f439366c1ed676933b03989101b

MSNN_MINING
0x1ec0b8d69ada68aa4f9f3ee2538e60a5c84731bf
MSNN_MINING_OWNER_WALLET
0x413e6b908129f625b26372f82f5c954dd186f011
```

# test network

```
MSNTT
0x318b13467537f58890002847fe71eb2a74b6a5a5
MSNTT_OWNER_WALLET
0x8779b8c61096d1fd49a12ea296b10ccc41ff2cbd

MSNTT_MINING
0x674519c73734ec01b349c13096c6092e21255443
MSNTT_MINING_OWNER_WALLET
0x4d32c3d67656ae92b176cadf3ef48e00236f3063

MSNTT_DAO
0x94111374f8bf05c4fb64e4db0599eb30307e5021
MSNTT_DAO_OWNER_WALLET
```

### blow only for test network speicals are only meaning to test contract as mainnet contracts fully open !

### mapping(address => uint8) special_list :
#### 1 for MSNTT contract creator
#### 2 for MSNTT contract itself
#### 3 for MSNTT_MINING contract creator
#### 4 for MSNTT_MINING contract itself
#### 5 for MSNTT_DAO contract creator
#### 6 fro MSNTT_DAO contract itself

#### 7~ 100 currently reserved  for other contracts in the future
###  100 ~ 200 above for internal maintainers 
###  200 ~ 255 reserved not use now 
