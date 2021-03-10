pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Util.sol";
import "./RLPUtil.sol";

contract prover {
    address public admin;

    constructor() public {
        admin = msg.sender;
    }

    // block header: 0xf90215a07b3677b7a9c7a10698a6626b7a563168d70d075b20dc4a34586f69d107215220a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794037b539b0d6ae674c01cf5d9f84ea81b22532694a09fc4c68683db4aa2b60d4aa66ee87c4c62dd2ca97e4be40398f4b1135c511896a05bf56e745ff8705eb1f66747eaeda1ad215631b5ec84a9c4a5fd0f778cdc26f3a06d6b6ab9a687ab5fda5f81906af0407e5601c3730c4a10b34ddf46495996c514b90100000000000000000000000008000000000000000000000000002000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000004010000000000000000000000000000000000000000000000000000000000000008308bd64823b91837a1200825bf8845ffd524f9ad983010918846765746888676f312e31352e358664617277696ea01fb6eea3708aacac671c741e28215064b7553e78917c23e4bd8941b38efe0c16880bbf17bb8d9a3e9a
    // receipt: 0xf901bd01825bf8b9010000000000000000000000000800000000000000000000000000200000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000401000000000000000000000000000000000000000000000000000000000000000f8b4f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a02a056365f90644ba02872f61a1ad37613f47bba498327650b0b3ac40677e66c4a00000000000000000000000000000000000000000000000000000000000000064f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a0f81f8171d13ab9fef6d56dec96341eba6a5265cec2002c22bbadc5f19d219720a00000000000000000000000000000000000000000000000000000000000000065
    // log entry: 0xf85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a02a056365f90644ba02872f61a1ad37613f47bba498327650b0b3ac40677e66c4a00000000000000000000000000000000000000000000000000000000000000064
    // proofArrayRLP: 0xf901ccb901c9f901c6822080b901c0f901bd01825bf8b9010000000000000000000000000800000000000000000000000000200000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000401000000000000000000000000000000000000000000000000000000000000000f8b4f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a02a056365f90644ba02872f61a1ad37613f47bba498327650b0b3ac40677e66c4a00000000000000000000000000000000000000000000000000000000000000064f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a0f81f8171d13ab9fef6d56dec96341eba6a5265cec2002c22bbadc5f19d219720a00000000000000000000000000000000000000000000000000000000000000065
    // proof: ["0x2080", "0xf901bd01825bf8b9010000000000000000000000000800000000000000000000000000200000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000401000000000000000000000000000000000000000000000000000000000000000f8b4f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a02a056365f90644ba02872f61a1ad37613f47bba498327650b0b3ac40677e66c4a00000000000000000000000000000000000000000000000000000000000000064f85894d389508032869c1701b9dbe3f5fc6df40c488bc7e1a0f81f8171d13ab9fef6d56dec96341eba6a5265cec2002c22bbadc5f19d219720a00000000000000000000000000000000000000000000000000000000000000065"]
    function verify_log_entry(
        uint64 log_index,
        bytes memory log_entry_data,
        uint64 receipt_index,
        bytes memory receipt_data,
        bytes memory header_data,
        bytes memory proofRLP,
        bool skip_bridge_call
    ) public returns (bool) {
        // RLP decode: log entry
        RLPUtil.LogEntry memory logEntry = RLPUtil.DecodeLogEntry(log_entry_data);

        // RLP decode: receipt
        RLPUtil.Receipt memory receipt = RLPUtil.DecodeReceipt(receipt_data);

        // RLP decode: block header
        RLPUtil.Header memory header = RLPUtil.DecodeHeader(header_data);

        // RLP decode: proof, bytes --> bytes[]
        bytes[] memory proof = RLPUtil.DecodeProof(proofRLP);

        // Verify log_entry included in receipt
        RLPUtil.LogEntry memory logInReceipt = receipt.logs[log_index];
        if (!Util.LogEntryEqual(logEntry, logInReceipt)) return false;

        // Verify receipt included into header
        bytes memory receipt_index_rlp = RLPEncode.encodeUint(receipt_index);
        bool result = verify_trie_proof(header.receipts_root, receipt_index_rlp, proof, receipt_data);

        // Verify block header was in the bridge
    }

    bytes public actual_key;
    function verify_trie_proof(bytes32 expected_root, bytes memory key, bytes[] memory proof, bytes memory expected_value) internal returns (bool) {
        actual_key.length = 0;
        for (uint i=0;i<key.length;i++) {
            if (actual_key.length + 1 == proof.length) {
                actual_key.push(key[i]);
            } else {
                actual_key.push(bytes1(uint8(key[i]) / 16));
                actual_key.push(bytes1(uint8(key[i]) % 16));
            }
        }

        _verify_trie_proof(abi.encodePacked(expected_root), actual_key, proof, 0, 0, expected_value);
    }

    function _verify_trie_proof(bytes memory expected_root, bytes memory key, bytes[] memory proof, uint key_index, uint proof_index, bytes memory expected_value) internal returns (bool) {
        bytes memory node = proof[proof_index];
        bytes[] memory dec = RLPUtil.DecodeNode(node);

        if (key_index == 0) {
            require(Util.BytesEqual(abi.encodePacked(keccak256(node)), expected_root));
        } else if (node.length < 32) {
            require(Util.BytesEqual(node, expected_root));
        } else {
            require(Util.BytesEqual(abi.encodePacked(keccak256(node)), expected_root));
        }

        if (dec.length == 17) {
            // branch node
            if (key_index == key.length) {
                if (Util.BytesEqual(dec[dec.length - 1], expected_value)) {
                    return true;
                }
            } else if (key_index < key.length) {
                bytes memory new_expected_root = dec[uint8(key[key_index])];
                if (new_expected_root.length != 0) {
                    return _verify_trie_proof(
                        new_expected_root,
                        key,
                        proof,
                        key_index + 1,
                        proof_index + 1,
                        expected_value
                    );
                }
            } else {
                revert(); // This should not be reached if the proof has the correct format
            }
        } else if (dec.length == 2) {
            // leaf or extension node
            bytes memory nibbles = Util.ExtractNibbles(dec[0]);
            uint prefix = uint8(nibbles[0]);
            uint8 nibble = uint8(nibbles[1]);

            if (prefix == 2) {
                // even leaf node
                bytes memory key_left = Util.subarray(key, key_index, key.length);
                if (Util.BytesEqual(Util.ConcatNibbles(Util.subarray(nibbles, 2, nibbles.length)), key_left) &&
                    Util.BytesEqual(expected_value, dec[1])) {
                    return true;
                }
            } else if (prefix == 3) {
                // odd leaf node
                bytes memory key_left = Util.subarray(key, key_index + 1, key.length);
                if (nibble == uint8(key[key_index]) &&
                Util.BytesEqual(Util.ConcatNibbles(Util.subarray(nibbles, 2, nibbles.length)), key_left) &&
                    Util.BytesEqual(expected_value, dec[1])) {
                    return true;
                }

            } else if (prefix == 0) {
                // even extension node
                bytes memory shared_nibbles = Util.subarray(nibbles, 2, nibbles.length);
                bytes memory key_left = Util.subarray(key, key_index, key_index + shared_nibbles.length);
                if (Util.BytesEqual(Util.ConcatNibbles(shared_nibbles), key_left)) {
                    return _verify_trie_proof(
                        dec[1],
                        key,
                        proof,
                        key_index + shared_nibbles.length,
                        proof_index + 1,
                        expected_value
                    );
                }
            } else if (prefix == 1) {
                // odd extension node
                bytes memory key_left = Util.subarray(key, key_index + 1, key_index + nibbles.length - 1);
                if (nibble == uint8(key[key_index]) &&
                    Util.BytesEqual(Util.ConcatNibbles(Util.subarray(nibbles, 2, nibbles.length)), key_left)) {
                    return _verify_trie_proof(
                        dec[1],
                        key,
                        proof,
                        key_index + nibbles.length - 1,
                        proof_index + 1,
                        expected_value
                    );
                }

            } else {
                revert(); // This should not be reached if the proof has the correct format
            }
        } else {
            revert(); // This should not be reached if the proof has the correct format
        }

        return (expected_value.length == 0);
    }
}
