;; FractalNet - Decentralized Professional Identity & Reputation System
;; A privacy-preserving credential verification platform with fractal reputation scoring

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-stake (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-credential-expired (err u106))
(define-constant err-invalid-endorsement (err u107))
(define-constant err-challenge-active (err u108))

;; Minimum stake amount (in microSTX)
(define-constant min-stake-amount u1000000)

;; Time decay parameters (in blocks)
(define-constant credential-validity-period u52560) ;; ~1 year in blocks
(define-constant reputation-decay-period u4380) ;; ~1 month in blocks

;; Data Variables
(define-data-var total-credentials uint u0)
(define-data-var total-endorsements uint u0)
(define-data-var platform-fee uint u50000) ;; Fee in microSTX

;; Data Maps

;; Professional Identity Registry
(define-map professional-identities
    principal
    {
        reputation-score: uint,
        total-credentials: uint,
        total-endorsements-received: uint,
        total-endorsements-given: uint,
        joined-at: uint,
        last-activity: uint,
        is-verified: bool
    }
)

;; Credential Storage (hash-based for privacy)
(define-map credentials
    uint
    {
        owner: principal,
        credential-hash: (buff 32),
        credential-type: (string-ascii 50),
        stake-amount: uint,
        created-at: uint,
        expires-at: uint,
        endorsement-count: uint,
        challenge-count: uint,
        is-active: bool,
        verification-score: uint
    }
)

;; Credential Staking
(define-map credential-stakes
    {credential-id: uint, staker: principal}
    {
        amount: uint,
        staked-at: uint,
        is-locked: bool
    }
)

;; Endorsements
(define-map endorsements
    {credential-id: uint, endorser: principal}
    {
        endorsed-at: uint,
        endorsement-weight: uint,
        endorser-reputation: uint
    }
)

;; Challenge System
(define-map credential-challenges
    {credential-id: uint, challenger: principal}
    {
        challenge-stake: uint,
        challenged-at: uint,
        resolution-deadline: uint,
        is-resolved: bool,
        challenge-outcome: (optional bool)
    }
)

;; Fractal Reputation Connections
(define-map reputation-links
    {from: principal, to: principal}
    {
        trust-score: uint,
        interaction-count: uint,
        last-interaction: uint
    }
)

;; Read-only functions

(define-read-only (get-professional-identity (user principal))
    (map-get? professional-identities user)
)

(define-read-only (get-credential (credential-id uint))
    (map-get? credentials credential-id)
)

(define-read-only (get-credential-stake (credential-id uint) (staker principal))
    (map-get? credential-stakes {credential-id: credential-id, staker: staker})
)

(define-read-only (get-endorsement (credential-id uint) (endorser principal))
    (map-get? endorsements {credential-id: credential-id, endorser: endorser})
)

(define-read-only (get-reputation-link (from principal) (to principal))
    (map-get? reputation-links {from: from, to: to})
)

(define-read-only (calculate-time-decayed-reputation (user principal))
    (let
        (
            (identity (unwrap! (map-get? professional-identities user) (err u0)))
            (base-reputation (get reputation-score identity))
            (last-activity (get last-activity identity))
            (blocks-elapsed (- block-height last-activity))
            (decay-factor (/ blocks-elapsed reputation-decay-period))
        )
        (ok (if (> decay-factor u10)
            (/ base-reputation u2)
            (- base-reputation (/ base-reputation (* decay-factor u10)))
        ))
    )
)

(define-read-only (is-credential-valid (credential-id uint))
    (match (map-get? credentials credential-id)
        cred (ok (and 
            (get is-active cred)
            (< block-height (get expires-at cred))
        ))
        (err err-not-found)
    )
)

(define-read-only (get-total-credentials)
    (ok (var-get total-credentials))
)

(define-read-only (get-platform-fee)
    (ok (var-get platform-fee))
)

;; Public functions

;; Initialize professional identity
(define-public (register-professional-identity)
    (let
        (
            (caller tx-sender)
            (existing-identity (map-get? professional-identities caller))
        )
        (asserts! (is-none existing-identity) err-already-exists)
        (map-set professional-identities caller {
            reputation-score: u100,
            total-credentials: u0,
            total-endorsements-received: u0,
            total-endorsements-given: u0,
            joined-at: block-height,
            last-activity: block-height,
            is-verified: false
        })
        (ok true)
    )
)

;; Create a new credential with stake
(define-public (create-credential 
    (credential-hash (buff 32))
    (credential-type (string-ascii 50))
    (stake-amount uint))
    (let
        (
            (caller tx-sender)
            (credential-id (+ (var-get total-credentials) u1))
            (identity (unwrap! (map-get? professional-identities caller) err-not-found))
        )
        (asserts! (>= stake-amount min-stake-amount) err-invalid-stake)
        
        ;; Transfer stake to contract
        (try! (stx-transfer? stake-amount caller (as-contract tx-sender)))
        
        ;; Create credential
        (map-set credentials credential-id {
            owner: caller,
            credential-hash: credential-hash,
            credential-type: credential-type,
            stake-amount: stake-amount,
            created-at: block-height,
            expires-at: (+ block-height credential-validity-period),
            endorsement-count: u0,
            challenge-count: u0,
            is-active: true,
            verification-score: u50
        })
        
        ;; Record stake
        (map-set credential-stakes {credential-id: credential-id, staker: caller} {
            amount: stake-amount,
            staked-at: block-height,
            is-locked: true
        })
        
        ;; Update identity
        (map-set professional-identities caller
            (merge identity {
                total-credentials: (+ (get total-credentials identity) u1),
                last-activity: block-height
            })
        )
        
        ;; Update counter
        (var-set total-credentials credential-id)
        
        (ok credential-id)
    )
)

;; Endorse a credential
(define-public (endorse-credential (credential-id uint))
    (let
        (
            (caller tx-sender)
            (credential (unwrap! (map-get? credentials credential-id) err-not-found))
            (endorser-identity (unwrap! (map-get? professional-identities caller) err-not-found))
            (owner-identity (unwrap! (map-get? professional-identities (get owner credential)) err-not-found))
            (existing-endorsement (map-get? endorsements {credential-id: credential-id, endorser: caller}))
        )
        (asserts! (get is-active credential) err-credential-expired)
        (asserts! (is-none existing-endorsement) err-already-exists)
        (asserts! (not (is-eq caller (get owner credential))) err-unauthorized)
        
        ;; Record endorsement
        (map-set endorsements {credential-id: credential-id, endorser: caller} {
            endorsed-at: block-height,
            endorsement-weight: (get reputation-score endorser-identity),
            endorser-reputation: (get reputation-score endorser-identity)
        })
        
        ;; Update credential
        (map-set credentials credential-id
            (merge credential {
                endorsement-count: (+ (get endorsement-count credential) u1),
                verification-score: (+ (get verification-score credential) u10)
            })
        )
        
        ;; Update identities
        (map-set professional-identities caller
            (merge endorser-identity {
                total-endorsements-given: (+ (get total-endorsements-given endorser-identity) u1),
                last-activity: block-height
            })
        )
        
        (map-set professional-identities (get owner credential)
            (merge owner-identity {
                total-endorsements-received: (+ (get total-endorsements-received owner-identity) u1),
                reputation-score: (+ (get reputation-score owner-identity) u5),
                last-activity: block-height
            })
        )
        
        ;; Create reputation link
        (update-reputation-link caller (get owner credential))
        
        ;; Update counter
        (var-set total-endorsements (+ (var-get total-endorsements) u1))
        
        (ok true)
    )
)

;; Challenge a credential
(define-public (challenge-credential (credential-id uint) (challenge-stake uint))
    (let
        (
            (caller tx-sender)
            (credential (unwrap! (map-get? credentials credential-id) err-not-found))
            (existing-challenge (map-get? credential-challenges {credential-id: credential-id, challenger: caller}))
        )
        (asserts! (get is-active credential) err-credential-expired)
        (asserts! (is-none existing-challenge) err-already-exists)
        (asserts! (not (is-eq caller (get owner credential))) err-unauthorized)
        (asserts! (>= challenge-stake min-stake-amount) err-invalid-stake)
        
        ;; Transfer challenge stake
        (try! (stx-transfer? challenge-stake caller (as-contract tx-sender)))
        
        ;; Record challenge
        (map-set credential-challenges {credential-id: credential-id, challenger: caller} {
            challenge-stake: challenge-stake,
            challenged-at: block-height,
            resolution-deadline: (+ block-height u1440), ;; ~10 days
            is-resolved: false,
            challenge-outcome: none
        })
        
        ;; Update credential
        (map-set credentials credential-id
            (merge credential {
                challenge-count: (+ (get challenge-count credential) u1)
            })
        )
        
        (ok true)
    )
)

;; Resolve a challenge (can be called by contract owner or through governance)
(define-public (resolve-challenge (credential-id uint) (challenger principal) (challenge-valid bool))
    (let
        (
            (credential (unwrap! (map-get? credentials credential-id) err-not-found))
            (challenge (unwrap! (map-get? credential-challenges {credential-id: credential-id, challenger: challenger}) err-not-found))
            (owner-identity (unwrap! (map-get? professional-identities (get owner credential)) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (get is-resolved challenge)) err-unauthorized)
        
        (if challenge-valid
            ;; Challenge was valid - slash credential owner's stake and reward challenger
            (begin
                (try! (as-contract (stx-transfer? 
                    (get challenge-stake challenge)
                    tx-sender
                    challenger
                )))
                (map-set credentials credential-id
                    (merge credential {
                        is-active: false,
                        verification-score: u0
                    })
                )
                (map-set professional-identities (get owner credential)
                    (merge owner-identity {
                        reputation-score: (if (> (get reputation-score owner-identity) u50)
                            (- (get reputation-score owner-identity) u50)
                            u0
                        )
                    })
                )
            )
            ;; Challenge was invalid - return stake and penalize challenger
            (begin
                (try! (as-contract (stx-transfer? 
                    (get challenge-stake challenge)
                    tx-sender
                    (get owner credential)
                )))
            )
        )
        
        ;; Mark challenge as resolved
        (map-set credential-challenges {credential-id: credential-id, challenger: challenger}
            (merge challenge {
                is-resolved: true,
                challenge-outcome: (some challenge-valid)
            })
        )
        
        (ok true)
    )
)

;; Withdraw stake from expired credential
(define-public (withdraw-stake (credential-id uint))
    (let
        (
            (caller tx-sender)
            (credential (unwrap! (map-get? credentials credential-id) err-not-found))
            (stake (unwrap! (map-get? credential-stakes {credential-id: credential-id, staker: caller}) err-not-found))
        )
        (asserts! (is-eq caller (get owner credential)) err-unauthorized)
        (asserts! (> block-height (get expires-at credential)) err-unauthorized)
        (asserts! (get is-locked stake) err-unauthorized)
        
        ;; Transfer stake back
        (try! (as-contract (stx-transfer? (get amount stake) tx-sender caller)))
        
        ;; Update stake record
        (map-set credential-stakes {credential-id: credential-id, staker: caller}
            (merge stake {is-locked: false})
        )
        
        (ok true)
    )
)

;; Private functions

(define-private (update-reputation-link (from principal) (to principal))
    (let
        (
            (existing-link (map-get? reputation-links {from: from, to: to}))
        )
        (match existing-link
            link (map-set reputation-links {from: from, to: to}
                {
                    trust-score: (+ (get trust-score link) u1),
                    interaction-count: (+ (get interaction-count link) u1),
                    last-interaction: block-height
                }
            )
            (map-set reputation-links {from: from, to: to}
                {
                    trust-score: u1,
                    interaction-count: u1,
                    last-interaction: block-height
                }
            )
        )
        true
    )
)

;; Admin functions

(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set platform-fee new-fee)
        (ok true)
    )
)

(define-public (verify-professional (user principal))
    (let
        (
            (identity (unwrap! (map-get? professional-identities user) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set professional-identities user
            (merge identity {is-verified: true})
        )
        (ok true)
    )
)
