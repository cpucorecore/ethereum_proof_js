const {RobustWeb3} = require("./rainbow/robust");
const {
    EthProofExtractor,
} = require('./eth-proof-extractor')
const utils = require('ethereumjs-util')
const { Header, Proof, Receipt, Log } = require('eth-object')

let lockedEvent = {
    transactionHash: '0xc008be9258da8b4c1da836caa5adbded5837cea7532dd52a2de37b860b0d22a3',
    logIndex: 0
}

let ethNodeURL = 'http://localhost:8545'
const extractor = new EthProofExtractor()
extractor.initialize(ethNodeURL)

extractorFunc = async() => {
    let robustWeb3 = new RobustWeb3(ethNodeURL)
    let web3 = robustWeb3.web3

    const receipt = await extractor.extractReceipt(lockedEvent.transactionHash)
    const block = await extractor.extractBlock(receipt.blockNumber)
    const tree = await extractor.buildTrie(block)
    const proof = await extractor.extractProof(
        web3,
        block,
        tree,
        receipt.transactionIndex
    )
    let txLogIndex = -1

    let logFound = false
    let log
    for (let receiptLog of receipt.logs) {
        txLogIndex++
        const blockLogIndex = receiptLog.logIndex
        if (blockLogIndex === lockedEvent.logIndex) {
            logFound = true
            log = receiptLog
            break
        }
    }
    if (logFound) {
        //header rlp
        console.log(`header RLP: [${proof.header_rlp.toString('hex')}]`)
        //receipt rlp
        console.log(`receipt RLP: [${Receipt.fromWeb3(receipt).serialize().toString('hex')}]`)
        //log rlp
        console.log(`log RLP: [${Log.fromWeb3(log).serialize().toString('hex')}]`)
        //proof rlp
        proof.receiptProof[0].forEach(function(value, i) {
            console.log(value.toString('hex'))
        })
    } else {
        console.log(`Failed to find log for event ${lockedEvent}`)
    }
}

extractorFunc().then(r => console.log(r));