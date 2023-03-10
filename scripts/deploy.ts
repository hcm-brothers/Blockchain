import { ethers, hardhatArguments } from "hardhat";
import * as Config from "./config";

async function main() {
  await Config.initConfig();
  const network = hardhatArguments.network ? hardhatArguments.network : "dev";
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // const Darts = await ethers.getContractFactory("Darts");
  // const darts = await Darts.deploy();
  // console.log("Darts address: ", darts.address);
  // Config.setConfig(network + ".Darts", darts.address);

  // const Vault = await ethers.getContractFactory("Vault");
  // const vault = await Vault.deploy();
  // console.log("Darts address: ", vault.address);
  // Config.setConfig(network + ".Vault", vault.address);

  // const Usdt = await ethers.getContractFactory("Usdt");
  // const usdt = await Usdt.deploy();
  // console.log("Usdt address: ", usdt.address);
  // Config.setConfig(network + ".Usdt", usdt.address);

  // const Ico = await ethers.getContractFactory("DARTSCrowdSale");
  // const ico = await Ico.deploy(
  //   1000,
  //   100,
  //   "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  //   "0xa6c68BaBBd27982E2BAd2B8153FBD65C1C8AE0Ed"
  // );
  // console.log("Ico address: ", ico.address);
  // Config.setConfig(network + ".Ico", ico.address);

  // const Nft = await ethers.getContractFactory("HeroNFT");
  // const nft = await Nft.deploy();
  // console.log("Nft address: ", nft.address);
  // Config.setConfig(network + ".Nft", nft.address);

  const HeroMarket = await ethers.getContractFactory("HeroMarketPlace");
  const heroMarket = await HeroMarket.deploy(
    "0x72965F99b239eAc613591aE3fCa432FfC47AF2a1",
    "0xFF0FE89C054509F86E39B08C759878B19C2CcC84"
  );
  console.log("HeroMarket address: ", heroMarket.address);
  Config.setConfig(network + ".HeroMarket", heroMarket.address);

  await Config.updateConfig();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
