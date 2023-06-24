import { ethers } from "hardhat";
import fs from "fs";

// run provider script and replace the contract addresses
const ORACLE_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const CALLER_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

async function main() {
  const provider = new ethers.WebSocketProvider("ws://localhost:8545");
  const signer = await provider.getSigner();
  const Caller = JSON.parse(
    fs.readFileSync("./artifacts/contracts/Caller.sol/Caller.json").toString()
  );
  const contract = new ethers.Contract(CALLER_ADDRESS, Caller.abi, signer);
  contract.on("OracleAddressChanged", async (address: string) => {
    console.info(`OracleAddressChanged: ${address}`);
  });
  contract.on("RandomNumberRequested", async (id: number) => {
    console.info(`RandomNumberRequested: ${id}`);
  });
  contract.on(
    "RandomNumberReceived",
    async (randomNumber: number, id: number) => {
      console.info(`RandomNumberReceived: ${id} ${randomNumber}`);
    }
  );
  await contract.setRandOracleAddress(ORACLE_ADDRESS);
  await contract.getRandomNumber();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
