export FABRIC_CFG_PATH=${PWD}/../../configs/configPeer
export channel_name=mychannel
export CORE_PEER_TLS_ENABLED=true
export PEER0_ORG1_CA=${PWD}/../../organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/../../organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:12051

peer lifecycle chaincode install basic.tar.gz