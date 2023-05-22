const sui = require("@mysten/sui.js");
require("dotenv").config();

const pkg = "0xce247eb7810234a1f3a9b491409dba60712650272f98ad6a29d45b6445426519";
const adminKey = "0xf506ad3eb464c1bef85dee740a543f6b1774b71c5b706ca5fedae855d935d90b";

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
        target: `${pkg}::emotes::mint`,
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
        target: `${pkg}::emotes::burn`,
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