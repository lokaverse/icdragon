# IC Dragon

IC Dragon is a dice-roll game powered by ICP on-chain Randomizer
This game is a testament to how provably secure randomness can be achieved fully on-chain on ICP — a follow-up to Jan Camenisch's tweet here.

## Game Play

1. Connect wallet and get a new wallet address auto generated for you.
2. Transfer some ICP to your new wallet address.
3. Buy ticket and roll the dice!

Use Claim if you win to redeem your prize.

Use Withdraw if you want to transfer out your ICP to your main wallet or exchange.

## Installation

1. Make sure you have nodejs installed
2. Download and setup IC SDK on Mac / Linux (or Windows with WSL2)
3. Copy or clone this repository to your local dev, go to the directory and start dfx

```bash
$ dfx start --background

```

4. Deploy (Now here is quite tricky part, where you have to set ICdragon canister as EYES token minter)
   a. Deploy local EYES token but with a false name, e,g TEMPEEYES

```bash
$ export MINTER = $(dfx identity get-principal)

$ dfx deploy tempeeyes  --argument "(variant {Init =
record {
     token_symbol = \"TEYES\";
     token_name = \"TEYES\";
     minting_account = record { owner = principal \"${MINTER}\" };
     transfer_fee = 10;
     metadata = vec {};
     feature_flags = opt record{icrc2 = true};
     initial_balances = vec { record { record { owner = principal \"${MINTER}\"; }; 1000000000000; }; };
     archive_options = record {
         num_blocks_to_archive = 1000;
         trigger_threshold = 2000;
         controller_id = principal \"${MINTER}\";
         cycles_for_archive_creation = opt 10000000000000;
     };
 }
})"

```

b. Deploy ICDragon, with dependency to EYES token above

```bash
   $ dfx deploy tempeeyes  --argument "(variant {Init =
record {
     token_symbol = \"TEYES\";
     token_name = \"TEYES\";
     minting_account = record { owner = principal \"${MINTER}\" };
     transfer_fee = 10;
     metadata = vec {};
     feature_flags = opt record{icrc2 = true};
     initial_balances = vec { record { record { owner = principal \"${MINTER}\"; }; 1000000000000; }; };
     archive_options = record {
         num_blocks_to_archive = 1000;
         trigger_threshold = 2000;
         controller_id = principal \"${MINTER}\";
         cycles_for_archive_creation = opt 10000000000000;
     };
 }
})"

dfx deploy icdragon  --argument "(record{admin = principal \"${MINTER}\"})"
```

c. Deploy another EYES token, this time proper name, with ICDragon canister ID as the minter

```bash
   $ dfx deploy eyes  --argument "(variant {Init =
record {
     token_symbol = \"EYES\";
     token_name = \"EYES\";
     minting_account = record { owner = principal \"br5f7-7uaaa-aaaaa-qaaca-cai\" };
     transfer_fee = 10;
     metadata = vec {};
     feature_flags = opt record{icrc2 = true};
     initial_balances = vec { record { record { owner = principal \"br5f7-7uaaa-aaaaa-qaaca-cai\"; }; 1000000000000; }; };
     archive_options = record {
         num_blocks_to_archive = 1000;
         trigger_threshold = 2000;
         controller_id = principal \"br5f7-7uaaa-aaaaa-qaaca-cai\";
         cycles_for_archive_creation = opt 10000000000000;
     };
 }
})"

dfx deploy icdragon  --argument "(record{admin = principal \"${MINTER}\"})"
```

d. Remove dependency to the first temporary EYES token, then update the code on ICDragon and its dependency to the proper EYES token
e. Upgrade ICDragon 5. Set the ticket Price (optional) 6. Start the first game

## Documentation

Coming soon

## Roadmap

- [Q1 2024] Alpha Launch + $EYES token reward
- [Q2 2024] (REDACTED) launch
- [Q3 2024] we'll see

## License

This project is licensed under the GNU 3 license

## References

- [Internet Computer](https://internetcomputer.org)
