// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";

contract EvoMint is ERC20, Ownable(msg.sender), Pausable {
    uint32 constant INTERVAL = 30 days;
    uint32 timeMintedLast;
    address public v2Router;
    address public v2Factory;

    constructor(address _v2Router, address _v2Factory) ERC20("EvoMint", "EVT") {
        _mint(msg.sender, 1000000e18);
        timeMintedLast = uint32(block.timestamp);
        v2Router = _v2Router;
        v2Factory = _v2Factory;
    }

    // custom errors
    error YouCanOnlyMintOnceEvery30Days();
    error ZeroAddressNotAllowed();
    error ZeroAmountNotAllowed();
    error TokenWethPairDoesNotExist();

    // events
    event Minted(address indexed user, uint256 amount);
    event Burned(uint256 amount);
    event TokenWethPairCreated(
        address token1,
        address token2,
        address pairAddress
    );
    event LiquidityAddedToTokenPair(
        address pairAddress,
        uint amountA,
        uint amountB,
        uint liquidity
    );
    event TokensSwappedForETH(uint[] amounts);

    // functions
    // function to mint once every 30 days
    function mint(uint256 _amount) external onlyOwner {
        // checks
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();
        if (block.timestamp < timeMintedLast + INTERVAL)
            revert YouCanOnlyMintOnceEvery30Days();
        if (_amount <= 0) revert ZeroAmountNotAllowed();

        _mint(msg.sender, _amount);

        timeMintedLast = uint32(block.timestamp);

        emit Minted(msg.sender, _amount);
    }

    // pause contract functions
    function pause() external onlyOwner {
        _requireNotPaused();
        _pause();
    }

    // unpause contract functions
    function unpause() external onlyOwner {
        _requirePaused();
        _unpause();
    }

    // burn tokens
    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
    }

    function swapTokensForEth(
        uint _amountIn,
        uint _amountOutMin,
        address[] calldata _path,
        address _to,
        uint _deadline
    ) external {
        _requireNotPaused();
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();

        address _weth = IUniswapV2Router02(v2Router).WETH();
        address pairAddress = IUniswapV2Factory(v2Factory).getPair(
            address(this),
            _weth
        );

        if (pairAddress == address(0)) revert TokenWethPairDoesNotExist();

        if (_amountIn <= 0) revert ZeroAmountNotAllowed();
        require(
            IERC20(address(this)).balanceOf(msg.sender) >= _amountIn,
            "Insufficient token balance"
        );

        IERC20(address(this)).transferFrom(
            msg.sender,
            address(this),
            _amountIn
        );

        IERC20(address(this)).approve(v2Router, _amountIn);

        uint[] memory amounts = IUniswapV2Router02(v2Router)
            .swapExactTokensForETH(
                _amountIn,
                _amountOutMin,
                _path,
                _to,
                _deadline
            );

        emit TokensSwappedForETH(amounts);
    }

    function _createTokenWethPair() internal {
        _requireNotPaused();
        address _weth = IUniswapV2Router02(v2Router).WETH();

        address pairAddress = IUniswapV2Factory(v2Factory).createPair(
            address(this),
            _weth
        );

        emit TokenWethPairCreated(address(this), _weth, pairAddress);
    }

    function createTokenWethPair() external onlyOwner {
        _createTokenWethPair();
    }

    function addLiquidity(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
    ) external payable {
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();
        if (amountTokenDesired <= 0) revert ZeroAmountNotAllowed();
        if (msg.value <= 0) revert ZeroAmountNotAllowed();

        // Transfer the tokens from the user to the contract
        IERC20(address(this)).transferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );

        // Approve the Uniswap router to spend the tokens
        IERC20(address(this)).approve(v2Router, amountTokenDesired);

        _addLiquidityToPair(
            address(this),
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            deadline,
            msg.value
        );
    }

    function _addLiquidityToPair(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint ethValue
    ) internal {
        _requireNotPaused();

        address _weth = IUniswapV2Router02(v2Router).WETH();
        address pairAddress = IUniswapV2Factory(v2Factory).getPair(
            address(this),
            _weth
        );

        if (pairAddress == address(0)) revert TokenWethPairDoesNotExist();

        IERC20(address(this)).approve(v2Router, amountTokenDesired);

        (uint amountA, uint amountB, uint liquidity) = IUniswapV2Router02(
            v2Router
        ).addLiquidityETH{value: ethValue}(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );

        emit LiquidityAddedToTokenPair(
            pairAddress,
            amountA,
            amountB,
            liquidity
        );
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
