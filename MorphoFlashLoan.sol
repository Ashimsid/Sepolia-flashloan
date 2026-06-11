// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IMorpho {
    function flashLoan(
        address token,
        uint256 assets,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract MorphoFlashLoan {
    // Morpho Blue on Sepolia
    address public constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

    address public owner;

    event FlashLoanExecuted(address token, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Trigger a flashloan for `amount` of `token`
    function executeFlashLoan(address token, uint256 amount) external onlyOwner {
        bytes memory data = abi.encode(token, amount);
        IMorpho(MORPHO).flashLoan(token, amount, data);
        emit FlashLoanExecuted(token, amount);
    }

    /// @notice Morpho calls this during the flashloan
    /// @dev You MUST approve Morpho to pull back `assets` by the end of this function
    function onMorphoFlashLoan(uint256 assets, bytes calldata data) external {
        require(msg.sender == MORPHO, "caller is not Morpho");

        (address token, ) = abi.decode(data, (address, uint256));

        // ── YOUR LOGIC GOES HERE ──────────────────────────────────────
        // At this point your contract holds `assets` tokens.
        // Do arbitrage, liquidation, collateral swap, etc.
        // For now we just borrow and return immediately.
        // ─────────────────────────────────────────────────────────────

        // Approve Morpho to pull back the exact amount
        IERC20(token).approve(MORPHO, assets);
    }

    /// @notice Withdraw any tokens accidentally sent to this contract
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }

    receive() external payable {}
}
