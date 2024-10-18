export FABRIC_CFG_PATH=${PWD}/../../configs/configPeer

peer lifecycle chaincode package basic.tar.gz --path ../../../asset-transfer-basic/chaincode-go --lang golang --label basic_1.0
