const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("LudoContractModule", (m) => {
  const linkToken = "0x98F3bc937aB52d5B54BF4eBD7BaB8746eC14A159";
  const vrfCoordninator = "0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE";

  const LudoContract = m.contract("LudoContract", [vrfCoordninator, linkToken]);

  return { LudoContract };
});
