;; Contractor Verification Contract
;; Validates and manages service providers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_CONTRACTOR_EXISTS (err u401))
(define-constant ERR_CONTRACTOR_NOT_FOUND (err u402))

;; Contractor profiles
(define-map contractors
  { contractor: principal }
  {
    name: (string-ascii 100),
    specialties: (list 5 (string-ascii 50)),
    certification-level: uint,
    registration-date: uint,
    status: (string-ascii 20),
    completed-jobs: uint,
    average-rating: uint
  }
)

;; Contractor certifications
(define-map certifications
  { contractor: principal, cert-type: (string-ascii 50) }
  {
    issued-date: uint,
    expiry-date: uint,
    issuing-authority: (string-ascii 100),
    valid: bool
  }
)

;; Register contractor
(define-public (register-contractor
  (contractor principal)
  (name (string-ascii 100))
  (specialties (list 5 (string-ascii 50)))
  (certification-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? contractors { contractor: contractor })) ERR_CONTRACTOR_EXISTS)

    (map-set contractors
      { contractor: contractor }
      {
        name: name,
        specialties: specialties,
        certification-level: certification-level,
        registration-date: block-height,
        status: "active",
        completed-jobs: u0,
        average-rating: u0
      }
    )

    (ok true)
  )
)

;; Add certification
(define-public (add-certification
  (contractor principal)
  (cert-type (string-ascii 50))
  (expiry-date uint)
  (issuing-authority (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? contractors { contractor: contractor })) ERR_CONTRACTOR_NOT_FOUND)

    (map-set certifications
      { contractor: contractor, cert-type: cert-type }
      {
        issued-date: block-height,
        expiry-date: expiry-date,
        issuing-authority: issuing-authority,
        valid: true
      }
    )

    (ok true)
  )
)

;; Update contractor rating
(define-public (update-contractor-rating (contractor principal) (new-rating uint))
  (let ((contractor-data (unwrap! (map-get? contractors { contractor: contractor }) ERR_CONTRACTOR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-rating u100) ERR_UNAUTHORIZED)

    (map-set contractors
      { contractor: contractor }
      (merge contractor-data { average-rating: new-rating })
    )

    (ok true)
  )
)

;; Get contractor details
(define-read-only (get-contractor (contractor principal))
  (map-get? contractors { contractor: contractor })
)

;; Check contractor certification
(define-read-only (get-certification (contractor principal) (cert-type (string-ascii 50)))
  (map-get? certifications { contractor: contractor, cert-type: cert-type })
)

;; Verify contractor is active and certified
(define-read-only (is-contractor-verified (contractor principal))
  (match (map-get? contractors { contractor: contractor })
    contractor-data
      (and
        (is-eq (get status contractor-data) "active")
        (>= (get certification-level contractor-data) u1)
      )
    false
  )
)
