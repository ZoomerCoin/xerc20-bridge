import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

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
    ["0x840541b6C760D505C720e4409598f27135F4FD80"], // connext bridge address (grumpy adapter)
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
