// import { Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock } from "@mysten/sui.js"
const { Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock } = require("@mysten/sui.js")
const { execSync } = require("child_process")

const main = async () => {
  // Generate a new Keypair
  const keypair = new Ed25519Keypair()
  const provider = new JsonRpcProvider()
  const signer = new RawSigner(keypair, provider)
  const { modules, dependencies } = JSON.parse(
    execSync(`${cliPath} move build --dump-bytecode-as-base64 --path ${packagePath}`, { encoding: "utf-8" })
  )
  const tx = new TransactionBlock()
  const [upgradeCap] = tx.publish({
    modules,
    dependencies,
  })
  tx.transferObjects([upgradeCap], tx.pure(await signer.getAddress()))
  const result = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
  })
  console.log({ result })
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
