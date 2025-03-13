# Solana Simple TX Signer

> [!WARNING]  
> This code isn't audited. Please review it yourself before use, it is only 80 lines.

This is a bare-bones tool to sign raw Solana transaction messages with a keyfile.

It was build during the Solana Governance votes for SIMD-0123 and SIMD-0228, which require signing a merkle-claim transaction with the validator-identity key. This validator-identity-key is oftentimes also the vote-key.

We didn't want to accidentally leak this key, so build a very minimal program with few dependencies, that takes an already constructed message, signs it, and sends it to the chain.

We then patched the original merkle-claim CLI to NOT sign and submit the transaction it assembles, but prints it in base58 to stdout.

We could then take that to another system, and sign there. Note that the blockhash is easily replacable! That means there is no 2-minute timeout or anything, you have all the time in the world here.

## Usage

First, you need to grab yourself a base58-encoded `solana_sdk::message::Message` that you want to sign. Most tools don't provide this, so you'll likely have to apply a small patch. For example, for the [solgov-distributor](https://github.com/laine-sa/solgov-distributor/blob/master/cli/src/bin/cli.rs), replace:

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

And remove the keypair file parsing, using a hardcoded pubkey as claimant. This will give you a serialized transaction message like this:

```
T6Z6yDpwWu9sjAMdHZ7DPSFrA1K7t8PkQqsTLNwUsQf1aN6zXrodD6uD1nuPY1KmhWsaqPnFLqsgt2VtnjxnzfER6646nNwTEZfwBGB733HaAoWywhwzaafS1fLcTHFfqzydKzd6X3Knzx4WfPXJ2Z8GEbq8m1pSYTnAmAhu7fHMAyn3YxjAn3vjD5wgrheCShSocXVF8MCuzKBAfmmSM9ibcR8V4hJqYkTjxYDczSsGeogzsuSxKFaPcDNNJo2r8wCSqJFm3mVJeN8t94jnV8HqrrQxV6g7YGhsdjmbNfnFHtVQehoMFQpAi84SmeuStwQsKvgYuJBskXEScFqpc4mgjJDznoLEVAiAAkHhCmQ7W1iCYLZ8VyvAu9w82A529deaE1pXeX8tJdzjZ28zWSoSz1ydJghPJr8AYBeAWFVuCd2JirXpfuTeMVRHuGqrVMUawzSFcJCknWrpp7tQWW2QavJ7KRAEHtRUU2E4bkTmCbSuXdCZ4dJvULCK2zeLN458b9TLJ1vXRnN6gAu7eF6uM85ntuyZ4hPXurCLeYNYXDpy7o4AXa866ssikZstUwsEbZuZoQvJwphXZjQRu6S46FnU3aUfuYnT7CjpSruxwrbNhXYHozjsxz8Xszz6pZUpeE9tVQvZyFfKKUEjSErc3jFPCCnYzw9K83bbj9VjGWoijaZGWER4YCrbXyWQRzdk8oSN6jjQmnsv9brMJMfB8mmD6XZYgL2kfxpQ7u4iWheRfQXc1oerpfCSFENz9UwsjUWKxMseDayZ3yQ7zQAZHrjanobWmHh494ipiEmumSjXXsRGzAyWjYXFoemQsUCsDrrvsZnoGgm1gPN6XqodFX6tAD75PY9kFwaZnxG5m6NJP8jyd5vVihsgG12scGWVnYEdteCWiKotZmSAYXQsQukDdrv5vMg1HwcCMMYiUZqtvtc1CFz5Dt658wT3o3Wf8fNWc9wLykuhjusUg1rG8UUWJsDzapgoaFTjWZ3Cgr3725YXm1jHPUDM2XdqhrSav1xBqb
```

Then we can sign this message with this tool:

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
Account 1: -rw- 4r7udQQFMwEw2fMu5br9j8cZrstQ27YfE3MGyT7rKaiG
Account 2: -rw- 66XwHpfLXw9e3LELmU3C3UFnTMYTFxmaK2d3YD6r7X6v
Account 3: -rw- FRp8ZooCqLTnGFa1CP7KCuD4VEmAEefpFDXvuqmxyYR5
Account 4: -rw- GJ2cgZ4AEKu6q1xq38DLkUf7HD2qYs2zScBELAqQSCwy
Account 5: -r-- 11111111111111111111111111111111
Account 6: -r-- TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
Account 7: -r-x mERKcfxMC5SqJn4Ld4BUris3WKZZ1ojjWJ3A3J5CKxv
Account 8: -r-- s228VmFcuiEfroSCQTvEp1pYUownL7JRZMTd7FqHJVK
Account 9: -r-x ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL
Instruction 0
  Program:   ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL (9)
  Account 0: NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr (0)
  Account 1: 66XwHpfLXw9e3LELmU3C3UFnTMYTFxmaK2d3YD6r7X6v (2)
  Account 2: NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr (0)
  Account 3: s228VmFcuiEfroSCQTvEp1pYUownL7JRZMTd7FqHJVK (8)
  Account 4: 11111111111111111111111111111111 (5)
  Account 5: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA (6)
  Data: [0]
Instruction 1
  Program:   mERKcfxMC5SqJn4Ld4BUris3WKZZ1ojjWJ3A3J5CKxv (7)
  Account 0: FRp8ZooCqLTnGFa1CP7KCuD4VEmAEefpFDXvuqmxyYR5 (3)
  Account 1: GJ2cgZ4AEKu6q1xq38DLkUf7HD2qYs2zScBELAqQSCwy (4)
  Account 2: 4r7udQQFMwEw2fMu5br9j8cZrstQ27YfE3MGyT7rKaiG (1)
  Account 3: 66XwHpfLXw9e3LELmU3C3UFnTMYTFxmaK2d3YD6r7X6v (2)
  Account 4: NdMV1C3XMCRqSBwBtNmoUNnKctYh95Ug4xb6FSTcAWr (0)
  Account 5: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA (6)
  Account 6: 11111111111111111111111111111111 (5)
  Data: [78, 177, 98, 123, 210, 21, 187, 83, 100, 225, 94, 226, 50, 101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 104, 182, 160, 150, 169, 127, 101, 245, 186, 127, 183, 29, 126, 157, 213, 136, 137, 194, 86, 92, 196, 161, 197, 155, 224, 124, 109, 24, 68, 216, 22, 107, 206, 72, 143, 77, 115, 134, 98, 76, 249, 59, 51, 173, 151, 72, 188, 142, 240, 76, 63, 6, 142, 137, 16, 12, 140, 208, 61, 158, 157, 173, 232, 206, 119, 67, 236, 90, 92, 120, 153, 40, 53, 193, 214, 55, 125, 97, 96, 2, 91, 136, 189, 47, 28, 49, 100, 33, 77, 156, 4, 199, 253, 243, 202, 233, 100, 159, 165, 102, 82, 194, 128, 220, 219, 141, 129, 117, 13, 96, 200, 27, 108, 78, 128, 88, 16, 141, 0, 238, 221, 235, 33, 39, 245, 85, 15, 100, 15, 107, 63, 92, 248, 209, 201, 237, 209, 59, 86, 92, 250, 38, 247, 210, 118, 164, 226, 55, 35, 248, 88, 152, 30, 224, 67, 236, 195, 124, 109, 42, 208, 37, 8, 25, 187, 139, 196, 145, 70, 63, 104, 33, 175, 156, 186, 122, 131, 43, 34, 101, 48, 213, 26, 217, 166, 72, 147, 136, 38, 104, 124, 144, 118, 94, 189, 55, 236, 45, 101, 133, 86, 182, 193, 83, 51, 204, 10, 220, 34, 239, 238, 6, 17, 183, 56, 5, 88, 98, 44, 19, 46, 111, 76, 193, 228, 208, 85, 113, 152, 141, 211, 197, 182, 236, 2, 228, 44, 96, 31, 208, 111, 0, 49, 203, 229, 1, 129, 183, 148, 58, 107, 191, 168, 245, 156, 44, 231, 205, 241, 24, 174, 195, 191, 14, 199, 215, 20, 199, 208, 26, 128, 118, 124, 9, 248, 182, 133, 229, 183, 224, 81, 23, 30, 202, 10, 16, 43, 131, 53, 111, 236, 107, 77, 141, 216, 196, 254, 222, 164, 74, 70, 44, 108, 23, 173, 105, 0, 228, 129, 56, 227, 35, 63, 231, 40, 106, 180, 40, 12, 63, 35, 145, 130, 101, 214, 163, 167, 172, 199, 202, 73, 69, 4, 139, 139, 95, 188, 232, 169, 102, 234, 121, 60, 230, 135, 218, 82, 148, 29, 157, 188, 226]
Status: Unavailable

Does the TX look good? (yes/no): 
```

Enter yes, and it will sign and send the transaction to the network. (or show an error if the signer does not match)

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.