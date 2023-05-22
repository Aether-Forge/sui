// SPDX-License-Identifier: Apache-2.0

module sui::emotes { // Alex" Emotes should be emotes by usual standards
// sui:: because the containing folder is named sui
    use sui::url::{Self, Url};
    use std::string::{utf8, Self, String};
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::transfer_policy as policy;
    use sui::tx_context::{Self, TxContext};

    use sui::package;
    use sui::display;


    struct NFT has key, store {
    // struct NFT<phantom T> has key, store { // if we want to make different types or something?
        id: UID,
        name: String,
        description: String,
        rarity: String,
        reaction: String,
        image_url: Url,
        url: Url,
        // TODO: allow custom attributes only for other assets
    }

    struct EMOTES has drop {}

    struct MintNFTEvent has copy, drop {
        object_id: ID,
        name: string::String,
        description: string::String,
        rarity: string::String,
        reaction: string::String,
        image_url: Url,
    }

    struct AdminKey has key, store {
        id: UID
    }

    /// In the module initializer one claims the `Publisher` object
    /// to then create a `Display`. The `Display` is initialized with
    /// a set of fields (but can be modified later) and published via
    /// the `update_version` call.
    ///
    /// Keys and values are set in the initializer but could also be
    /// set after publishing if a `Publisher` object was created.
    fun init(otw: EMOTES, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"image_url"), //TODO: maybe just image?
            utf8(b"rarity"),
            utf8(b"reaction"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator")
        ];

        let values = vector[
            utf8(b"{name}"),
            utf8(b"{image_url}"),
            utf8(b"{rarity}"),
            utf8(b"{reaction}"),
            utf8(b"{description}"),
            utf8(b"https://aethergames.io"),
            utf8(b"Aether Games")
        ];

        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);

        let admin_key = AdminKey {
            id: object::new(ctx)
        };

        // Get a new `Display` object for the `Hero` type.
        let display = display::new_with_fields<NFT>(
            &publisher, keys, values, ctx
        );

        // Commit first version of `Display` to apply changes.
        display::update_version(&mut display);

        // transfer policy
        let (policy, policy_cap) = policy::new<EMOTES>(&publisher, ctx);
        // share the policy, as long as we have the policy_cap we can modify it later
        transfer::public_share_object(policy);

        let sender = tx_context::sender(ctx);
        transfer::public_transfer(admin_key, sender);
        transfer::public_transfer(publisher, sender);
        transfer::public_transfer(display, sender);
        transfer::public_transfer(policy_cap, sender);
    }

    // ------------------ CREATE DESTROY ------------------

    public fun mint(
        _: &AdminKey,
        name: String,
        description: String,
        rarity: String,
        reaction: String,
        image_url: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ): NFT {
        let nft = NFT {
            id: object::new(ctx),
            name,
            description,
            rarity,
            reaction,
            image_url: url::new_unsafe_from_bytes(image_url),
            url: url::new_unsafe_from_bytes(url),

        };

        event::emit(MintNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            name: nft.name,
            description: nft.description,
            rarity: nft.rarity,
            reaction: nft.reaction,
            image_url: nft.image_url
        });

        nft
    }

    public entry fun create_admin_key(_: &AdminKey, recipient: address, ctx: &mut TxContext) {  //_: &AdminKey, acces control with key
        let admin_key = AdminKey {
            id: object::new(ctx)
        };
        transfer::public_transfer(admin_key, recipient);
    }

    public entry fun burn(nft: NFT) {
        let NFT { id, name: _, description: _, reaction: _, rarity: _, image_url: _, url: _ } = nft;
        object::delete(id);
    }

    // ------------------ GETTERS ------------------

    public fun name(nft: &NFT): &String {
        &nft.name
    }

    public fun description(nft: &NFT): &String {
        &nft.description
    }

    public fun url(nft: &NFT): &Url {
        &nft.url
    }

    public fun image_url(nft: &NFT): &Url {
        &nft.image_url
    }

    public fun rarity(nft: &NFT): &String {
        &nft.rarity
    }

    public fun reaction(nft: &NFT): &String {
        &nft.reaction
    }

    // public fun creator(nft: &NFT): &address {
    //     &nft.creator
    // }

    // ------------------------- SETTERS --------------------------------

    public entry fun set_name(_: &AdminKey, nft: &mut NFT, new_name: String) {
        nft.name = new_name;
    }

    public entry fun set_description(_: &AdminKey, nft: &mut NFT, new_description: String) {
        nft.description = new_description;
    }

    public entry fun set_url(_: &AdminKey, nft: &mut NFT, new_url: vector<u8>) {
        nft.url = url::new_unsafe_from_bytes(new_url);
    }

    public entry fun set_image_url(_: &AdminKey, nft: &mut NFT, new_image_url: vector<u8>) {
        nft.image_url = url::new_unsafe_from_bytes(new_image_url);
    }

    public entry fun set_rarity(_: &AdminKey, nft: &mut NFT, new_rarity: String) {
        nft.rarity = new_rarity;
    }

    public entry fun set_reaction(_: &AdminKey, nft: &mut NFT, new_reaction: String) {
        nft.reaction = new_reaction;
    }

    // public entry fun set_creator(_: &AdminKey, nft: &mut NFT, new_creator: address) {
    //     nft.creator = new_creator;
    // }


  //TODO: TRANSFER POLIOCY <------------------------------------------------------------

  #[test_only]
  public fun test_create_admin_key (ctx: &mut TxContext): AdminKey {
    AdminKey {
        id: object::new(ctx)
    }
  }
} 

#[test_only]
module sui::tests {

    use std::string;
    
    use sui::test_scenario as ts;
    use sui::transfer;
    use sui::url;

    use sui::emotes::{Self, AdminKey, NFT};

    // errors
    const EWrongName: u64 = 0;
    const EWrongDescription: u64 = 1;
    const EWrongRarity: u64 = 2;
    const EWrongReaction: u64 = 3;
    const EWrongImageUrl: u64 = 4;
    const EWrongURL: u64 = 5;

    const PLAYER: address = @0x123;

    #[test]
    fun test_mint_get_set () {
        // "globals"
        let scenario = ts::begin(PLAYER);
        let admin_key: AdminKey = emotes::test_create_admin_key(ts::ctx(&mut scenario));
        {
        let nft = emotes::mint(
            &admin_key,
            string::utf8(b"rofl"),
            string::utf8(b"Roll on the floor laughing"),
            string::utf8(b"Rare"),
            string::utf8(b"rofl"),
            b"https://rofl.lol",
            b"https://aethergames.com",
            ts::ctx(&mut scenario)
        );

        assert!(emotes::name(&nft) == &string::utf8(b"rofl"), EWrongName);
        assert!(emotes::description(&nft) == &string::utf8(b"Roll on the floor laughing"), EWrongDescription);
        assert!(emotes::rarity(&nft) == &string::utf8(b"Rare"), EWrongRarity);
        assert!(emotes::reaction(&nft) == &string::utf8(b"rofl"), EWrongReaction);
        assert!(emotes::image_url(&nft) == &url::new_unsafe_from_bytes(b"https://rofl.lol"), EWrongImageUrl);
        assert!(emotes::url(&nft) == &url::new_unsafe_from_bytes(b"https://aethergames.com"), EWrongURL);

        transfer::public_transfer(nft, PLAYER);
        };

        ts::next_tx(&mut scenario, PLAYER);
        {
            let nft = ts::take_from_sender<NFT>(&mut scenario);

            emotes::set_name(&admin_key, &mut nft, string::utf8(b"wth"));
            assert!(emotes::name(&nft) == &string::utf8(b"wth"), EWrongName);

            ts::return_to_sender<NFT>(&scenario, nft);

        };
        ts::next_tx(&mut scenario, PLAYER);
        {
            let nft = ts::take_from_sender<NFT>(&scenario);

            emotes::set_rarity(&admin_key, &mut nft, string::utf8(b"Common"));
            assert!(emotes::rarity(&nft) == &string::utf8(b"Common"), EWrongName);

            ts::return_to_sender<NFT>(&scenario, nft);
        };

        transfer::public_transfer(admin_key, PLAYER); // otherwise can't finish the test
        ts::end(scenario);
    }
}


// #[test_only]
// module nfts::DevNet_NFTTests {
//     use nfts::DevNet_NFT::{Self, NFT};
//     use sui::test_scenario as ts;
//     use sui::transfer;
//     use std::string;

//     #[test]
//     fun mint_transfer_update() {
//         let addr1 = @0xA;
//         let addr2 = @0xB;
//         // create the NFT
//         let scenario = ts::begin(addr1);
//         {
//             DevNet_NFT::mint(b"test", b"a test", b"https://www.sui.io", ts::ctx(&mut scenario))
//         };
//         // send it from A to B
//         ts::next_tx(&mut scenario, addr1);
//         {
//             let nft = ts::take_from_sender<NFT>(&mut scenario);
//             transfer::public_transfer(nft, addr2);
//         };
//         // update its description
//         ts::next_tx(&mut scenario, addr2);
//         {
//             let nft = ts::take_from_sender<NFT>(&mut scenario);
//             DevNet_NFT::update_description(&mut nft, b"a new description") ;
//             assert!(*string::bytes(DevNet_NFT::description(&nft)) == b"a new description", 0);
//             ts::return_to_sender(&mut scenario, nft);
//         };
//         // burn it
//         ts::next_tx(&mut scenario, addr2);
//         {
//             let nft = ts::take_from_sender<NFT>(&mut scenario);
//             DevNet_NFT::burn(nft)
//         };
//         ts::end(scenario);
//     }
// }