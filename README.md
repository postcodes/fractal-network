# FractalNet

FractalNet is a decentralized professional identity and reputation system that revolutionizes how professional credentials are verified and shared. The platform uses zero-knowledge proofs and fractal mathematics to create verifiable professional credentials while keeping sensitive personal data completely private and self-sovereign.

The system leverages zk-SNARKs to enable professionals to prove qualifications, work experience, and skill endorsements without revealing actual details or personal information. Smart contracts automate verification challenges where users can stake tokens on their credentials' authenticity, creating economic incentives for honest behavior through slashing mechanisms that penalize false claims. The innovative fractal reputation algorithm analyzes geometric patterns of professional relationships to calculate trust scores that become increasingly accurate and tamper-resistant as the network expands.

# FractalNet - Decentralized Professional Identity & Reputation System

A privacy-preserving credential verification platform built on the Stacks blockchain that revolutionizes professional identity management through zero-knowledge proofs, fractal reputation scoring, and economic staking mechanisms.

## Overview

FractalNet enables professionals to maintain complete privacy sovereignty while creating verifiable credentials that can be selectively revealed for job applications, client proposals, and partnership opportunities. The system uses cryptographic hashes for privacy, economic staking for authenticity, and fractal mathematics for reputation calculation.

## Key Features

### 🔐 Privacy-First Architecture
- Credentials stored as cryptographic hashes (buff 32)
- Selective disclosure of professional attributes
- Zero-knowledge proof compatible design
- Self-sovereign identity management

### 💎 Economic Staking Mechanism
- Minimum stake requirement (1 STX) for credential creation
- Stake slashing for fraudulent credentials
- Challenge and verification system
- Automated dispute resolution

### 📊 Fractal Reputation Scoring
- Dynamic reputation calculation based on network geometry
- Time-decay functions for credential relevance
- Weighted endorsements by endorser reputation
- Tamper-resistant trust scores

### ✅ Credential Verification System
- Peer endorsement mechanisms
- Challenge-based validation
- Verification score accumulation
- Automatic credential expiration (1 year validity)

### 🤝 Professional Network Mapping
- Reputation link tracking between users
- Trust score calculation
- Interaction history
- Network effect amplification

## Smart Contract Architecture

### Core Data Structures

#### Professional Identity
```clarity
{
    reputation-score: uint,           // Base reputation (starts at 100)
    total-credentials: uint,          // Number of credentials created
    total-endorsements-received: uint,
    total-endorsements-given: uint,
    joined-at: uint,                  // Block height of registration
    last-activity: uint,              // Last interaction block height
    is-verified: bool                 // Platform verification status
}
```

#### Credential
```clarity
{
    owner: principal,
    credential-hash: (buff 32),       // Privacy-preserving hash
    credential-type: (string-ascii 50),
    stake-amount: uint,
    created-at: uint,
    expires-at: uint,                 // Auto-expires after ~1 year
    endorsement-count: uint,
    challenge-count: uint,
    is-active: bool,
    verification-score: uint          // Increases with endorsements
}
```

#### Endorsement
```clarity
{
    endorsed-at: uint,
    endorsement-weight: uint,         // Based on endorser's reputation
    endorser-reputation: uint
}
```

#### Challenge
```clarity
{
    challenge-stake: uint,
    challenged-at: uint,
    resolution-deadline: uint,        // ~10 days to resolve
    is-resolved: bool,
    challenge-outcome: (optional bool)
}
```

#### Reputation Link
```clarity
{
    trust-score: uint,
    interaction-count: uint,
    last-interaction: uint
}
```

## Main Functions

### Identity Management

#### `register-professional-identity`
Register a new professional identity on the platform.

**Returns:** `(response bool uint)`

**Example:**
```clarity
(contract-call? .fractalnet register-professional-identity)
```

#### `get-professional-identity`
Retrieve a user's professional identity information.

**Parameters:**
- `user: principal` - The user's principal address

**Returns:** `(optional {identity})`

### Credential Operations

#### `create-credential`
Create a new credential with economic stake.

**Parameters:**
- `credential-hash: (buff 32)` - Privacy-preserving hash of credential data
- `credential-type: (string-ascii 50)` - Type of credential (e.g., "education", "experience")
- `stake-amount: uint` - Amount to stake (minimum 1,000,000 microSTX)

**Returns:** `(response uint uint)` - Returns credential ID on success

**Example:**
```clarity
(contract-call? .fractalnet create-credential 
    0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
    "software-engineer-experience"
    u2000000)
```

#### `endorse-credential`
Endorse another user's credential to increase its verification score.

**Parameters:**
- `credential-id: uint` - The credential to endorse

**Returns:** `(response bool uint)`

**Effects:**
- Increases credential verification score by 10 points
- Increases credential owner's reputation by 5 points
- Creates reputation link between endorser and credential owner

**Example:**
```clarity
(contract-call? .fractalnet endorse-credential u1)
```

#### `challenge-credential`
Challenge the authenticity of a credential by staking tokens.

**Parameters:**
- `credential-id: uint` - The credential to challenge
- `challenge-stake: uint` - Amount to stake on the challenge

**Returns:** `(response bool uint)`

**Example:**
```clarity
(contract-call? .fractalnet challenge-credential u1 u1500000)
```

#### `resolve-challenge`
Resolve a credential challenge (admin only).

**Parameters:**
- `credential-id: uint` - The challenged credential
- `challenger: principal` - The principal who issued the challenge
- `challenge-valid: bool` - Whether the challenge is valid

**Returns:** `(response bool uint)`

**Effects:**
- If valid: Slashes credential owner's stake, deactivates credential, rewards challenger
- If invalid: Returns challenger's stake to credential owner

#### `withdraw-stake`
Withdraw stake from an expired credential.

**Parameters:**
- `credential-id: uint` - The expired credential

**Returns:** `(response bool uint)`

**Requirements:**
- Caller must be credential owner
- Credential must be expired (beyond validity period)

### Reputation & Analytics

#### `calculate-time-decayed-reputation`
Calculate a user's current reputation considering time decay.

**Parameters:**
- `user: principal` - The user to calculate reputation for

**Returns:** `(response uint uint)`

**Algorithm:**
- Decay period: ~1 month (4,380 blocks)
- Reputation halved after 10 decay periods
- Encourages ongoing platform activity

#### `is-credential-valid`
Check if a credential is currently valid and active.

**Parameters:**
- `credential-id: uint` - The credential to check

**Returns:** `(response bool uint)`

#### `get-reputation-link`
Retrieve reputation link data between two users.

**Parameters:**
- `from: principal` - Source user
- `to: principal` - Target user

**Returns:** `(optional {link-data})`

### Read-Only Functions

- `get-credential` - Retrieve credential details
- `get-credential-stake` - Get stake information
- `get-endorsement` - Get endorsement details
- `get-total-credentials` - Get platform statistics
- `get-platform-fee` - Get current platform fee

### Administrative Functions

#### `set-platform-fee`
Update the platform fee (owner only).

**Parameters:**
- `new-fee: uint` - New fee amount in microSTX

#### `verify-professional`
Grant platform verification status to a user (owner only).

**Parameters:**
- `user: principal` - User to verify

## Economic Model

### Staking Requirements
- **Minimum Stake:** 1,000,000 microSTX (1 STX)
- **Purpose:** Economic guarantee of credential authenticity
- **Lock Period:** Until credential expiration (~1 year)
- **Withdrawal:** Available after credential expires

### Challenge Mechanism
- **Challenge Stake:** Minimum 1 STX
- **Resolution Time:** ~10 days (1,440 blocks)
- **Valid Challenge:** Challenger receives their stake + credential owner's stake
- **Invalid Challenge:** Credential owner receives challenger's stake
- **Reputation Impact:** Valid challenges reduce owner's reputation by 50 points

### Endorsement Economics
- **Cost:** Free (gas fees only)
- **Reputation Gain:** +5 reputation per endorsement received
- **Verification Score:** +10 points per endorsement
- **Weight:** Based on endorser's reputation

## Time-Based Mechanics

### Credential Lifecycle
- **Validity Period:** 52,560 blocks (~1 year)
- **Creation:** Immediate upon staking
- **Expiration:** Automatic after validity period
- **Renewal:** Create new credential after expiration

### Reputation Decay
- **Decay Period:** 4,380 blocks (~1 month)
- **Mechanism:** Linear decay based on inactivity
- **Maximum Decay:** 50% after 10 periods
- **Prevention:** Any platform activity resets decay

### Challenge Resolution
- **Deadline:** 1,440 blocks (~10 days)
- **Timeframe:** From challenge creation
- **Resolution:** Admin or governance decision

## Privacy & Security

### Privacy Features
1. **Credential Hashing:** All credential data stored as cryptographic hashes
2. **Selective Disclosure:** Users choose what to reveal and when
3. **Zero-Knowledge Compatible:** Hash structure supports ZK proofs
4. **No Personal Data:** Contract stores no identifiable information

### Security Mechanisms
1. **Economic Incentives:** Staking discourages false credentials
2. **Challenge System:** Community-driven fraud detection
3. **Reputation at Risk:** False claims damage long-term reputation
4. **Time Locks:** Stake locked until credential expiration
5. **Slashing:** Automatic penalty for fraudulent behavior

## Use Cases

### Job Applications
- Prove years of experience without revealing employer
- Verify education credentials without exposing institution
- Demonstrate skill endorsements from verified professionals

### Client Proposals
- Show track record without disclosing confidential projects
- Prove expertise through peer endorsements
- Display reputation score for trustworthiness

### Professional Networking
- Build verifiable professional relationships
- Accumulate weighted endorsements
- Establish trust through fractal reputation

### Partnership Verification
- Validate business credentials
- Verify company associations
- Demonstrate professional standing

## Integration Guide

### Creating a Credential

1. **Prepare Credential Data**
   ```javascript
   // Off-chain: Hash sensitive credential data
   const credentialData = {
       employer: "Tech Corp",
       position: "Senior Engineer",
       years: 5,
       skills: ["Rust", "Clarity", "Blockchain"]
   };
   const hash = sha256(JSON.stringify(credentialData));
   ```

2. **Submit to Blockchain**
   ```clarity
   (contract-call? .fractalnet create-credential 
       hash 
       "work-experience" 
       u2000000)
   ```

3. **Store Proof Off-Chain**
   ```javascript
   // Keep original data for future ZK proofs
   localStorage.setItem('credential-1-proof', credentialData);
   ```

### Selective Disclosure

1. **Generate ZK Proof** (off-chain)
   ```javascript
   // User proves they worked at "a FAANG company" 
   // without revealing which one
   const proof = generateZKProof(
       credentialData,
       "employer in FAANG_LIST"
   );
   ```

2. **Verify Against Hash**
   ```javascript
   // Verifier checks proof against on-chain hash
   const isValid = verifyProof(proof, onChainHash);
   ```

### Building Reputation

1. **Register Identity**
2. **Create Multiple Credentials** (different types)
3. **Seek Endorsements** from reputable professionals
4. **Maintain Activity** to prevent reputation decay
5. **Participate in Network** through endorsements

## Deployment

### Prerequisites
- Stacks blockchain node or access to testnet/mainnet
- Clarinet for testing (if modifications needed)
- STX tokens for contract deployment

### Deployment Steps

1. **Deploy Contract**
   ```bash
   clarinet deploy --testnet fractalnet.clar
   ```

2. **Initialize Platform**
   ```clarity
   ;; Set platform fee if needed
   (contract-call? .fractalnet set-platform-fee u50000)
   ```

3. **Register First Users**
   ```clarity
   (contract-call? .fractalnet register-professional-identity)
   ```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Only contract owner can perform this action |
| u101 | err-not-found | Requested entity not found |
| u102 | err-unauthorized | Unauthorized action |
| u103 | err-invalid-stake | Stake amount below minimum |
| u104 | err-insufficient-balance | Insufficient STX balance |
| u105 | err-already-exists | Entity already exists |
| u106 | err-credential-expired | Credential has expired |
| u107 | err-invalid-endorsement | Invalid endorsement attempt |
| u108 | err-challenge-active | Challenge already active |

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| min-stake-amount | 1,000,000 | Minimum stake (1 STX) |
| credential-validity-period | 52,560 blocks | ~1 year |
| reputation-decay-period | 4,380 blocks | ~1 month |
| platform-fee | 50,000 microSTX | Platform fee |

## Roadmap

### Phase 1: Core Infrastructure ✅
- Professional identity registration
- Credential creation with staking
- Endorsement system
- Challenge mechanism

### Phase 2: Enhanced Privacy (Future)
- Native zk-SNARK integration
- Advanced selective disclosure
- Privacy-preserving queries
- Encrypted credential metadata

### Phase 3: Governance (Future)
- DAO-based challenge resolution
- Community verification
- Protocol parameter updates
- Fee distribution mechanisms

### Phase 4: Ecosystem Integration (Future)
- API for external platforms
- LinkedIn/GitHub integration bridges
- Cross-chain credential portability
- Enterprise solutions

## Best Practices

### For Professionals
1. **Stake Appropriately:** Higher stakes signal stronger confidence
2. **Build Gradually:** Start with easily verifiable credentials
3. **Seek Quality Endorsements:** Focus on reputable endorsers
4. **Maintain Activity:** Prevent reputation decay
5. **Store Proofs Securely:** Keep original credential data safe

### For Endorsers
1. **Verify Before Endorsing:** Your reputation is on the line
2. **Endorse Strategically:** Quality over quantity
3. **Build Reputation First:** Higher reputation = higher endorsement weight
4. **Maintain Integrity:** False endorsements harm the network

### For Challengers
1. **Challenge Responsibly:** Only challenge suspicious credentials
2. **Stake Adequately:** Match or exceed credential stake
3. **Provide Evidence:** Support challenges with proof
4. **Accept Outcomes:** Respect resolution decisions

## Security Considerations

### Smart Contract Security
- No recursive calls
- Protected admin functions
- Balance checks before transfers
- Input validation on all parameters

### Economic Security
- Minimum stake requirements prevent spam
- Challenge mechanism deters fraud
- Reputation at risk for all participants
- Time locks prevent immediate stake withdrawal

### Privacy Security
- No raw personal data stored
- Hash-based credential storage
- Off-chain proof generation
- User-controlled disclosure

## FAQ

**Q: How is reputation calculated?**
A: Reputation starts at 100, increases with endorsements (+5 per endorsement received), and decreases with valid challenges (-50). Time decay applies based on inactivity.

**Q: Can I delete my credentials?**
A: Credentials automatically expire after 1 year. You can mark them inactive but blockchain data is immutable.

**Q: What happens if my credential is falsely challenged?**
A: If the challenge is ruled invalid, you receive the challenger's stake as compensation.

**Q: How do endorsements work?**
A: Any registered user can endorse credentials (except their own). Endorsements from high-reputation users carry more weight.

**Q: Is my personal information stored on-chain?**
A: No. Only cryptographic hashes are stored. Your actual credential data stays off-chain under your control.

**Q: How long do credentials last?**
A: Credentials are valid for approximately 1 year (52,560 blocks) from creation.

**Q: Can I increase my reputation score?**
A: Yes, through receiving endorsements, creating credentials, and maintaining platform activity.

**Q: What prevents fake endorsements?**
A: The reputation system creates economic incentives for honesty. False endorsements can be challenged, risking the endorser's reputation.

## Contributing

FractalNet is designed to be extended and improved by the community. Consider contributing to:
- Enhanced privacy features
- Governance mechanisms  
- Additional credential types
- Integration tools
- Documentation improvements

## License

This smart contract is provided as-is for educational and commercial use. Review and audit before production deployment.

## Contact & Support

For questions, issues, or collaboration:
- Open an issue for bugs or feature requests
- Review the code for implementation details
- Test thoroughly on testnet before mainnet deployment

## Disclaimer

This smart contract handles financial stakes and reputation systems. Users should:
- Understand the economic implications
- Test on testnet first
- Audit code before production use
- Comply with local regulations
- Secure their private keys

---

**FractalNet** - Decentralized Professional Identity for the Web3 Era
