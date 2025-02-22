import {
  RpcProvider,
  Account,
  CallData,
  byteArray,
  CairoCustomEnum,
  Contract,
  hash,
} from "starknet";

import * as fs from "fs";
import * as path from "path";
import { fileURLToPath } from "url";

import { dirname } from "path";

import { ArgumentParser } from "argparse";

import "toml";

const parser = new ArgumentParser({ description: "Argparse example" });

parser.add_argument("-t", "--target-path", {
  help: "path to the target/ dir",
});

parser.add_argument("--profile", {
  help: "sozo profile",
  default: "dev",
});

parser.add_argument("-s", "--salt", {
  help: "salt for the contract",
  default: 0,
});

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const parsedArgs = parser.parse_args();
const profile = parsedArgs.profile;
const targetPath = path.join(path.resolve(parsedArgs.target_path), profile);

console.log(targetPath);

const getAccount = async (rpc, account1Address, privateKey1) => {
  const provider = new RpcProvider({ nodeUrl: rpc });
  console.log(`Connected to StarkNet node at ${rpc}`);
  const account = new Account(provider, account1Address, privateKey1);
  console.log(`Account address: ${account1Address}`);
  return [provider, account];
};

const loadJson = (rpath) => {
  return JSON.parse(fs.readFileSync(path.resolve(__dirname, rpath)));
};

const getContractPaths = (targetPath) => {
  let contracts = {};
  for (const file of fs.readdirSync(targetPath)) {
    const name = path.basename(file).split(".", 1);

    if (file.endsWith(".contract_class.json")) {
      name in contracts || (contracts[name] = {});
      contracts[name].contract = path.join(targetPath, file);
    } else if (file.endsWith(".compiled_contract_class.json")) {
      name in contracts || (contracts[name] = {});
      contracts[name].casm = path.join(targetPath, file);
    }
  }
  return contracts;
};

const declareContract = async (account, name, files) => {
  const contract = loadJson(files.contract);
  const classHash = hash.computeContractClassHash(contract);
  console.log(`\n\nClass hash for ${name}: ${classHash}`);
  try {
    await account.getClassByHash(classHash);
    console.log(`\t${name} already declared with classHash\n\t\t${classHash}`);
  } catch {
    try {
      console.log(`\tDeclaring ${name} with classHash\n\t\t${classHash}`);
      const casm = loadJson(files.casm);
      const declareResponse = await account.declare(
        { contract, casm },
        { version: 3 }
      );
      await account.waitForTransaction(declareResponse.transaction_hash);
      console.log(
        `\t${name} declared with classHash\n\t\t${declareResponse.class_hash}`
      );
    } catch {
      console.log(`\tFailed to declare ${name}`);
    }
  }

  return classHash;
};

const declareContracts = async (account, contracts) => {
  let classHashes = {};
  for (const contractName in contracts) {
    classHashes[contractName] = await declareContract(
      account,
      contractName,
      contracts[contractName]
    );
  }
  return classHashes;
};

const deployZeroContract = async (account, classHash) => {
  try {
    const deployResponse = await account.deployContract(
      {
        classHash,
        salt: "0x0",
        unique: false,
      },
      { version: 3 }
    );
    await account.waitForTransaction(deployResponse.transaction_hash);
    console.log(`Deployed contract with classHash: ${classHash}`);
  } catch {
    console.log(`Failed to deploy contract with classHash: ${classHash}`);
  }
};
const [provider, account] = await getAccount(
  process.env.STARKNET_RPC_URL,
  process.env.STARKNET_ACCOUNT_ADDRESS,
  process.env.STARKNET_PRIVATE_KEY
);

const contracts = getContractPaths(targetPath);
let contractHashes = await declareContracts(account, contracts);
deployZeroContract(account, contractHashes.dojo_beacon_example_m_Moves);
for (const contractName in contractHashes) {
  if (contractName.includes("_m_")) {
    await deployZeroContract(account, contractHashes[contractName]);
  }
}

const makeManifest = () => {};
