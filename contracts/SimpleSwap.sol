// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    
    address public tokenAAddr;
    address public tokenBAddr;

    constructor(address _tokenA, address _tokenB) ERC20("Simpleswap Token", "STK"){
        require(_tokenA.code.length > 0, "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(_tokenB.code.length > 0, "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(_tokenA!=_tokenB,"SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(token0 < token1, "SimpleSwap: TOKENA_SHOULD_BE_LESS_THAN_TOKENB");
        tokenAAddr = token0;
        tokenBAddr = token1;
    }
    // Implement core logic here
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut){
        require(tokenIn == tokenAAddr || tokenIn == tokenBAddr, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == tokenAAddr || tokenOut == tokenBAddr, "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(amountIn > 0,"SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        (uint256 reserveA_, uint256 reserveB_) = this.getReserves();

        if (tokenIn == tokenAAddr){
            amountOut = amountIn * reserveB_ / ( reserveA_ + amountIn);
            ERC20(tokenAAddr).transferFrom(msg.sender, address(this), amountIn);
            ERC20(tokenBAddr).approve(address(this), amountOut);
            ERC20(tokenBAddr).transferFrom(address(this), msg.sender, amountOut);
        } else if (tokenIn == tokenBAddr) {
            amountOut = amountIn * reserveA_ / (reserveB_ + amountIn);
            ERC20(tokenBAddr).transferFrom(msg.sender, address(this), amountIn);
            ERC20(tokenAAddr).approve(address(this), amountOut);
            ERC20(tokenAAddr).transferFrom(address(this), msg.sender, amountOut);
        }

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }
    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity){
        require(amountAIn > 0 && amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        (uint256 reserveA, uint256 reserveB) = this.getReserves();

        if (reserveA == 0 && reserveB == 0){
            (amountA, amountB) = (amountAIn, amountBIn);
        } else {
            uint256 amountBOptional =  amountAIn * reserveB / reserveA;
            if (amountBOptional <= amountBIn){
                (amountA, amountB) = ( amountAIn, amountBOptional );
            } else {
                uint256 amountAOptional =  amountBIn * reserveA / reserveB;
                assert(amountAOptional <= amountAIn);
                (amountA, amountB) = ( amountAOptional, amountBIn);
            }
        }

        uint256 _totalSupply = totalSupply();
        if ( _totalSupply == 0 ) {
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            liquidity = Math.min(( amountA * _totalSupply ) / reserveA , ( amountB * _totalSupply ) / reserveB );
        }

        ERC20(tokenAAddr).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenBAddr).transferFrom(msg.sender, address(this), amountB);

        _mint(msg.sender, liquidity);

        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }   
    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB){
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        _transfer(msg.sender, address(this), liquidity);

        (uint256 _reserveA, uint256 _reserveB) = this.getReserves();
        uint256 _totalSupply = totalSupply();

        amountA = (liquidity * _reserveA) / _totalSupply;
        amountB = (liquidity * _reserveB) / _totalSupply;

        ERC20(tokenAAddr).transfer(msg.sender, amountA);
        ERC20(tokenBAddr).transfer(msg.sender, amountB);

        _burn(address(this), liquidity);

        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB){
        reserveA = ERC20(tokenAAddr).balanceOf(address(this));
        reserveB = ERC20(tokenBAddr).balanceOf(address(this));
    }
    function getTokenA() external view returns (address tokenA){
        tokenA = tokenAAddr;
    }
    function getTokenB() external view returns (address tokenB){
        tokenB = tokenBAddr;
    }

}
