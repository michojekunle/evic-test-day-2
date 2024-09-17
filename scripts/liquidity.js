const {
  addLiquidity,
  addLiquidityETH,
  constants,
  USDC,
  DAI,
  removeLiquidity,
  removeLiquidityETH,
} = require(".");
const { ethers } = require("hardhat");

async function main() {
  const {
    impersonatedSigner,
    V2_PAIR,
    V2_FACTORY,
    USDC_CONTRACT,
    DAI_CONTRACT,
    ROUTER,
    WETH,
  } = await constants();
  const deadline = Math.floor(Date.now() / 1000) + 60 * 10;
  const slippageTolerance = 0.8; // 80%

  // adliquidityETH
  const amountTokenDesired = ethers.parseUnits("100", 6);
  const amountTokenMin =
    (amountTokenDesired * BigInt(1000 - slippageTolerance * 1000)) /
    BigInt(1000);
  const amountETHMin = ethers.parseEther("0.01");

  //  Remove liquidity ETH
  const amountUSDCDesiredRemL = ethers.parseUnits("2", 6);
  const amountDAIDesiredRemL = ethers.parseUnits("2", 18);
  let liquidityRemL = ethers.parseUnits("1", 18);

  const pairAddl = await V2_FACTORY.getPair(USDC, DAI);
  console.log("========================================");

  // console.log("Liquidity pair NAME", nameAddl);
  // console.log("Liquidity pair SYMBOL", symbolAddl);
  console.log("Liquidity Pair", pairAddl);
  const balBeforeAddlETH = await ethers.provider.getBalance(
    impersonatedSigner.address
  );
  console.log("Balance before adding liquidity eth", balBeforeAddlETH);

  await USDC_CONTRACT.approve(ROUTER, amountTokenDesired);

  // token,
  // amountTokenDesired,
  // amountTokenMin,
  // amountETHMin,
  // to,
  // deadline
  const addLiquidityETHTx = await addLiquidityETH(
    USDC,
    amountTokenDesired,
    amountTokenMin,
    amountETHMin,
    impersonatedSigner.address,
    deadline
  );

  console.log("Liquidity ETH added successfully.");

  const pairAddlETH = await V2_FACTORY.getPair(USDC, WETH);

  console.log("Weth & usdc pair", pairAddlETH);

  console.log("========================================");
  console.log("Add liquidity ETH", addLiquidityETHTx);
  console.log("========================================");

  const balAfterAddlETH = await ethers.provider.getBalance(
    impersonatedSigner.address
  );
  console.log("Balance after adding liquidity eth", balAfterAddlETH);

  await USDC_CONTRACT.approve(ROUTER, amountUSDCDesiredRemL);
  await DAI_CONTRACT.approve(ROUTER, amountDAIDesiredRemL);

  let liquidityEthRemL = ethers.parseUnits("1", 18);

  const pairContractWETH = await ethers.getContractAt(
    "IERC20",
    pairAddlETH,
    impersonatedSigner
  );
  const liquidityBalanceWETH = await pairContractWETH.balanceOf(
    impersonatedSigner
  );
  if (liquidityBalanceWETH < liquidityEthRemL) {
    liquidityEthRemL = liquidityBalanceWETH / BigInt(2);
    console.log(
      liquidityBalanceWETH,
      liquidityRemL
    );
  }

  pairContractWETH.approve(ROUTER, liquidityBalanceWETH);

  // token,
  // liquidity,
  // amountTokenMin,
  // amountETHMin,
  // to,
  // deadline
  const removeLiquidityETHTx = await removeLiquidityETH(
    USDC,
    liquidityEthRemL,
    0,
    0,
    impersonatedSigner.address,
    deadline
  );

  console.log("========================================");
  console.log("remove Liquidity ETH Tx", removeLiquidityETHTx);
  console.log("========================================");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
