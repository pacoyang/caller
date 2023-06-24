import { ethers } from "hardhat";
import fs from "fs";

interface Request {
  callerAddress: string;
  id: number;
}

const SLEEP_TIME = 2000;
const BATCH_SIZE = 3;

function getRandomInteger(min: number, max: number): number {
  min = Math.floor(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function main() {
  const provider = new ethers.WebSocketProvider("ws://localhost:8545");
  const signer = await provider.getSigner();
  // deploy contract
  const randOracle = await ethers.deployContract("RandOracle");
  await randOracle.waitForDeployment();
  console.info("RandOracle deployed to:", randOracle.target);
  const caller = await ethers.deployContract("Caller");
  await caller.waitForDeployment();
  console.info("Caller deployed to:", caller.target);

  const RandOracle = JSON.parse(
    fs
      .readFileSync("./artifacts/contracts/RandOracle.sol/RandOracle.json")
      .toString()
  );
  // listen to contract event
  const contract = new ethers.Contract(
    randOracle.target as string,
    RandOracle.abi,
    signer
  );
  await randOracle.addProvider(signer);
  const requestsQueue: Request[] = [];
  contract.on(
    "RandomNumberRequested",
    async (callerAddress: string, id: number) => {
      console.info(`RandomNumberRequested: ${callerAddress} ${id}`);
      requestsQueue.push({ callerAddress, id });
    }
  );
  // process requests queue at intervals
  setInterval(async () => {
    let processedRequests = 0;
    while (requestsQueue.length > 0 && processedRequests < BATCH_SIZE) {
      const request = requestsQueue.shift();
      if (request) {
        const randomNumber = getRandomInteger(1, 1000);
        // return random number to oracle contract
        await contract.returnRandomNumber(
          randomNumber,
          request.callerAddress,
          request.id
        );
        processedRequests++;
      }
    }
  }, SLEEP_TIME);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
