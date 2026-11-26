extends RefCounted


const ACTIVE := {
	"name": "Ambition to Surpass the Sakura",
	"condition": "orders_done",
	"threshold": 10,
	"script": "res://scripts/skills/effects/level_reset.gd",
	"repeat": true,
	"uses": 9999,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Cute puppy ────────────────────────────────────────────────────
	"all_price_factor": 1.5,

	# ── Made in haven ─────────────────────────────────────────────────
	"time_scale": 1.25,
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
const ASIAN := {
	"active": {"threshold": 15, "repeat": false, "uses": 1},
	"passive": {"all_price_factor": 1.25},
}
