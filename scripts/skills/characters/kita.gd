extends RefCounted
## ─────────────────────────────────────────────────── CÁCH CHỈNH
## ─────────────────────────────────────── KĨ NĂNG CHỈ ĂN VỚI ĐÚNG CHỦ


const ACTIVE := {
	"name": "Victory Cheer!",

	"condition": "perfect_orders",
	"threshold": 5,

	"effect": "force_perfect",

	"perfect_payout_multiplier": 2.0,

	"uses": 1,
}


const PASSIVE := {

	"patience_factor": 1.30,

	"perfect_bonus_add": 0.20,

	"burn_time_cut": 2.0,
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
const ASIAN := {
	"active": {"threshold": 8},
	"passive": {"patience_factor": 1.15, "perfect_bonus_add": 0.10},
}
