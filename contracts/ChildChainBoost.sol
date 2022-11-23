// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract ChildChainBoost is NonblockingLzApp {
    // total supply of ve tokens from a parentChain
    uint256 public totalSupplyVE;

    struct Boost {
        uint256 received;
        uint256 expiryData;
    }

    // mapping of user to boost received from parentChain
    mapping(address => Boost) public boosts;

    constructor(address _endpoint) NonblockingLzApp(_endpoint) {}

    // TODO send function for communicating back to parentChains _lzSend()
    // function lzSend() {}

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory /*_srcAddress*/, uint64 /*_nonce*/, bytes memory _payload) internal virtual override {
        (uint16 funcType, bytes memory data) = abi.decode(_payload, (uint16, bytes));


        if (funcType == 1) {
            // total supply update
            (uint256 totalSupply) = abi.decode(data, (uint256));
            totalSupplyVE = totalSupply;

        } else if (funcType == 2) {
            // boost received
            (address receiver, uint256 receivedBoost, uint256 expiryData, uint256 totalSupply) = abi.decode(data, (address, uint256, uint256, uint256));
            totalSupplyVE = totalSupply;

            // TODO overrides existing boosts, not sure how we want to accumulate them, or if they can have multiple
            boosts[receiver] = Boost(receivedBoost, expiryData);
        } else {
            require(1 != 1, "invalid function type");
        }
    }

//    function getAdjustedBalanceOf(address _user) public view returns(uint256) {
//        return receivedBoosts[_user];
//    }
}