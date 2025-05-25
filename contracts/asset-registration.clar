;; Asset Registration Contract
;; Manages registration and details of public infrastructure assets

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ASSET_EXISTS (err u101))
(define-constant ERR_ASSET_NOT_FOUND (err u102))

;; Asset data structure
(define-map assets
  { asset-id: uint }
  {
    name: (string-ascii 100),
    asset-type: (string-ascii 50),
    location: (string-ascii 200),
    installation-date: uint,
    estimated-lifespan: uint,
    owner: principal,
    status: (string-ascii 20)
  }
)

;; Asset counter
(define-data-var asset-counter uint u0)

;; Register a new asset
(define-public (register-asset
  (name (string-ascii 100))
  (asset-type (string-ascii 50))
  (location (string-ascii 200))
  (installation-date uint)
  (estimated-lifespan uint))
  (let ((asset-id (+ (var-get asset-counter) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set assets
      { asset-id: asset-id }
      {
        name: name,
        asset-type: asset-type,
        location: location,
        installation-date: installation-date,
        estimated-lifespan: estimated-lifespan,
        owner: tx-sender,
        status: "active"
      }
    )
    (var-set asset-counter asset-id)
    (ok asset-id)
  )
)

;; Get asset details
(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

;; Update asset status
(define-public (update-asset-status (asset-id uint) (new-status (string-ascii 20)))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR_ASSET_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set assets
      { asset-id: asset-id }
      (merge asset { status: new-status })
    )
    (ok true)
  )
)

;; Get total asset count
(define-read-only (get-asset-count)
  (var-get asset-counter)
)
