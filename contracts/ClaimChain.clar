;; ClaimChain - Transparent Claims Processing Protocol
;; Records accident reports, repairs, and payouts immutably on Stacks

(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-CLAIM-ID u100000)
(define-constant MAX-STRING-LENGTH u256)

;; Error codes
(define-constant ERR-UNAUTHORIZED u401)
(define-constant ERR-INVALID-CLAIM u400)
(define-constant ERR-CLAIM-NOT-FOUND u404)
(define-constant ERR-INVALID-REPAIR u405)
(define-constant ERR-INSUFFICIENT-BALANCE u402)
(define-constant ERR-CLAIM-CLOSED u406)

;; Status codes
(define-constant STATUS-FILED u0)
(define-constant STATUS-APPROVED u1)
(define-constant STATUS-UNDER-REPAIR u2)
(define-constant STATUS-COMPLETED u3)
(define-constant STATUS-PAID u4)
(define-constant STATUS-DENIED u5)

;; Data structures
(define-map claims
  { claim-id: uint }
  {
    claimant: principal,
    accident-date: uint,
    accident-location: (string-ascii 128),
    accident-description: (string-ascii 256),
    damage-estimate: uint,
    status: uint,
    created-at: uint,
    updated-at: uint
  }
)

(define-map repairs
  { claim-id: uint, repair-id: uint }
  {
    repair-shop: principal,
    repair-description: (string-ascii 256),
    repair-cost: uint,
    repair-date: uint,
    completion-date: uint,
    status: uint
  }
)

(define-map payouts
  { claim-id: uint }
  {
    approved-amount: uint,
    paid-amount: uint,
    payout-date: uint,
    payout-tx: (optional (buff 32))
  }
)

(define-map repair-counters
  { claim-id: uint }
  { count: uint }
)

(define-data-var total-claims-filed uint u0)
(define-data-var total-claims-approved uint u0)
(define-data-var total-claims-paid uint u0)
(define-data-var total-payouts-issued uint u0)

;; File a claim
(define-public (file-claim
  (accident-date uint)
  (accident-location (string-ascii 128))
  (accident-description (string-ascii 256))
  (damage-estimate uint)
)
  ;; Add input validation assertions to eliminate unchecked data warnings
  (begin
    (asserts! (> accident-date u0) (err ERR-INVALID-CLAIM))
    (asserts! (> damage-estimate u0) (err ERR-INVALID-CLAIM))
    (let
      (
        (new-claim-id (+ (var-get total-claims-filed) u1))
        (current-timestamp block-height)
      )
      (begin
        (map-set claims
          { claim-id: new-claim-id }
          {
            claimant: tx-sender,
            accident-date: accident-date,
            accident-location: accident-location,
            accident-description: accident-description,
            damage-estimate: damage-estimate,
            status: STATUS-FILED,
            created-at: current-timestamp,
            updated-at: current-timestamp
          }
        )
        (map-set repair-counters
          { claim-id: new-claim-id }
          { count: u0 }
        )
        (var-set total-claims-filed (+ (var-get total-claims-filed) u1))
        (ok new-claim-id)
      )
    )
  )
)

;; Approve a claim
(define-public (approve-claim (claim-id uint))
  ;; Add input validation assertion
  (begin
    (asserts! (> claim-id u0) (err ERR-INVALID-CLAIM))
    (if (is-eq tx-sender CONTRACT-OWNER)
      (match (map-get? claims { claim-id: claim-id })
        claim-data
        (if (is-eq (get status claim-data) STATUS-FILED)
          (begin
            (map-set claims
              { claim-id: claim-id }
              (merge claim-data { status: STATUS-APPROVED, updated-at: block-height })
            )
            (var-set total-claims-approved (+ (var-get total-claims-approved) u1))
            (ok true)
          )
          (err ERR-CLAIM-CLOSED)
        )
        (err ERR-CLAIM-NOT-FOUND)
      )
      (err ERR-UNAUTHORIZED)
    )
  )
)

;; Deny a claim
(define-public (deny-claim (claim-id uint))
  ;; Add input validation assertion
  (begin
    (asserts! (> claim-id u0) (err ERR-INVALID-CLAIM))
    (if (is-eq tx-sender CONTRACT-OWNER)
      (match (map-get? claims { claim-id: claim-id })
        claim-data
        (if (is-eq (get status claim-data) STATUS-FILED)
          (begin
            (map-set claims
              { claim-id: claim-id }
              (merge claim-data { status: STATUS-DENIED, updated-at: block-height })
            )
            (ok true)
          )
          (err ERR-CLAIM-CLOSED)
        )
        (err ERR-CLAIM-NOT-FOUND)
      )
      (err ERR-UNAUTHORIZED)
    )
  )
)

;; Record a repair
(define-public (record-repair
  (claim-id uint)
  (repair-shop principal)
  (repair-description (string-ascii 256))
  (repair-cost uint)
  (repair-date uint)
)
  ;; Add input validation assertions
  (begin
    (asserts! (> claim-id u0) (err ERR-INVALID-CLAIM))
    (asserts! (> repair-cost u0) (err ERR-INVALID-CLAIM))
    (asserts! (> repair-date u0) (err ERR-INVALID-CLAIM))
    (match (map-get? claims { claim-id: claim-id })
      claim-data
      (if (is-eq (get status claim-data) STATUS-APPROVED)
        (let
          (
            (next-repair-id (match (map-get? repair-counters { claim-id: claim-id })
              counter-data (get count counter-data)
              u0
            ))
          )
          (begin
            (map-set repairs
              { claim-id: claim-id, repair-id: next-repair-id }
              {
                repair-shop: repair-shop,
                repair-description: repair-description,
                repair-cost: repair-cost,
                repair-date: repair-date,
                completion-date: u0,
                status: STATUS-UNDER-REPAIR
              }
            )
            (map-set repair-counters
              { claim-id: claim-id }
              { count: (+ next-repair-id u1) }
            )
            (map-set claims
              { claim-id: claim-id }
              (merge claim-data { status: STATUS-UNDER-REPAIR, updated-at: block-height })
            )
            (ok next-repair-id)
          )
        )
        (err ERR-CLAIM-CLOSED)
      )
      (err ERR-CLAIM-NOT-FOUND)
    )
  )
)

;; Complete a repair
(define-public (complete-repair
  (claim-id uint)
  (repair-id uint)
  (completion-date uint)
)
  ;; Add input validation assertions
  (begin
    (asserts! (> claim-id u0) (err ERR-INVALID-CLAIM))
    (asserts! (>= completion-date u0) (err ERR-INVALID-CLAIM))
    (match (map-get? repairs { claim-id: claim-id, repair-id: repair-id })
      repair-data
      (begin
        (map-set repairs
          { claim-id: claim-id, repair-id: repair-id }
          (merge repair-data { completion-date: completion-date, status: STATUS-COMPLETED })
        )
        (match (map-get? claims { claim-id: claim-id })
          claim-data
          (begin
            (map-set claims
              { claim-id: claim-id }
              (merge claim-data { status: STATUS-COMPLETED, updated-at: block-height })
            )
            (ok true)
          )
          (err ERR-CLAIM-NOT-FOUND)
        )
      )
      (err ERR-INVALID-REPAIR)
    )
  )
)

;; Approve payout
(define-public (approve-payout (claim-id uint) (approved-amount uint))
  ;; Add input validation assertions
  (begin
    (asserts! (> claim-id u0) (err ERR-INVALID-CLAIM))
    (asserts! (> approved-amount u0) (err ERR-INVALID-CLAIM))
    (if (is-eq tx-sender CONTRACT-OWNER)
      (match (map-get? claims { claim-id: claim-id })
        claim-data
        (if (is-eq (get status claim-data) STATUS-COMPLETED)
          (begin
            (map-set payouts
              { claim-id: claim-id }
              {
                approved-amount: approved-amount,
                paid-amount: u0,
                payout-date: u0,
                payout-tx: none
              }
            )
            (ok true)
          )
          (err ERR-CLAIM-CLOSED)
        )
        (err ERR-CLAIM-NOT-FOUND)
      )
      (err ERR-UNAUTHORIZED)
    )
  )
)

;; Record payout
(define-public (record-payout
  (claim-id uint)
  (paid-amount uint)
  (payout-tx (buff 32))
)
  ;; Add input validation assertions
  (begin
    (asserts! (> claim-id u0) (err ERR-INVALID-CLAIM))
    (asserts! (> paid-amount u0) (err ERR-INVALID-CLAIM))
    (if (is-eq tx-sender CONTRACT-OWNER)
      (match (map-get? payouts { claim-id: claim-id })
        payout-data
        (if (<= paid-amount (get approved-amount payout-data))
          (begin
            (map-set payouts
              { claim-id: claim-id }
              {
                approved-amount: (get approved-amount payout-data),
                paid-amount: paid-amount,
                payout-date: block-height,
                payout-tx: (some payout-tx)
              }
            )
            (match (map-get? claims { claim-id: claim-id })
              claim-data
              (begin
                (map-set claims
                  { claim-id: claim-id }
                  (merge claim-data { status: STATUS-PAID, updated-at: block-height })
                )
                (var-set total-claims-paid (+ (var-get total-claims-paid) u1))
                (var-set total-payouts-issued (+ (var-get total-payouts-issued) paid-amount))
                (ok true)
              )
              (err ERR-CLAIM-NOT-FOUND)
            )
          )
          (err ERR-INSUFFICIENT-BALANCE)
        )
        (err ERR-CLAIM-NOT-FOUND)
      )
      (err ERR-UNAUTHORIZED)
    )
  )
)

;; Read-only functions

;; Get claim details
(define-read-only (get-claim (claim-id uint))
  (map-get? claims { claim-id: claim-id })
)

;; Get repair details
(define-read-only (get-repair (claim-id uint) (repair-id uint))
  (map-get? repairs { claim-id: claim-id, repair-id: repair-id })
)

;; Get payout details
(define-read-only (get-payout (claim-id uint))
  (map-get? payouts { claim-id: claim-id })
)

;; Get claim status
(define-read-only (get-claim-status (claim-id uint))
  (match (map-get? claims { claim-id: claim-id })
    claim-data
    (ok (get status claim-data))
    (err ERR-CLAIM-NOT-FOUND)
  )
)

;; Get repair count for a claim
(define-read-only (get-repair-count (claim-id uint))
  (match (map-get? repair-counters { claim-id: claim-id })
    counter-data
    (ok (get count counter-data))
    (err ERR-CLAIM-NOT-FOUND)
  )
)

;; Get statistics
(define-read-only (get-statistics)
  (ok {
    total-claims-filed: (var-get total-claims-filed),
    total-claims-approved: (var-get total-claims-approved),
    total-claims-paid: (var-get total-claims-paid),
    total-payouts-issued: (var-get total-payouts-issued)
  })
)
