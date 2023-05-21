// SPDX-License-Identifier: Apache-2.0

module AetherGames::Emotes {
    use sui::url::{Self, Url};
    use std::string::{utf8, Self};
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use sui::package;
    use sui::display;


    struct NFT has key, store {
    // struct NFT<phantom T> has key, store { // if we want to make different types or something
        id: UID,
        /// Name for the token
        name: string::String,
        /// Description of the token
        description: string::String,
        /// Rarity of the token
        rarity: string::String,
        /// Reaction of the token
        reaction: string::String,
        /// Image URL for the token
        image_url: Url,
        /// URL for the token
        url: Url,
        // TODO: allow custom attributes
    }

    struct EMOTES has drop {}

    struct MintNFTEvent has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        // creator: address,
        // The name of the NFT
        name: string::String,
        // The description of the NFT
        description: string::String,
        // The rarity of the NFT
        rarity: string::String,
        // The reaction of the NFT
        reaction: string::String,
        // The image URL of the NFT
        image_url: Url,
        // The URL of the NFT
        // url: Url,
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
            // utf8(b"link"),
            utf8(b"image_url"), //TODO: maybe just image?
            utf8(b"rarity"),
            utf8(b"reaction"),
            utf8(b"description"),
            utf8(b"project_url"),
            // utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"{name}"),
            utf8(b"{image_url}"),
            utf8(b"{rarity}"),
            utf8(b"{reaction}"),
            utf8(b"{description}"),
            utf8(b"https://aethergames.io"),
            // Creator field can be any
            // utf8(b"Aether Games")
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

        let sender = tx_context::sender(ctx);
        transfer::public_transfer(admin_key, sender);
        transfer::public_transfer(publisher, sender);
        transfer::public_transfer(display, sender);
    }

    /// Create a new DevNet_NFT
    public entry fun mint(
        _: &AdminKey,
        name: vector<u8>,
        description: vector<u8>,
        rarity: vector<u8>,
        reaction: vector<u8>,
        image_url: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let nft = NFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            rarity: string::utf8(rarity),
            reaction: string::utf8(reaction),
            image_url: url::new_unsafe_from_bytes(image_url),
            url: url::new_unsafe_from_bytes(url)
        };
        let sender = tx_context::sender(ctx);
        event::emit(MintNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            // creator: sender,
            name: nft.name,
            description: nft.description,
            rarity: nft.rarity,
            reaction: nft.reaction,
            image_url: nft.image_url
            // url: nft.url,
        });
        transfer::public_transfer(nft, sender);
    }

    //create a admin key // TODO: could update
    public entry fun create_admin_key(_: &AdminKey, recipient: address, ctx: &mut TxContext) {  //_: &AdminKey, acces control with key
        let admin_key = AdminKey {
            id: object::new(ctx)
        };
        transfer::public_transfer(admin_key, recipient);
    }

    /// Update the `description` of `nft` to `new_description`
    public entry fun update_description( //TODO: DOESN'T WORK
        nft: &mut NFT,
        new_description: vector<u8>,
    ) {
        nft.description = string::utf8(new_description);
    }

    /// Permanently delete `nft`
    public entry fun burn(nft: NFT) {
        let NFT { id, name: _, description: _, reaction: _, rarity: _, image_url: _, url: _ } = nft;
        object::delete(id);
    }

    /// Get the NFT's `name`
    public fun name(nft: &NFT): &string::String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &NFT): &string::String {
        &nft.description
    }

    /// Get the NFT's `url`
    public fun url(nft: &NFT): &Url {
        &nft.url
    }

    /// Get the NFT's `image_url`
    public fun image_url(nft: &NFT): &Url {
        &nft.image_url
    }

    /// Get the NFT's `rarity`
    public fun rarity(nft: &NFT): &string::String {
        &nft.rarity
    }

    /// Get the NFT's `reaction`
    public fun reaction(nft: &NFT): &string::String {
        &nft.reaction
    }

    /// Get the NFT's `creator`
    // public fun creator(nft: &NFT): &address {
    //     &nft.creator
    // }

    // ------------------------- SETTERS --------------------------------

    // Set the NFT's `name`
    public entry fun set_name(_: &AdminKey, nft: &mut NFT, new_name: vector<u8>) {
        nft.name = string::utf8(new_name);
    }

    // Set the NFT's `description`
    public entry fun set_description(_: &AdminKey, nft: &mut NFT, new_description: vector<u8>) {
        nft.description = string::utf8(new_description);
    }

    // Set the NFT's `url`
    public entry fun set_url(_: &AdminKey, nft: &mut NFT, new_url: vector<u8>) {
        nft.url = url::new_unsafe_from_bytes(new_url);
    }

    // Set the NFT's `image_url`
    public entry fun set_image_url(_: &AdminKey, nft: &mut NFT, new_image_url: vector<u8>) {
        nft.image_url = url::new_unsafe_from_bytes(new_image_url);
    }

    // Set the NFT's `rarity`
    public entry fun set_rarity(_: &AdminKey, nft: &mut NFT, new_rarity: vector<u8>) {
        nft.rarity = string::utf8(new_rarity);
    }

    // Set the NFT's `reaction`
    public entry fun set_reaction(_: &AdminKey, nft: &mut NFT, new_reaction: vector<u8>) {
        nft.reaction = string::utf8(new_reaction);
    }

    // Set the NFT's `creator`
    // public entry fun set_creator(_: &AdminKey, nft: &mut NFT, new_creator: address) {
    //     nft.creator = new_creator;
    // }


  //TODO: TRANSFER POLIOCY

  
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