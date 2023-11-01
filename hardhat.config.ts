import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-ethers";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import { config as envConfig } from "dotenv";

envConfig();

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: { chainId: 1337 },
    goerli: {
      chainId: 5,
      accounts: [process.env.PRIVATE_KEY!],
      url: process.env.INFURA_KEY
        ? `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`
        : "https://goerli.gateway.tenderly.co",
      verify: {
        etherscan: {
          apiKey: process.env.ETHERSCAN_API_KEY!,
        },
      },
    },
    mainnet: {
      chainId: 1,
      accounts: [process.env.PRIVATE_KEY!],
      url: process.env.INFURA_KEY
        ? `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`
        : "https://eth.llamarpc.com",
      verify: {
        etherscan: {
          apiKey: process.env.ETHERSCAN_API_KEY!,
        },
      },
    },
  },
};

export default config;
