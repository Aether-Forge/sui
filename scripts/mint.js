const sui = require("@mysten/sui.js");
require("dotenv").config();

const pkg = "0x057d2c6f7910f8a415b57d4bd4403edaf88f1fd7da4e636c48fef7173e4c431e";
const adminKey = "0x40a66d08de6b4d01dd92672732e1f7084c0e4503c0e8418a0cbbf2ee08b3344e";

const getSignerAddressExample = () => {
  const privKey = sui.fromB64(process.env.PRIVATE_KEY);
  const keypair = sui.Ed25519Keypair.fromSecretKey(privKey);

  // our address
  const address = `${keypair.getPublicKey().toSuiAddress()}`;
  const provider = new sui.JsonRpcProvider(sui.devnetConnection);
  const signer = new sui.RawSigner(keypair, provider);
  
  return {signer, address};
};


const mint = async () => {
    const {signer, address} = getSignerAddressExample();

    const tx = new sui.TransactionBlock();

    const nft = tx.moveCall({
        target: `${pkg}::Emotes::mint`,
        typeArguments: [],
        arguments: [
            tx.object(adminKey),
            tx.pure("Laugh out Loud"),
            tx.pure("Laughing hard"),
            tx.pure("Common"),
            tx.pure("lol"),
            tx.pure("http://lol.com"),
            tx.pure("http://aether-games.com")
        ]
    });

    tx.transferObjects([nft], tx.pure(address));
    tx.setSender(address);
    
    return await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        options: {
            showEffects: true
        }
    });
}

const burn = async (emoteId) => {
    const {signer, address} = getSignerAddressExample();

    const tx = new sui.TransactionBlock();

    tx.moveCall({
        target: `${pkg}::Emotes::burn`,
        typeArguments: [],
        arguments: [tx.object(emoteId)]
    });

    tx.setSender(address);

    return await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        options: {
            showEffects: true
        }
    })
}

// helper

const mintResponseParser = (response) => {
    const result = {};
    result.status = response.effects.status.status;
    if (result.status == "success") {
        result.emoteId = response.effects.created[0].reference.objectId;
        result.owner = response.effects.created[0].owner.AddressOwner;
    }
    return result;
}


const main = async () => {
    // mint and burn the NFT

    const mintResp = await mint();

    const result = mintResponseParser(mintResp);

    const burnResp = await burn(result.emoteId);

    console.log(JSON.stringify(burnResp));
}

main();