;; Auction House - NFT/Asset Auction System
;; Create auctions with bidding and automatic settlement

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-auction-ended (err u104))
(define-constant err-auction-active (err u105))
(define-constant err-bid-too-low (err u106))
(define-constant err-not-ended (err u107))

;; Data Variables
(define-data-var auction-nonce uint u0)
(define-data-var platform-fee-percent uint u250) ;; 2.5%

;; Auction Types
(define-constant auction-type-english u1) ;; highest bid wins
(define-constant auction-type-dutch u2) ;; price decreases over time

;; Data Maps
(define-map auctions
  { auction-id: uint }
  {
    seller: principal,
    asset-contract: principal,
    asset-id: uint,
    auction-type: uint,
    starting-price: uint,
    reserve-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    start-height: uint,
    end-height: uint,
    settled: bool
  }
)

(define-map bids
  { auction-id: uint, bidder: principal }
  {
    amount: uint,
    bid-time: uint,
    outbid: bool
  }
)

(define-map user-bid-count
  { auction-id: uint }
  { count: uint }
)

(define-map seller-stats
  { seller: principal }
  {
    auctions-created: uint,
    auctions-settled: uint,
    total-sold: uint
  }
)

(define-map bidder-stats
  { bidder: principal }
  {
    bids-placed: uint,
    auctions-won: uint,
    total-spent: uint
  }
)

;; Read-Only Functions
(define-read-only (get-auction (auction-id uint))
  (map-get? auctions { auction-id: auction-id })
)

(define-read-only (get-bid (auction-id uint) (bidder principal))
  (map-get? bids { auction-id: auction-id, bidder: bidder })
)

(define-read-only (is-auction-active (auction-id uint))
  (match (get-auction auction-id)
    auction
      (and
        (>= block-height (get start-height auction))
        (< block-height (get end-height auction))
        (not (get settled auction))
      )
    false
  )
)

(define-read-only (get-seller-stats (seller principal))
  (default-to
    { auctions-created: u0, auctions-settled: u0, total-sold: u0 }
    (map-get? seller-stats { seller: seller })
  )
)

(define-read-only (get-bidder-stats (bidder principal))
  (default-to
    { bids-placed: u0, auctions-won: u0, total-spent: u0 }
    (map-get? bidder-stats { bidder: bidder })
  )
)

(define-read-only (calculate-dutch-price (auction-id uint))
  (match (get-auction auction-id)
    auction
      (let (
        (elapsed (- block-height (get start-height auction)))
        (duration (- (get end-height auction) (get start-height auction)))
        (price-drop (- (get starting-price auction) (get reserve-price auction)))
        (current-drop (/ (* price-drop elapsed) duration))
      )
        (ok (- (get starting-price auction) current-drop))
      )
    err-not-found
  )
)

;; Public Functions
(define-public (create-auction 
    (asset-contract principal)
    (asset-id uint)
    (auction-type uint)
    (starting-price uint)
    (reserve-price uint)
    (duration uint)
  )
  (let (
    (auction-id (+ (var-get auction-nonce) u1))
    (seller-info (get-seller-stats tx-sender))
  )
    (asserts! (> starting-price u0) err-invalid-amount)
    (asserts! (> duration u0) err-invalid-amount)
    
    (map-set auctions
      { auction-id: auction-id }
      {
        seller: tx-sender,
        asset-contract: asset-contract,
        asset-id: asset-id,
        auction-type: auction-type,
        starting-price: starting-price,
        reserve-price: reserve-price,
        current-bid: u0,
        highest-bidder: none,
        start-height: block-height,
        end-height: (+ block-height duration),
        settled: false
      }
    )
    
    (map-set seller-stats
      { seller: tx-sender }
      (merge seller-info {
        auctions-created: (+ (get auctions-created seller-info) u1)
      })
    )
    
    (var-set auction-nonce auction-id)
    (ok auction-id)
  )
)

(define-public (place-bid (auction-id uint) (amount uint))
  (let (
    (auction (unwrap! (get-auction auction-id) err-not-found))
    (bidder-info (get-bidder-stats tx-sender))
    (previous-bidder (get highest-bidder auction))
  )
    (asserts! (is-auction-active auction-id) err-auction-ended)
    (asserts! (> amount (get current-bid auction)) err-bid-too-low)
    (asserts! (>= amount (get starting-price auction)) err-bid-too-low)
    (asserts! (not (is-eq tx-sender (get seller auction))) err-unauthorized)
    
    ;; Mark previous bid as outbid
    (match previous-bidder
      prev-bidder
        (match (get-bid auction-id prev-bidder)
          prev-bid
            (map-set bids
              { auction-id: auction-id, bidder: prev-bidder }
              (merge prev-bid { outbid: true })
            )
          true
        )
      true
    )
    
    ;; Record new bid
    (map-set bids
      { auction-id: auction-id, bidder: tx-sender }
      {
        amount: amount,
        bid-time: block-height,
        outbid: false
      }
    )
    
    ;; Update auction
    (map-set auctions
      { auction-id: auction-id }
      (merge auction {
        current-bid: amount,
        highest-bidder: (some tx-sender)
      })
    )
    
    ;; Update bidder stats
    (map-set bidder-stats
      { bidder: tx-sender }
      (merge bidder-info {
        bids-placed: (+ (get bids-placed bidder-info) u1)
      })
    )
    
    (ok true)
  )
)

(define-public (settle-auction (auction-id uint))
  (let (
    (auction (unwrap! (get-auction auction-id) err-not-found))
    (winner (unwrap! (get highest-bidder auction) err-not-found))
    (final-price (get current-bid auction))
    (platform-fee (/ (* final-price (var-get platform-fee-percent)) u10000))
    (seller-amount (- final-price platform-fee))
    (seller-info (get-seller-stats (get seller auction)))
    (winner-info (get-bidder-stats winner))
  )
    (asserts! (>= block-height (get end-height auction)) err-not-ended)
    (asserts! (not (get settled auction)) err-auction-ended)
    (asserts! (>= final-price (get reserve-price auction)) err-bid-too-low)
    
    (map-set auctions
      { auction-id: auction-id }
      (merge auction { settled: true })
    )
    
    (map-set seller-stats
      { seller: (get seller auction) }
      (merge seller-info {
        auctions-settled: (+ (get auctions-settled seller-info) u1),
        total-sold: (+ (get total-sold seller-info) seller-amount)
      })
    )
    
    (map-set bidder-stats
      { bidder: winner }
      (merge winner-info {
        auctions-won: (+ (get auctions-won winner-info) u1),
        total-spent: (+ (get total-spent winner-info) final-price)
      })
    )
    
    (ok seller-amount)
  )
)

(define-public (cancel-auction (auction-id uint))
  (let (
    (auction (unwrap! (get-auction auction-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get seller auction)) err-unauthorized)
    (asserts! (is-eq (get current-bid auction) u0) err-auction-active)
    (asserts! (not (get settled auction)) err-auction-ended)
    
    (map-set auctions
      { auction-id: auction-id }
      (merge auction { settled: true })
    )
    
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set platform-fee-percent new-fee)
    (ok true)
  )
)
