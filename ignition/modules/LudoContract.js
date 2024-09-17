const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("LudoContractModule", (m) => {

  const LudoContract = m.contract("LudoContract");

  return { LudoContract };
});
