(define-constant ERR-NOT-AUTHORIZED (err u1001))
(define-constant ERR-PROJECT-NOT-FOUND (err u1002))
(define-constant ERR-BOUNTY-NOT-FOUND (err u1003))
(define-constant ERR-INSUFFICIENT-FUNDS (err u1004))
(define-constant ERR-BOUNTY-ALREADY-CLAIMED (err u1005))
(define-constant ERR-INVALID-STATUS (err u1006))
(define-constant ERR-CONTRIBUTOR-NOT-FOUND (err u1007))
(define-constant ERR-ALREADY-EXISTS (err u1008))
(define-constant ERR-INVALID-PERCENTAGE (err u1009))
(define-constant ERR-NO-CONTRIBUTIONS (err u1010))

(define-constant CONTRACT-OWNER tx-sender)
(define-constant REFERRAL-REWARD u5)
(define-constant MIN-STAKE-AMOUNT u1000000)
(define-constant MAX-ROYALTY-PERCENTAGE u25)

(define-data-var next-project-id uint u1)
(define-data-var next-bounty-id uint u1)
(define-data-var next-contribution-id uint u1)
(define-data-var total-platform-fees uint u0)

(define-map projects
  uint
  {
    name: (string-ascii 50),
    description: (string-ascii 500),
    maintainer: principal,
    repository-url: (string-ascii 200),
    royalty-percentage: uint,
    total-earned: uint,
    is-active: bool
  }
)

(define-map contributors
  principal
  {
    github-username: (string-ascii 50),
    reputation-score: uint,
    total-earned: uint,
    contributions-count: uint,
    is-verified: bool
  }
)

(define-map bounties
  uint
  {
    project-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    amount: uint,
    creator: principal,
    assignee: (optional principal),
    status: (string-ascii 20),
    deadline: uint,
    required-skills: (string-ascii 200)
  }
)

(define-map contributions
  uint
  {
    bounty-id: uint,
    contributor: principal,
    submission-url: (string-ascii 200),
    status: (string-ascii 20),
    submitted-at: uint,
    validated-by: (optional principal)
  }
)

(define-map stakes
  { project-id: uint, staker: principal }
  {
    amount: uint,
    staked-at: uint,
    is-active: bool
  }
)

(define-map project-stakes
  uint
  { total-staked: uint }
)

(define-map bounty-assignments
  { bounty-id: uint, contributor: principal }
  { assigned-at: uint }
)

(define-read-only (get-project (project-id uint))
  (map-get? projects project-id)
)

(define-read-only (get-contributor (contributor principal))
  (map-get? contributors contributor)
)

(define-read-only (get-bounty (bounty-id uint))
  (map-get? bounties bounty-id)
)

(define-read-only (get-contribution (contribution-id uint))
  (map-get? contributions contribution-id)
)

(define-read-only (get-stake (project-id uint) (staker principal))
  (map-get? stakes { project-id: project-id, staker: staker })
)

(define-read-only (get-project-total-stake (project-id uint))
  (default-to { total-staked: u0 } (map-get? project-stakes project-id))
)

(define-read-only (get-platform-stats)
  {
    total-projects: (- (var-get next-project-id) u1),
    total-bounties: (- (var-get next-bounty-id) u1),
    total-contributions: (- (var-get next-contribution-id) u1),
    total-platform-fees: (var-get total-platform-fees)
  }
)

(define-public (register-project (name (string-ascii 50)) (description (string-ascii 500)) (repository-url (string-ascii 200)) (royalty-percentage uint))
  (let ((project-id (var-get next-project-id)))
    (asserts! (<= royalty-percentage MAX-ROYALTY-PERCENTAGE) ERR-INVALID-PERCENTAGE)
    (map-set projects project-id
      {
        name: name,
        description: description,
        maintainer: tx-sender,
        repository-url: repository-url,
        royalty-percentage: royalty-percentage,
        total-earned: u0,
        is-active: true
      }
    )
    (map-set project-stakes project-id { total-staked: u0 })
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

(define-public (register-contributor (github-username (string-ascii 50)) (referrer (optional principal)))
  (begin
    (asserts! (is-none (map-get? contributors tx-sender)) ERR-ALREADY-EXISTS)
    (map-set contributors tx-sender
      {
        github-username: github-username,
        reputation-score: u0,
        total-earned: u0,
        contributions-count: u0,
        is-verified: false
      }
    )
    (match referrer
      ref (let ((referrer-data (unwrap! (map-get? contributors ref) (ok true))))
            (asserts! (not (is-eq ref tx-sender)) (ok true))
            (asserts! (get is-verified referrer-data) (ok true))
            (map-set contributors ref
              (merge referrer-data { reputation-score: (+ (get reputation-score referrer-data) REFERRAL-REWARD) })
            )
            (ok true)
          )
      (ok true)
    )
  )
)

(define-public (create-bounty (project-id uint) (title (string-ascii 100)) (description (string-ascii 500)) (deadline uint) (required-skills (string-ascii 200)))
  (let ((bounty-id (var-get next-bounty-id))
        (amount (stx-get-balance tx-sender)))
    (asserts! (> amount u0) ERR-INSUFFICIENT-FUNDS)
    (asserts! (is-some (map-get? projects project-id)) ERR-PROJECT-NOT-FOUND)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set bounties bounty-id
      {
        project-id: project-id,
        title: title,
        description: description,
        amount: amount,
        creator: tx-sender,
        assignee: none,
        status: "open",
        deadline: deadline,
        required-skills: required-skills
      }
    )
    (var-set next-bounty-id (+ bounty-id u1))
    (ok bounty-id)
  )
)

(define-public (stake-on-project (project-id uint) (amount uint))
  (begin
    (asserts! (>= amount MIN-STAKE-AMOUNT) ERR-INSUFFICIENT-FUNDS)
    (asserts! (is-some (map-get? projects project-id)) ERR-PROJECT-NOT-FOUND)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (let ((existing-stake (default-to { amount: u0, staked-at: u0, is-active: false } 
                                    (map-get? stakes { project-id: project-id, staker: tx-sender })))
          (current-total (get total-staked (get-project-total-stake project-id))))
      (map-set stakes { project-id: project-id, staker: tx-sender }
        {
          amount: (+ (get amount existing-stake) amount),
          staked-at: stacks-block-height,
          is-active: true
        }
      )
      (map-set project-stakes project-id { total-staked: (+ current-total amount) })
      (ok true)
    )
  )
)

(define-public (submit-contribution (bounty-id uint) (submission-url (string-ascii 200)))
  (let ((contribution-id (var-get next-contribution-id))
        (bounty (unwrap! (map-get? bounties bounty-id) ERR-BOUNTY-NOT-FOUND)))
    (asserts! (is-some (map-get? contributors tx-sender)) ERR-CONTRIBUTOR-NOT-FOUND)
    (asserts! (is-eq (get status bounty) "open") ERR-INVALID-STATUS)
    (map-set contributions contribution-id
      {
        bounty-id: bounty-id,
        contributor: tx-sender,
        submission-url: submission-url,
        status: "pending",
        submitted-at: stacks-block-height,
        validated-by: none
      }
    )
    (var-set next-contribution-id (+ contribution-id u1))
    (ok contribution-id)
  )
)

(define-public (validate-contribution (contribution-id uint) (approved bool))
  (let ((contribution (unwrap! (map-get? contributions contribution-id) ERR-BOUNTY-NOT-FOUND))
        (bounty-id (get bounty-id contribution))
        (bounty (unwrap! (map-get? bounties bounty-id) ERR-BOUNTY-NOT-FOUND))
        (project (unwrap! (map-get? projects (get project-id bounty)) ERR-PROJECT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get maintainer project)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status contribution) "pending") ERR-INVALID-STATUS)
    (if approved
      (begin
        (map-set contributions contribution-id
          (merge contribution { status: "approved", validated-by: (some tx-sender) })
        )
        (map-set bounties bounty-id
          (merge bounty { status: "completed", assignee: (some (get contributor contribution)) })
        )
        (try! (as-contract (stx-transfer? (get amount bounty) tx-sender (get contributor contribution))))
        (let ((contributor-data (unwrap! (map-get? contributors (get contributor contribution)) ERR-CONTRIBUTOR-NOT-FOUND)))
          (map-set contributors (get contributor contribution)
            (merge contributor-data 
              { 
                total-earned: (+ (get total-earned contributor-data) (get amount bounty)),
                contributions-count: (+ (get contributions-count contributor-data) u1),
                reputation-score: (+ (get reputation-score contributor-data) u10)
              }
            )
          )
        )
      )
      (map-set contributions contribution-id
        (merge contribution { status: "rejected", validated-by: (some tx-sender) })
      )
    )
    (ok approved)
  )
)

(define-public (claim-bounty (bounty-id uint))
  (let ((bounty (unwrap! (map-get? bounties bounty-id) ERR-BOUNTY-NOT-FOUND)))
    (asserts! (is-eq (get status bounty) "completed") ERR-INVALID-STATUS)
    (asserts! (is-eq (some tx-sender) (get assignee bounty)) ERR-NOT-AUTHORIZED)
    (try! (as-contract (stx-transfer? (get amount bounty) tx-sender tx-sender)))
    (ok true)
  )
)

(define-public (cancel-bounty (bounty-id uint))
  (let ((bounty (unwrap! (map-get? bounties bounty-id) ERR-BOUNTY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get creator bounty)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status bounty) "open") ERR-INVALID-STATUS)
    (asserts! (is-none (get assignee bounty)) ERR-INVALID-STATUS)
    (try! (as-contract (stx-transfer? (get amount bounty) tx-sender (get creator bounty))))
    (map-set bounties bounty-id (merge bounty { status: "cancelled" }))
    (ok true)
  )
)

(define-public (distribute-royalties (project-id uint))
  (let ((project (unwrap! (map-get? projects project-id) ERR-PROJECT-NOT-FOUND))
        (contract-balance (stx-get-balance (as-contract tx-sender))))
    (asserts! (is-eq tx-sender (get maintainer project)) ERR-NOT-AUTHORIZED)
    (asserts! (> contract-balance u0) ERR-INSUFFICIENT-FUNDS)
    (let ((royalty-amount (/ (* contract-balance (get royalty-percentage project)) u100))
          (platform-fee (/ contract-balance u20)))
      (try! (as-contract (stx-transfer? royalty-amount tx-sender (get maintainer project))))
      (var-set total-platform-fees (+ (var-get total-platform-fees) platform-fee))
      (map-set projects project-id
        (merge project { total-earned: (+ (get total-earned project) royalty-amount) })
      )
      (ok royalty-amount)
    )
  )
)

(define-public (update-project-status (project-id uint) (is-active bool))
  (let ((project (unwrap! (map-get? projects project-id) ERR-PROJECT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get maintainer project)) ERR-NOT-AUTHORIZED)
    (map-set projects project-id (merge project { is-active: is-active }))
    (ok true)
  )
)

(define-public (assign-bounty (bounty-id uint) (contributor principal))
  (let ((bounty (unwrap! (map-get? bounties bounty-id) ERR-BOUNTY-NOT-FOUND))
        (project (unwrap! (map-get? projects (get project-id bounty)) ERR-PROJECT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get maintainer project)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status bounty) "open") ERR-INVALID-STATUS)
    (asserts! (is-some (map-get? contributors contributor)) ERR-CONTRIBUTOR-NOT-FOUND)
    (map-set bounties bounty-id (merge bounty { assignee: (some contributor) }))
    (map-set bounty-assignments { bounty-id: bounty-id, contributor: contributor }
      { assigned-at: stacks-block-height }
    )
    (ok true)
  )
)

(define-public (withdraw-stake (project-id uint))
  (let ((stake-info (unwrap! (map-get? stakes { project-id: project-id, staker: tx-sender }) ERR-BOUNTY-NOT-FOUND))
        (stake-amount (get amount stake-info)))
    (asserts! (get is-active stake-info) ERR-INVALID-STATUS)
    (map-set stakes { project-id: project-id, staker: tx-sender }
      (merge stake-info { is-active: false })
    )
    (let ((current-total (get total-staked (get-project-total-stake project-id))))
      (map-set project-stakes project-id { total-staked: (- current-total stake-amount) })
    )
    (try! (as-contract (stx-transfer? stake-amount tx-sender tx-sender)))
    (ok stake-amount)
  )
)

(define-public (update-contributor-verification (contributor principal) (verified bool))
  (let ((contributor-data (unwrap! (map-get? contributors contributor) ERR-CONTRIBUTOR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set contributors contributor (merge contributor-data { is-verified: verified }))
    (ok true)
  )
)

(define-public (emergency-pause-project (project-id uint))
  (let ((project (unwrap! (map-get? projects project-id) ERR-PROJECT-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set projects project-id (merge project { is-active: false }))
    (ok true)
  )
)

(define-read-only (get-bounties-by-project (project-id uint))
  (ok project-id)
)

(define-read-only (get-contributor-reputation (contributor principal))
  (default-to u0 (get reputation-score (map-get? contributors contributor)))
)

(define-read-only (get-project-priority-score (project-id uint))
  (let ((total-stake (get total-staked (get-project-total-stake project-id)))
        (project-data (map-get? projects project-id)))
    (match project-data
      project (if (get is-active project) total-stake u0)
      u0
    )
  )
)

(define-read-only (calculate-contributor-share (contributor principal) (project-id uint))
  (let ((contributor-data (map-get? contributors contributor))
        (project-data (map-get? projects project-id)))
    (match contributor-data
      contrib-info (match project-data
        proj-info (let ((contrib-count (get contributions-count contrib-info)))
                    (if (> contrib-count u0)
                        (/ (* contrib-count u100) contrib-count)
                        u0))
        u0
      )
      u0
    )
  )
)

(define-read-only (get-bounty-status-summary (project-id uint))
  {
    project-id: project-id,
    total-stake: (get total-staked (get-project-total-stake project-id)),
    is-active: (default-to false (get is-active (map-get? projects project-id)))
  }
)
