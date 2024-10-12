// // SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title DiceCoin: A wager token.
/// @author Joel Markley
/// @notice DiceCoin is a wager token. The user can collect an initial pot of coins to play with and then they can wager those tokens on whether a dice roll will be: even or odd (x2 payout),
/// or a specific number 1-6 (x5 payout).
contract DiceCoin is ERC20NOEXTERNALS {
    // DC Events
    event WagerWon(uint256 payout);
    event WagerLost(uint256 wager);

    // DC Errors
    error TooBroke(address brokeIndividual);
    error NegativeWager();

    uint256 public INITIAL_SUPPLY = 1000000;

    uint256 public _payoutEvenOrOdd = 2;
    uint256 public _payoutExact = 5;
    enum WagerType {
        evenOdd,
        exact
    }
    mapping(WagerType => uint256) private getWagerMultiplier;

    uint256 randNonce = 0;

    constructor() ERC20NOEXTERNALS("Dice Coin", "DC") {
        _mint(address(this), INITIAL_SUPPLY);

        // Set wager multipliers
        getWagerMultiplier[WagerType.evenOdd] = _payoutEvenOrOdd;
        getWagerMultiplier[WagerType.exact] = _payoutExact;
    }

    modifier _wagerIsValid(
        uint256 wager,
        uint256 roll,
        WagerType wagerType
    ) {
        address sender = _msgSender();

        if (wager < 0) {
            revert NegativeWager();
        } 

        if (wagerType == WagerType.exact) {
            require(roll >= 0 && roll <= 6);
        }
        _;
    }

    /// @notice Returns a users DC wallet balance
    /// @return uint256 DC wallet balance
    function getDCWallet() public view returns (uint256) {
        return balanceOf(_msgSender());
    }

    /// @notice Allows a first time user to "buy in" and receive an initial pot of coin to play with
    /// @return true on success, false otherwise
    function buyIn() public returns (bool) {
        // Make sure the caller only gets to "buy in" once (i.e. their balance == 0)
        address sender = _msgSender();
        require(balanceOf(sender) == 0);

        // Give caller an initial pot of coin to play with
        _transfer(address(this), sender, 5);

        return true;
    }

    /// @notice Gets the payout of a wage given a WagerType
    /// @return uint256 amount of DC
    function _getPayout(
        uint256 wager,
        WagerType wagerType
    ) private view returns (uint256) {
        return wager * getWagerMultiplier[wagerType];
    }

    /// @notice Func used to generate a "random" number
    /// @param _modulus max (exclusive) number to generate a random number for
    /// @return uint256 representing "random" number (0, _modulus)
    function _randMod(uint256 _modulus) private returns (uint256) {
        randNonce++;
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, _msgSender(), randNonce)
                )
            ) % _modulus;
    }

    function _generateRandRoll() private returns (uint256) {
        return _randMod(6) + 1;
    }

    function _wagerWon(uint256 wager, WagerType wagerType) private {
        address sender = _msgSender();
        uint256 payout = _getPayout(wager, wagerType);
        _transfer(address(this), sender, payout);

        emit WagerWon(payout);
    }

    function _wagerLost(uint256 wager) private {
        address sender = _msgSender();
        _transfer(sender, address(this), wager);

        emit WagerLost(wager);
    }

    /// @notice Allows a user to place a wager on an even or odd roll number
    /// @param wager = wager value (DC), isEven = true if user believes roll will be an even number, false otherwise
    /// @return true on win and false otherwise
    function placeWager(
        uint256 wager,
        bool isEven
    ) public _wagerIsValid(wager, 0, WagerType.evenOdd) returns (uint256) {
        uint256 roll = _generateRandRoll();
        if ((roll % 2 == 0 && isEven) || (roll % 2 == 1 && !isEven)) {
            // Sender won wager
            _wagerWon(wager, WagerType.evenOdd);
        } else {
            // Sender lost wager
            // Deduct balance from sender
            _wagerLost(wager);
        }
        return roll;
    }

    /// @notice Allows a user to place a wager on a roll for an exact roll number
    /// @param wager = wager value (DC), num = number user wagers the roll will be (1 - 6 inclusive)
    /// @return true on win and false otherwise
    function placeWager(
        uint256 wager,
        uint256 num
    ) public _wagerIsValid(wager, num, WagerType.exact) returns (uint256) {
        uint256 roll = _generateRandRoll();
        if (roll == num) {
            _wagerWon(wager, WagerType.exact);
        } else {
            _wagerLost(wager);
        }
        return roll;
    }
}
