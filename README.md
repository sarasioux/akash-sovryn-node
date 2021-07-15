# Akash Sovryn Node

Many thanks to this guy for creating a Youtube video that explained exactly how to do this bounty:
https://www.youtube.com/watch?v=Iinsjgolmu8&t=117s

I used his same deployment strategy, and added a few ideas of my own.

### How to prepare a Sovryn Node image

Clone this repository.
```
git clone https://github.com/sarasioux/akash-sovryn-node.git
```
Clone the Sovryn Node repository.
```
git clone https://github.com/DistributedCollective/Sovryn-Node.git
```
Copy the files **Dockerfile**, **accounts.js**, and **telegram.js** from akash-sovryn-node into Sovryn-Node.
```
cp akash-sovryn-node/Dockerfile Sovryn-Node/
cp akash-sovryn-node/accounts.js Sovryn-Node/
cp akash-sovryn-node/telegram.js Sovryn-Node/
```
Create a docker image and push it to Docker Hub.
```
cd Sovryn-Node/
docker build -t sovryn-node:latest .
docker push sovryn-node:latest
```
Edit the included yaml file to point to your wallets and telegram bot.

Follow the instructions to deploy an Akash container using the included yaml file.
https://docs.akash.network/guides/deployment

### How to Deploy on Akash

Go back to our akash-sovryn-node repository.
```
cd ../akash-sovryn-node/
```

Set a bunch of environment variables.  Change *alice* to whatever you want.

```
export AKASH_NET="https://raw.githubusercontent.com/ovrclk/net/master/mainnet"
export AKASH_VERSION="$(curl -s "$AKASH_NET/version.txt")"
export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")"
export AKASH_NODE="$(curl -s "$AKASH_NET/rpc-nodes.txt" | head -1)"
export AKASH_KEYRING_BACKEND=os
export AKASH_KEY_NAME=alice
```

Create a new account and add it to the key ring.  Make sure you save the mnemonic key that it returns.

```
akash --keyring-backend "$AKASH_KEYRING_BACKEND" keys add "$AKASH_KEY_NAME"
export AKASH_ACCOUNT_ADDRESS="$(akash keys show $AKASH_KEY_NAME -a)"
```

Visit https://docs.akash.network/guides/funding to learn how to get some seed funding.

You can't create a certificate (the next step) until your account is funded.

Generate a deployment certificate for your account.

```
akash tx cert create client --chain-id $AKASH_CHAIN_ID --keyring-backend $AKASH_KEYRING_BACKEND --from $AKASH_KEY_NAME --node $AKASH_NODE --fees 5000uakt
```

Generate a deployment.

```
akash tx deployment create deploy.yml --from $AKASH_KEY_NAME --node $AKASH_NODE --chain-id $AKASH_CHAIN_ID --fees 5000uakt -y
```

From the response, capture the values for **dseq**, **oseq**, and **gseq** from the raw_log section of the response.

```
# Remember to change these numbers to match
export AKASH_DSEQ=1361904
export AKASH_OSEQ=1
export AKASH_GSEQ=1
```
Verify the order is open.
```
akash query market order get --node $AKASH_NODE --owner $AKASH_ACCOUNT_ADDRESS --dseq $AKASH_DSEQ --oseq $AKASH_OSEQ --gseq $AKASH_GSEQ
```
View your bids.
```
akash query market bid list --owner=$AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE --dseq $AKASH_DSEQ
```
Choose a provider from the bid list and create a lease.
```
export AKASH_PROVIDER=akash10cl5rm0cqnpj45knzakpa4cnvn5amzwp4lhcal
akash tx market lease create --chain-id $AKASH_CHAIN_ID --node $AKASH_NODE --owner $AKASH_ACCOUNT_ADDRESS --dseq $AKASH_DSEQ --gseq $AKASH_GSEQ --oseq $AKASH_OSEQ --provider $AKASH_PROVIDER --from $AKASH_KEY_NAME --fees 5000uakt
```
Check the status of your lease.
```
akash query market lease list --owner $AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE --dseq $AKASH_DSEQ
```
Send the manifest to your provider.
```
akash provider send-manifest deploy.yml --node $AKASH_NODE --dseq $AKASH_DSEQ --provider $AKASH_PROVIDER --home ~/.akash --from $AKASH_KEY_NAME
```
Wait a few minutes, then get the URL to your new deployment.
```
akash provider lease-status --node $AKASH_NODE --home ~/.akash --dseq $AKASH_DSEQ --from $AKASH_KEY_NAME --provider $AKASH_PROVIDER
```
Put that URL into your browser, and you'll see a working Sovryn Node!

Note that the URL shows a 502 error until the node has fully booted up.
