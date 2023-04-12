// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../interfaces/IL2LayerZeroDelegation.sol";

contract L2LayerZeroDelegation is IL2LayerZeroDelegation {

    function onVeBalBridged(address user) external {}

    function onVeBalSupplyUpdate() external {}
}
