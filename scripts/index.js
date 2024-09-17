const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const V2_PAIR_ADDRESS = "0x3356c9A8f40F8E9C1d192A4347A76D18243fABC5";
const ROUTER_ADDRESS = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const FACTORY_ADDRESS = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";

const TOKEN_HOLDER = "0xf584F8728B874a6a5c7A8d4d387C9aae9172D621";
const TOKEN_HOLDER_RE = "0x23f4569002a5A07f0Ecf688142eEB6bcD883eeF8";

const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
// const WETH = "";


const constants = async () => {
  await helpers.impersonateAccount(TOKEN_HOLDER);
  const impersonatedSigner = await ethers.getSigner(TOKEN_HOLDER);

  const USDC_CONTRACT = await ethers.getContractAt(
    "IERC20",
    USDC,
    impersonatedSigner
  );

  const DAI_CONTRACT = await ethers.getContractAt(
    "IERC20",
    DAI,
    impersonatedSigner
  );

  const ROUTER = await ethers.getContractAt(
    "IUniswapV2Router02",
    ROUTER_ADDRESS,
    impersonatedSigner
  );

  const V2_PAIR = await ethers.getContractAt(
    "IUniswapV2Pair",
    V2_PAIR_ADDRESS,
    impersonatedSigner
  );

  const V2_FACTORY = await ethers.getContractAt(
    "IUniswapV2Factory",
    FACTORY_ADDRESS,
    impersonatedSigner
  );

  const WETH = await ROUTER.WETH();
  const feeData = await ethers.provider.getFeeData();

  return {
    impersonatedSigner,
    USDC_CONTRACT,
    ROUTER,
    DAI_CONTRACT,
    V2_FACTORY,
    V2_PAIR,
    DAI_CONTRACT,
    USDC_CONTRACT,
    WETH,
    feeData,
  };
};

const addLiquidity = async (
  tokenA,
  tokenB,
  amountADesired,
  amountBDesired,
  amountAMin,
  amountBMin,
  to,
  deadline
) => {
  const { ROUTER, feeData } = await constants();
  try {
    const res = await ROUTER.addLiquidity(
      tokenA,
      tokenB,
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin,
      to,
      deadline,
      {
        maxFeePerGas: feeData.maxFeePerGas,
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
      }
    );
    return res;
  } catch (error) {
    return error;
  }
};

const removeLiquidity = async (
  tokenA,
  tokenB,
  liquidity,
  amountAMin,
  amountBMin,
  to,
  deadline
) => {
  const { ROUTER } = await constants();

  try {
    const res = await ROUTER.removeLiquidity(
      tokenA,
      tokenB,
      liquidity,
      amountAMin,
      amountBMin,
      to,
      deadline
    );
    return res;
  } catch (error) {
    return error;
  }
};

const addLiquidityETH = async (
  token,
  amountTokenDesired,
  amountTokenMin,
  amountETHMin,
  to,
  deadline,
) => {
  const { ROUTER } = await constants();

  try {
    const res = await ROUTER.addLiquidityETH(
      token,
      amountTokenDesired,
      amountTokenMin,
      amountETHMin,
      to,
      deadline,
      { value: amountETHMin*BigInt(125)/BigInt(100)}
    );
    return res;
  } catch (error) {
    return error;
  }
};

const removeLiquidityETH = async (
  token,
  liquidity,
  amountTokenMin,
  amountETHMin,
  to,
  deadline
) => {
  try {
    const { ROUTER } = await constants();
    const res = await ROUTER.removeLiquidityETH(
      token,
      liquidity,
      amountTokenMin,
      amountETHMin,
      to,
      deadline
    );
    return res;
  } catch (error) {
    return error;
  }
};

const removeLiquidityWithPermit = async () => {};

const removeLiquidityETHWithPermit = async () => {};

const removeLiquidityETHSupportingFeeOnTransferTokens = async () => {};

const removeLiquidityETHWithPermitSupportingFeeOnTransferTokens =
  async () => {};

const swapExactTokensForTokens = async (
  amountIn,
  amountOutMin,
  path,
  to,
  deadline
) => {
  try {
    const res = await ROUTER.swapExactTokensForTokens(
      amountIn,
      amountOutMin,
      path,
      to,
      deadline
    );
    return res;
  } catch (error) {
    return error;
  }
};

const swapTokensForExactTokens = async (
  amountOut,
  amountInMax,
  path,
  to,
  deadline
) => {
  try {
    const res = await ROUTER.swapTokensForExactTokens(
      amountOut,
      amountInMax,
      path,
      to,
      deadline
    );
    return res;
  } catch (error) {
    return error;
  }
};

const swapExactETHForTokens = async (amountOutMin, path, to, deadline) => {
  try {
    const res = await ROUTER.swapExactETHForTokens(
      amountOutMin,
      path,
      to,
      deadline
    );
    return res;
  } catch (error) {
    return error;
  }
};

const swapExactTokensForETH = async (
  amountIn,
  amountOutMin,
  path,
  to,
  deadline
) => {
  try {
    const res = await ROUTER.swapExactTokensForETH(
      amountIn,
      amountOutMin,
      path,
      to,
      deadline
    );
    return res;
  } catch (error) {
    return error;
  }
};

const swapETHForExactTokens = async (amountOut, path, to, deadline) => {
  try {
    const res = await ROUTER.swapETHForExactTokens(
      amountOut,
      path,
      to,
      deadline
    );
    return res;
  } catch (error) {
    return error;
  }
};

const swapExactTokensForTokensSupportingFeeOnTransferTokens = async () => {};

const swapExactETHForTokensSupportingFeeOnTransferTokens = async () => {};

const swapExactTokensForETHSupportingFeeOnTransferTokens = async () => {};

module.exports = {
  V2_PAIR_ADDRESS,
  ROUTER_ADDRESS,
  FACTORY_ADDRESS,
  TOKEN_HOLDER,
  USDC,
  DAI,
  addLiquidity,
  removeLiquidity,
  addLiquidityETH,
  removeLiquidityETH,
  removeLiquidityWithPermit,
  removeLiquidityETHWithPermit,
  removeLiquidityETHSupportingFeeOnTransferTokens,
  removeLiquidityETHWithPermitSupportingFeeOnTransferTokens,
  swapExactTokensForTokens,
  swapTokensForExactTokens,
  swapExactETHForTokens,
  swapExactTokensForETH,
  swapETHForExactTokens,
  swapExactTokensForTokensSupportingFeeOnTransferTokens,
  swapExactETHForTokensSupportingFeeOnTransferTokens,
  swapExactTokensForETHSupportingFeeOnTransferTokens,
  constants,
};
