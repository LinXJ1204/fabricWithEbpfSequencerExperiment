# Running the test network

You can use the `./network.sh` script to stand up a simple Fabric test network. The test network has two peer organizations with one peer each and a single node raft ordering service. You can also use the `./network.sh` script to create channels and deploy chaincode. For more information, see [Using the Fabric test network](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html). The test network is being introduced in Fabric v2.0 as the long term replacement for the `first-network` sample.

If you are planning to run the test network with consensus type BFT then please pass `-bft` flag as input to the `network.sh` script when creating the channel. Note that currently this sample does not yet support the use of consensus type BFT and CA together.
That is to create a network use:
```bash
./network.sh up -bft
```

To create a channel use:

```bash
./network.sh createChannel -bft
```

To restart a running network use:

```bash
./network.sh restart -bft
```

Note that running the createChannel command will start the network, if it is not already running.

Before you can deploy the test network, you need to follow the instructions to [Install the Samples, Binaries and Docker Images](https://hyperledger-fabric.readthedocs.io/en/latest/install.html) in the Hyperledger Fabric documentation.

## Using the Peer commands

The `setOrgEnv.sh` script can be used to set up the environment variables for the organizations, this will help to be able to use the `peer` commands directly.

First, ensure that the peer binaries are on your path, and the Fabric Config path is set assuming that you're in the `test-network` directory.

```bash
 export PATH=$PATH:$(realpath ../bin)
 export FABRIC_CFG_PATH=$(realpath ../config)
```

You can then set up the environment variables for each organization. The `./setOrgEnv.sh` command is designed to be run as follows.

```bash
export $(./setOrgEnv.sh Org2 | xargs)
```

(Note bash v4 is required for the scripts.)

You will now be able to run the `peer` commands in the context of Org2. If a different command prompt, you can run the same command with Org1 instead.
The `setOrgEnv` script outputs a series of `<name>=<value>` strings. These can then be fed into the export command for your current shell.

## Chaincode-as-a-service

To learn more about how to use the improvements to the Chaincode-as-a-service please see this [tutorial](./test-network/../CHAINCODE_AS_A_SERVICE_TUTORIAL.md). It is expected that this will move to augment the tutorial in the [Hyperledger Fabric ReadTheDocs](https://hyperledger-fabric.readthedocs.io/en/release-2.4/cc_service.html)


## Orderers and Peers Host Number List

### Orderers

1. Orderer0
    * ORDERER_GENERAL_LISTENPORT = 7050
    * ORDERER_ADMIN_LISTENADDRESS = 7053
    * ORDERER_OPERATIONS_LISTENADDRESS = 7443
    * UDP_SERVER_LISTENPORT = 7073/udp

2. Orderer1
    * ORDERER_GENERAL_LISTENPORT = 8050
    * ORDERER_ADMIN_LISTENADDRESS = 8053
    * ORDERER_OPERATIONS_LISTENADDRESS = 8443
    * UDP_SERVER_LISTENPORT = 8073/udp

3. Orderer2
    * ORDERER_GENERAL_LISTENPORT = 9050
    * ORDERER_ADMIN_LISTENADDRESS = 9053
    * ORDERER_OPERATIONS_LISTENADDRESS = 9443
    * UDP_SERVER_LISTENPORT = 9073/udp
4. Orderer3
    * ORDERER_GENERAL_LISTENPORT = 10050
    * ORDERER_ADMIN_LISTENADDRESS = 10053
    * ORDERER_OPERATIONS_LISTENADDRESS = 10443
    * UDP_SERVER_LISTENPORT = 10073/udp
5. Orderer4
    * ORDERER_GENERAL_LISTENPORT = 11050
    * ORDERER_ADMIN_LISTENADDRESS = 11053
    * ORDERER_OPERATIONS_LISTENADDRESS = 11443
    * UDP_SERVER_LISTENPORT = 11073/udp


### Peers

1. peer0.org1.example.com
    * CORE_PEER_LISTENADDRESS = 12051
    * CORE_PEER_CHAINCODEADDRESS = 12052
    * CORE_OPERATIONS_LISTENADDRESS = 12444
2. peer1.org1.example.com
    * CORE_PEER_LISTENADDRESS = 13051
    * CORE_PEER_CHAINCODEADDRESS = 13052
    * CORE_OPERATIONS_LISTENADDRESS = 13444
3. peer3.org1.example.com
    * CORE_PEER_LISTENADDRESS = 14051
    * CORE_PEER_CHAINCODEADDRESS = 14052
    * CORE_OPERATIONS_LISTENADDRESS = 14444