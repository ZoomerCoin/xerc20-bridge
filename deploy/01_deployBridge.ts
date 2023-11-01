import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const connextAddresses: Record<number, string> = {
  1: "0x840541b6C760D505C720e4409598f27135F4FD80", // grumpy adapter on mainnet
  10: "0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA",
  56: "0xCd401c10afa37d641d2F594852DA94C700e4F2CE",
  137: "0x11984dc4465481512eb5b777E44061C158CF2259",
  42161: "0xEE9deC2712cCE65174B561151701Bf54b99C24C8",
};

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // Get the chain id
  const chainId = +(await hre.getChainId());
  console.log("chainId", chainId);

  // Get the deployer
  const [deployer] = await hre.ethers.getSigners();
  if (!deployer) {
    throw new Error(`Cannot find signer to deploy with`);
  }

  console.log(
    "\n============================= Deploying Bridge ==============================="
  );
  console.log("deployer: ", deployer.address);
  const args = [
    50, // fee
    [0], // connext bridge enum
    [connextAddresses[chainId]], // connext bridge address
  ];

  // Deploy contract
  const adapter = await hre.deployments.deploy("Bridge", {
    from: deployer.address,
    args: [],
    log: true,
    proxy: {
      execute: {
        init: {
          methodName: "initialize",
          args,
        },
      },
      proxyContract: "OpenZeppelinTransparentProxy",
    },
    // deterministicDeployment: true,
  });
  console.log(`Bridge deployed to ${adapter.address}`);
};
export default func;
func.tags = ["grumpycat", "test", "prod"];
