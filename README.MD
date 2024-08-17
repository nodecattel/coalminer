## Disclaimer 👷‍♂️

This code is experimental and provided "as is", without warranty of any kind. Use it at your own risk. It's under development, and its features may change. Always back up your data before use. Contributions and feedback are welcome.

The script automates the setup and running of the Coal CLI for $COAL mining operations on Soylana Manlet, ensuring you're always running the latest version and simplifying the mining setup process.


$COAL (V2) token address `E3yUqBNTZxV8ELvW99oRLC7z4ddbJqqR4NphwrMug9zu`

## Quick Start 🛠️

To get started with the Ore Miner Auto Script, clone this repository to your local machine using the following command:

```bash
git clone https://github.com/nodecattel/coalminer.git
cd oreminer
```

### Prerequisites ✅

Before running the script, ensure you have the following installed:

- Rust and Cargo (The script will attempt to install these if they're not present)
- Solana CLI (Also installed by the script if not present)
- (Recommended) Private RPC endpoints for fast & secure mining hash submission. You can use our referal link for [Quicknode here](https://www.quicknode.com/?via=nodecattel)
### Give permission for script become executable

```bash
chmod +x install.sh coal.sh upgrade.sh
```
### Installation 💻

Navigate to the cloned repository directory and run the `install.sh` script to set up the necessary components:

```bash
./install.sh
```
We have added few options for installation which has `mainnet (official coal-cli)`and `panda optimized cores (JustPandaEver fork)`

Follow the on-screen instructions to complete the installation. The script will:

- Install Rust and Cargo
- Install the Solana CLI
- Create New Wallet if not exist : !!! note down your SEED PHRASE !!!
- Install and update the Coal CLI to the latest version
- Set executable permissions for `coal.sh`
- Optionally run `coal.sh` for further setup

### Running Coal Miner ⛏️

Fund your wallet with some sol

Show solana address on your machine : locate at $HOME/.config/solana/id.json
```
solana address
```

After installation, fund your wallet and you can start the mining process by running:
### Solo mining with your machine
```bash
./coal.sh mine
```

### Pool mining with Alvarium mine pool - not available yet
```bash
./coal.sh pool
```
See all available commands

```
./coal.sh
```

Upgrade COAL-CLI version
```
./upgrade.sh
```

### COALCULATOR Setup & Usage 🧮
Here’s a snapshot of the COALCULATOR in action:

![ORECULATOR Snapshot]
To install the required packages for cal.py:

```bash
sudo apt install python3-pip &&
pip install -r requirements.txt
```

Then, run the COALCULATOR with:

```bash
./cal.py
```

### Change default variable config manually

To change your setting please set up in `coal.conf` located at `$HOME/.coal`
```bash
cd $HOME/.coal
nano coal.conf
```
### Export Private key to external wallet
```bash
cat $HOME/.config/solana/id.json
```
Then copy the output to your external wallet like Phantom, Backpack

### Useful Links

Coal Cli's creates

```
https://crates.io/crates/coal-cli
```

Official Coal-Cli repository

```
https://github.com/coal-digital/coal-cli
```

`$COAL` Price chart

```
https://github.com/coal-digital/coal-cli
```


If you find values to the scripts here please [Follow NodeCattel on X](https://twitter.com/nodecattel)
