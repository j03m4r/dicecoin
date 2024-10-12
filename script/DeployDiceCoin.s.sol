// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Script} from "../lib/forge-std/src/Script.sol";
import {DiceCoin} from "../src/DiceCoin.sol";

contract DeployDiceCoin is Script {
    function run() external returns (DiceCoin) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiceCoin DC = new DiceCoin();

        vm.stopBroadcast();
        return DC;
    }
}
