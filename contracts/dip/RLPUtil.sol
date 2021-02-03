pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "https://github.com/hamdiallam/Solidity-RLP/blob/v2.0.3/contracts/RLPReader.sol";
import "https://github.com/bakaoh/solidity-rlp-encode/blob/master/contracts/RLPEncode.sol";

library RLPUtil {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    struct Header {
        bytes parent_hash;
        bytes uncles_hash;
        address author;
        bytes state_root;
        bytes transactions_root;
        bytes receipts_root;
        bytes log_bloom;
        bytes difficulty;
        uint number;
        uint gas_limit;
        uint gas_used;
        uint timestamp;
        bytes extra_data;
        bytes mix_hash;
        uint nonce;
    }

    function DecodeHeader(bytes memory header_data) public pure returns (Header memory) {
        Header memory header;

        RLPReader.RLPItem[] memory items = header_data.toRlpItem().toList();
        require(items.length == 15 || items.length == 13);

        header.parent_hash = items[0].toBytes();
        header.uncles_hash = items[1].toBytes();
        header.author = items[2].toAddress();
        header.state_root = items[3].toBytes();
        header.transactions_root = items[4].toBytes();
        header.receipts_root = items[5].toBytes();
        header.log_bloom = items[6].toBytes();
        header.difficulty = items[7].toBytes();
        header.number = items[8].toUint();
        header.gas_limit = items[9].toUint();
        header.gas_used = items[10].toUint();
        header.timestamp = items[11].toUint();

        return header;
    }

    struct LogEntry {
        address addr;
        bytes32[] topices;
        bytes data;
    }

    function DecodeLogEntry(bytes memory log_entry_data) public pure returns (LogEntry memory) {
        LogEntry memory logEntry;

        RLPReader.RLPItem[] memory items = log_entry_data.toRlpItem().toList();
        require(items.length == 3);

        logEntry.addr = items[0].toAddress();

        RLPReader.RLPItem[] memory topicesItems = items[1].toList();
        bytes32[] memory topices = new bytes32[](topicesItems.length);
        for(uint i=0; i<topicesItems.length; i++) {
            bytes memory sd = topicesItems[i].toBytes();
            bytes32 dd;
            assembly {
                dd := mload(add(sd, 32))
            }
            topices[i] = dd;
        }
        logEntry.topices = topices;

        logEntry.data = items[2].toBytes();

        return logEntry;
    }

    struct Receipt {
        bool status;
        uint gas_used;
        bytes log_bloom;
        LogEntry[] logs;
    }

    // test data: 0xf901bd01825bf8b9010000000000000000000000000800000000000000000000000000200000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000401000000000000000000000000000000000000000000000000000000000000000f8b4f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a02a056365f90644ba02872f61a1ad37613f47bba498327650b0b3ac40677e66c4a00000000000000000000000000000000000000000000000000000000000000064f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a0f81f8171d13ab9fef6d56dec96341eba6a5265cec2002c22bbadc5f19d219720a00000000000000000000000000000000000000000000000000000000000000065
    function DecodeReceipt(bytes memory receipt_data) public returns (Receipt memory) {
        Receipt memory receipt;

        RLPReader.RLPItem[] memory items = receipt_data.toRlpItem().toList();
        require(items.length == 4);

        receipt.status = items[0].toBoolean();
        receipt.gas_used = items[1].toUint();
        receipt.log_bloom = items[2].toBytes();

        RLPReader.RLPItem[] memory logItems = items[3].toList();
        if (logItems.length == 0) {
            return receipt;
        }

        LogEntry[] memory logs = new LogEntry[](logItems.length);
        for(uint i=0;i<logItems.length;i++) {
            bytes[] memory cache = new bytes[](1);
            cache[0] = logItems[i].toBytes();
            bytes memory logEntryHex = RLPEncode.encodeList(cache);
            LogEntry memory logEntry = DecodeLogEntry(logEntryHex);
            logs[i] = logEntry;
        }
        receipt.logs = logs;

        return receipt;
    }

    // proof: ["0x2080", "0xf901bd01825bf8b9010000000000000000000000000800000000000000000000000000200000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000401000000000000000000000000000000000000000000000000000000000000000f8b4f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a02a056365f90644ba02872f61a1ad37613f47bba498327650b0b3ac40677e66c4a00000000000000000000000000000000000000000000000000000000000000064f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a0f81f8171d13ab9fef6d56dec96341eba6a5265cec2002c22bbadc5f19d219720a00000000000000000000000000000000000000000000000000000000000000065"]
    // proof arrary RLP encoded by ethereum RLP library: 0xf901ccb901c9f901c6822080b901c0f901bd01825bf8b9010000000000000000000000000800000000000000000000000000200000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000401000000000000000000000000000000000000000000000000000000000000000f8b4f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a02a056365f90644ba02872f61a1ad37613f47bba498327650b0b3ac40677e66c4a00000000000000000000000000000000000000000000000000000000000000064f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a0f81f8171d13ab9fef6d56dec96341eba6a5265cec2002c22bbadc5f19d219720a00000000000000000000000000000000000000000000000000000000000000065
    function DecodeProof(bytes memory RLPProof) public pure returns (bytes[] memory empty) {
        RLPReader.RLPItem[] memory items = RLPProof.toRlpItem().toList();
        if (items.length == 0) return empty;

        bytes[] memory proof = new bytes[](items.length);
        for(uint i=0;i<items.length;i++) {
            proof[i] = items[i].toBytes();
        }

        return proof;
    }
}