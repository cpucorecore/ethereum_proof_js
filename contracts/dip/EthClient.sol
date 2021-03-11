pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./RLPUtil.sol";

contract EthClient {
    struct HeaderInfo {
        uint total_difficulty;
        bytes32 parent_hash;
        uint64 number;
    }

    bool public validate_ethash;
    uint64 public dags_start_epoch;
    bytes16[] public dags_merkle_roots; // Vec<H128>
    bytes32 public best_header_hash;
    uint64 public hashes_gc_threshold;
    uint64 public finalized_gc_threshold;
    uint64 public num_confirmations;
    mapping(uint64 => bytes32) public canonical_header_hashes;
    mapping(uint64 => bytes32[]) public all_header_hashes;
    mapping(bytes32 => RLPUtil.HeaderSimple) public headers;
    mapping(bytes32 => HeaderInfo) public infos;
    address public trusted_signer;

    uint64 hashes_gc_index;
    uint64 finalized_gc_index;

    constructor(
        bool _validate_ethash,
        uint64 _dags_start_epoch,
        bytes16[] memory _dags_merkle_roots,
        bytes memory first_header,
        uint64 _hashes_gc_threshold,
        uint64 _finalized_gc_threshold,
        uint64 _num_confirmations,
        address _trusted_signer
    ) public {
        RLPUtil.HeaderSimple memory header = RLPUtil.DecodeHeaderSimple(first_header);
        bytes32 header_hash = keccak256(first_header);
        uint64 header_number = header.number;

        validate_ethash = _validate_ethash;
        dags_start_epoch = _dags_start_epoch;
        dags_merkle_roots = _dags_merkle_roots;
        best_header_hash = header_hash;
        hashes_gc_threshold = _hashes_gc_threshold;
        finalized_gc_threshold = _finalized_gc_threshold;
        num_confirmations = _num_confirmations;
        trusted_signer = _trusted_signer;

        hashes_gc_index = header_number;
        finalized_gc_index = header_number;

        canonical_header_hashes[header_number] = header_hash;
        all_header_hashes[header_number].push(header_hash);
        headers[header_hash] = header;
        HeaderInfo memory info;
        info.total_difficulty = 0;
        info.parent_hash = 0;
        info.number = header_number;
        infos[header_hash] = info;
    }

    function dag_merkel_root(uint64 epoch) public view returns(bytes16) {
        return dags_merkle_roots[epoch];
    }

    function last_block_number() public view returns(uint64) {
        HeaderInfo storage hi = infos[best_header_hash];
        return hi.number;
    }

    function block_hash(uint64 index) public view returns(bytes32) {
        return canonical_header_hashes[index];
    }

    function known_hashes(uint64 index) public view returns(bytes32[] memory) {
        return all_header_hashes[index];
    }

    function block_hash_safe(uint64 index) public view returns(bytes32 default_value) {
        bytes32 header_hash = block_hash(index);
        uint64 _last_block_number = last_block_number();
        if ((index + num_confirmations) > _last_block_number) {
            return default_value;
        } else {
            return header_hash;
        }
    }

    function add_block_header(bytes memory block_header) public {
        RLPUtil.HeaderSimple memory header = RLPUtil.DecodeHeaderSimple(block_header);
        bytes32 header_hash = keccak256(block_header);
        // TODO verify header
        record_header(header, header_hash);
    }

    function record_header(RLPUtil.HeaderSimple memory header, bytes32 header_hash) public {
        HeaderInfo storage best_info = infos[best_header_hash];
        uint64 header_number = header.number;
        require(header_number + finalized_gc_threshold >= best_info.number, "Header is too old to have a chance to appear on the canonical chain.");

        HeaderInfo storage parent_info = infos[header.parent_hash];
        require(parent_info.number != 0, "Header has unknown parent. Parent should be submitted first.");

        // Record this header in all_hashes
        bytes32[] storage all_hashes = all_header_hashes[header_number];
        bool header_existed = false;
        for(uint64 i=0; i<all_hashes.length; i++) {
            if(all_hashes[i] == header_hash) {
                header_existed = true;
                break;
            }
        }
        require(!header_existed, "Header is already known");
        all_hashes.push(header_hash);
        all_header_hashes[header_number] = all_hashes;

        // Record full information about this header.
        headers[header_hash] = header;
        HeaderInfo memory info;
        info.total_difficulty = parent_info.total_difficulty + header.difficulty;
        info.parent_hash = header.parent_hash;
        info.number = header_number;
        infos[header_hash] = info;

        // Check if canonical chain needs to be updated.
        if (info.total_difficulty > best_info.total_difficulty || (info.total_difficulty == best_info.total_difficulty && header.difficulty % 2 == 0)) {

            // If the new header has a lower number than the previous header, we need to clean it going forward.
            if (best_info.number > info.number) {
                for(uint64 number = info.number+1; number <= best_info.number; number++) {
                    delete canonical_header_hashes[number];
                }
            }

            // Replacing the global best header hash.
            best_header_hash = header_hash;
            canonical_header_hashes[header_number] = header_hash;

            // Replacing past hashes until we converge into the same parent.
            // Starting from the parent hash.
            uint64 number = header.number - 1;
            bytes32 current_hash = info.parent_hash;
            bool key_existed = false;


            while(true) {
                bytes32 prev_value = canonical_header_hashes[number];
                key_existed = (prev_value != 0);

                canonical_header_hashes[number] = current_hash;

                if (number == 0 || (key_existed && prev_value == current_hash)) {
                    break;
                }

                HeaderInfo storage info_tmp = infos[current_hash];
                if (info_tmp.number != 0) {
                    current_hash = info_tmp.parent_hash;
                } else {
                    break;
                }
                number -= 1;
            }


            if (header_number - hashes_gc_index >= hashes_gc_threshold) {
                gc_canonical_chain(header_number - hashes_gc_threshold);
                hashes_gc_index = header_number - hashes_gc_threshold - 10;
            }

            if (header_number - finalized_gc_index >= finalized_gc_threshold) {
                gc_headers(header_number - finalized_gc_threshold);
                finalized_gc_index = header_number - finalized_gc_index - 10;
            }
        }
    }

    function gc_canonical_chain(uint64 header_number) internal {
        while(true) {
            delete canonical_header_hashes[header_number];
            if (header_number == 0) {
                break;
            } else {
                header_number -= 1;
            }
        }
    }

    function gc_headers(uint64 header_number) internal {
        while(true) {
            delete all_header_hashes[header_number];
            if (header_number == 0) {
                break;
            } else {
                header_number -= 1;
            }
        }
    }
}

