# Solana Simple TX Signer

> [!WARNING]  
> This code isn't audited. Please review it yourself before use, it is only 80 lines.

This is a bare-bones tool to sign raw Solana transaction messages with a keyfile.

It was build during the Solana Governance votes for SIMD-0123 and SIMD-0228, which require signing a merkle-claim transaction with the validator-identity key. This validator-identity-key is oftentimes also the vote-key.

We didn't want to accidentally leak this key, so build a very minimal program with few dependencies, that takes an already constructed message, signs it, and sends it to the chain.

We then patched the original merkle-claim CLI to NOT sign and submit the transaction it assembles, but prints it in base58 to stdout.

We could then take that to another system, and sign there. Note that the blockhash is easily replacable! That means there is no 2-minute timeout or anything, you have all the time in the world here.

## Usage

First, you need to grab yourself a base58-encoded `solana_sdk::message::Message` that you want to sign. Most tools don't provide this, so you'll likely have to apply a small patch.

We have done this for the [solgov-distributor](https://github.com/laine-sa/solgov-distributor/blob/master/cli/src/bin/cli.rs) here: https://github.com/neodyme-labs/solgov-distributor/commit/3c7f71ec3a600a55287f21b6cbf364972e5a14b1

With this patch, you can simply specify a pubkey in place of the keypair-file:

```
# in solgov-distributor (with patch applied, change out our validator key for your own!)

cargo run --bin cli -- --rpc-url https://api.mainnet-beta.solana.com --airdrop-version 0 --keypair-path NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr --mint s3262ckXrLnzPXG8RScfFAYWDQzZYgnr4vo1R2SboMW --program-id mERKcfxMC5SqJn4Ld4BUris3WKZZ1ojjWJ3A3J5CKxv claim --merkle-tree-path ./votes/simd0326/simd326-merkle-tree.json
```

This will give you a serialized transaction message like this:

```
T6Z6yDpwWu9sjAMdHZ7DPSFrA1K7t8PkQqsTLNwUsQf1aN6zhRijv9VbfuNgWtxVtoXYQh1QNYpwFCr43w7hLrDfFpoz26dSkH936yj4W7YioRfzsvkQoAGkwb9iq9qxNfPVHDQQNymmE4B4amSLJwrfWe1B4vndUq3QXPJ3AM3hBnq74RfC6JdjfNiTQDoxP1Vov2oCwCznWG6XgpMSq5RHtKrfNVDVZRkDKh1JKgg6GbySjpjcJEamAJ8qNUe4VfPiqLbfcznkRsG96TUyNYC9AED5DixyuMGmYfsQL2mSKcn4xUPTWdkVPmnX7sMhAgzZGKXddJsWUR3MBdpBgnfe6fm1wg7WtmuXvhts25MdX2x2at4sQ1dQA1YQMYz6sJvJkSRcYXVgJxXNP9n4FsZkfXKQxXxWYPbhThED1g8bkxJsZZEjGDXzad7J85o8K2Lp4mQ4yajgJhfGdwzjehTX6TX8kKajNVi75N3MdHrXCao1cKi7WKRTXWKZgC3mF2Q3nVLPdRG8LwtwANGMxeNtqTbksTXLPT1EvZ9s6AoUgCcyCUWDBbvQh1r8kumrA6DR9NtaedyPNZLrHequvJDSPU3ZZRWGRufPuKkFVeD1Mwf24m4NXdWzkyfZmfhfDaGvpHnCcE2rAhJ17TY5N1EpCtUc6QxBAA77vPUCfNhSqRwZGRnN7RSb94mHmg6NCviyaUusabUb3Z4WpTEjzzWqJoeTuXykGgNwGXHiKku1BJtefgWNUWiHNJC8jSuq3zmiCVaSMTcHAwZZUapERJbBFnxi99p7gzpoP7eHitSvxLtM1P9ncmcfWAipgAc8iXCsT6kZuzXEqhbxT74PE1zkd71mRgmrfteASqmugkHjB8kxo956xgydBZ5FU1NioGpdEWuDNYjCFZBumiLEyJVwcK59wGSX8Uv3m1f9VMNHQg7kQ6n6EbJSsr2XXT5p6P9kG8qaBEnjCYrmghJrBgFibW9MTGWCbNsjufY6PsKfeLyLEpGnZ8xKJ5ZhbqRzxkg8fVzZF2
```

You can simulate that message using the solana explorer's "Inspector": https://explorer.solana.com/tx/inspector.
If your satisfied, you can then we can sign this message with this tool:

```sh
cargo run -- --keyfile mykey.json --message $STRING_FROM_ABOVE 
```

It will show all signer, *toplevel* programs, and pretty-print the TX. Verify to your hearts content, remember: no timelimit!

Example:

```
Transaction message contains 2 instruction(s).
Signers: [NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr]
Programs: [ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL, mERKcfxMC5SqJn4Ld4BUris3WKZZ1ojjWJ3A3J5CKxv]
Transaction details:
Version: legacy
Recent Blockhash: 11111111111111111111111111111111
Signature 0: 1111111111111111111111111111111111111111111111111111111111111111
Account 0: srw- NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr (fee payer)
Account 1: -rw- 7dVKzug254scVZrQX7iS5PoPfosyq6uJYeJ36eV9h8nm
Account 2: -rw- DhqFawrswsXLa63MdG6c6i5f2g2NfyT4jrHY9HRjndh4
Account 3: -rw- EPBYDKEvd3EW85qPSdjm4HAQ9utYjVmVQ9jzKUuT4sHY
Account 4: -rw- GfyW5RdUWhVGBtyVyDyZ7EYWs7T6RkNCESXKnHj3cdxB
Account 5: -r-- 11111111111111111111111111111111
Account 6: -r-- TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
Account 7: -r-x mERKcfxMC5SqJn4Ld4BUris3WKZZ1ojjWJ3A3J5CKxv
Account 8: -r-- s3262ckXrLnzPXG8RScfFAYWDQzZYgnr4vo1R2SboMW
Account 9: -r-x ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL
Instruction 0
  Program:   ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL (9)
  Account 0: NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr (0)
  Account 1: GfyW5RdUWhVGBtyVyDyZ7EYWs7T6RkNCESXKnHj3cdxB (4)
  Account 2: NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr (0)
  Account 3: s3262ckXrLnzPXG8RScfFAYWDQzZYgnr4vo1R2SboMW (8)
  Account 4: 11111111111111111111111111111111 (5)
  Account 5: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA (6)
  Data: [0]
Instruction 1
  Program:   mERKcfxMC5SqJn4Ld4BUris3WKZZ1ojjWJ3A3J5CKxv (7)
  Account 0: 7dVKzug254scVZrQX7iS5PoPfosyq6uJYeJ36eV9h8nm (1)
  Account 1: EPBYDKEvd3EW85qPSdjm4HAQ9utYjVmVQ9jzKUuT4sHY (3)
  Account 2: DhqFawrswsXLa63MdG6c6i5f2g2NfyT4jrHY9HRjndh4 (2)
  Account 3: GfyW5RdUWhVGBtyVyDyZ7EYWs7T6RkNCESXKnHj3cdxB (4)
  Account 4: NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr (0)
  Account 5: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA (6)
  Account 6: 11111111111111111111111111111111 (5)
  Data: [78, 177, 98, 123, 210, 21, 187, 83, 40, 129, 52, 205, 196, 248, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 99, 2, 36, 53, 213, 90, 36, 60, 75, 235, 15, 93, 189, 6, 25, 61, 162, 200, 32, 194, 220, 40, 255, 205, 44, 166, 175, 51, 241, 17, 68, 230, 138, 129, 226, 155, 254, 250, 126, 175, 202, 200, 79, 196, 99, 124, 128, 97, 64, 221, 172, 101, 132, 232, 148, 13, 10, 85, 198, 162, 141, 66, 129, 52, 74, 143, 31, 17, 162, 203, 81, 212, 233, 197, 241, 233, 90, 98, 71, 154, 237, 182, 1, 229, 215, 205, 218, 170, 231, 251, 126, 143, 22, 198, 149, 15, 180, 6, 82, 4, 68, 5, 223, 158, 216, 235, 101, 44, 227, 112, 91, 157, 51, 235, 202, 188, 52, 93, 106, 159, 192, 207, 2, 187, 1, 223, 19, 131, 106, 137, 94, 223, 199, 90, 241, 205, 253, 167, 13, 175, 81, 161, 127, 151, 24, 143, 172, 84, 246, 154, 249, 239, 235, 8, 200, 34, 130, 220, 129, 107, 184, 162, 219, 103, 193, 215, 254, 3, 10, 16, 179, 215, 86, 186, 187, 169, 138, 223, 154, 83, 231, 81, 114, 209, 118, 20, 95, 162, 212, 211, 119, 253, 121, 72, 15, 148, 55, 97, 45, 64, 36, 169, 169, 51, 67, 67, 129, 71, 189, 65, 44, 158, 212, 248, 95, 242, 134, 117, 127, 243, 212, 4, 84, 30, 124, 32, 172, 20, 232, 42, 6, 163, 194, 11, 154, 181, 126, 214, 19, 177, 157, 27, 233, 51, 130, 150, 236, 170, 92, 71, 121, 91, 65, 1, 76, 84, 232, 103, 203, 180, 233, 241, 129, 215, 154, 135, 114, 143, 211, 49, 85, 42, 60, 1, 90, 123, 17, 176, 65, 153, 139, 90, 91, 204, 179, 87, 123, 5, 128, 77, 3, 193, 242, 123, 65, 211, 176, 57, 155, 26, 73, 243, 20, 80, 91, 158, 81, 165, 233, 238, 158, 203, 22, 56, 179, 112, 17, 224, 28, 254, 154, 238, 73, 17, 74, 63, 35, 99, 243, 65, 13, 94, 65, 157, 44, 244, 130, 250, 243, 160, 167, 35, 154, 121, 97, 235, 214, 210, 106, 66, 8, 85]
Status: Unavailable

Does the TX look good? (yes/no): yes
Loaded keypair for NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr
Successfully sent transaction with signature 3gYx4eZ9ysMcYidmfYyEVwazWvZL4kKcrs3dzzXQ4GArhLbE7G6USJ5VyEgZLW51a86cbH43TD7u8KRLsvQULv2
```

Enter yes, and it will sign and send the transaction to the network. (or show an error if the signer does not match)


## How to patch other tools to output messages instead of sending them

The patch to solgov-distributor boils down to replacing

```rust
let blockhash = client.get_latest_blockhash().unwrap();
let tx =
    Transaction::new_signed_with_payer(&ixs, Some(&claimant.key()), &[&keypair], blockhash);

let signature = client
    .send_and_confirm_transaction_with_spinner(&tx)
    .unwrap();
```

with

```rust
let msg = solana_sdk::message::Message::new(&ixs, Some(&claimant.key()));
let msg_b58: String = solana_sdk::bs58::encode(msg.serialize()).into_string();
println!("Message: {}", msg_b58);
```

And remove the keypair file parsing, using a hardcoded pubkey as claimant. 

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.