require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
  //   hardhat: {
  //     forking: {
  //       enabled: true,
  //       url: `https://mainnet.infura.io/v3/${process.env.INFURA_ID}`,
  //       blockNumber: 14390000,
  //     }, 
  //     chainId: 1,
  //   }
  }
};
